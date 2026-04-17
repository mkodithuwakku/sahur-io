extends "res://tests/support/test_suite.gd"

const ConfigStore = preload("res://scripts/core/config.gd")
const PlayerCombatScript = preload("res://scripts/player/player_combat.gd")

func test_active_window_opens_and_closes_over_time() -> void:
	var combat = PlayerCombatScript.new()
	combat.begin_attack()
	assert_false(combat.is_active_window(), "Attack should not be active before startup finishes")
	combat.tick(ConfigStore.combat_tuning.startup + 0.001)
	assert_true(combat.is_active_window(), "Attack should become active after startup")
	combat.tick(ConfigStore.combat_tuning.active_window + 0.25)
	assert_false(combat.is_active_window(), "Attack should stop being active after the swing ends")
	assert_false(combat.swinging, "Attack should finish once the total duration has elapsed")

func test_begin_attack_starts_cooldown_and_swing() -> void:
	var combat = PlayerCombatScript.new()
	assert_true(combat.can_attack(), "Fresh combat state should be ready to attack")
	combat.begin_attack()
	assert_false(combat.can_attack(), "Combat should be on cooldown immediately after starting an attack")
	assert_true(combat.swinging, "Attack should enter the swinging state")
	assert_near(ConfigStore.combat_tuning.cooldown, combat.cooldown_remaining)

func test_hit_targets_reset_per_swing() -> void:
	var combat = PlayerCombatScript.new()
	combat.begin_attack()
	combat.mark_target_hit(7)
	assert_true(combat.has_hit_target(7), "Hit targets should be tracked during a swing")
	combat.begin_attack()
	assert_false(combat.has_hit_target(7), "Starting a new swing should clear the prior hit target registry")
