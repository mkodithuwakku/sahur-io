extends "res://tests/support/test_suite.gd"

const ConfigStore = preload("res://scripts/core/config.gd")
const PlayerStatsScript = preload("res://scripts/player/player_stats.gd")

func test_apply_growth_increases_max_health_and_clamps_level() -> void:
	var stats = PlayerStatsScript.new(10, "Grower")
	stats.current_health = 52.0
	for _i in range(ConfigStore.player_tuning.max_growth_level + 3):
		stats.apply_growth(ConfigStore.player_tuning)
	assert_equal(ConfigStore.player_tuning.max_growth_level, stats.growth_level)
	assert_near(ConfigStore.player_tuning.get_max_health(stats.growth_level), stats.max_health)
	assert_true(stats.current_health <= stats.max_health, "Current health should never exceed max health")

func test_begin_respawn_and_tick_to_completion() -> void:
	var stats = PlayerStatsScript.new(3, "Respawn")
	stats.begin_respawn(1.5)
	assert_false(stats.alive, "Respawning player should be marked dead")
	assert_equal(1, stats.deaths)
	assert_false(stats.tick_respawn(0.5), "Respawn should not complete early")
	assert_true(stats.tick_respawn(1.0), "Respawn should complete when the timer reaches zero")

func test_init_uses_base_health() -> void:
	var stats = PlayerStatsScript.new(1, "Guest")
	assert_near(ConfigStore.player_tuning.base_health, stats.current_health)
	assert_near(ConfigStore.player_tuning.base_health, stats.max_health)

func test_reset_for_respawn_restores_base_state() -> void:
	var stats = PlayerStatsScript.new(5, "Reset")
	stats.growth_level = 4
	stats.current_health = 10.0
	stats.max_health = 200.0
	stats.last_attacker_id = 42
	stats.reset_for_respawn(ConfigStore.player_tuning)
	assert_equal(1, stats.growth_level)
	assert_true(stats.alive, "Reset player should be alive")
	assert_near(ConfigStore.player_tuning.base_health, stats.current_health)
	assert_equal(0, stats.last_attacker_id)

func test_take_damage_tracks_attacker_and_defeat() -> void:
	var stats = PlayerStatsScript.new(2, "Target")
	var defeated := stats.take_damage(25.0, 99)
	assert_false(defeated, "Initial damage should not defeat the player")
	assert_equal(99, stats.last_attacker_id)
	defeated = stats.take_damage(1000.0, 99)
	assert_true(defeated, "Lethal damage should report defeat")
	assert_near(0.0, stats.current_health)
