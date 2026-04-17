extends "res://tests/support/test_suite.gd"

const ConfigStore = preload("res://scripts/core/config.gd")
const PlayerScene = preload("res://scenes/player/Player.tscn")

func test_server_process_attack_hits_target_in_front_arc() -> void:
	var attacker := _create_player(1, "Alpha", Vector3.ZERO)
	var target := _create_player(2, "Bravo", Vector3(0.0, 0.0, -2.0))
	attacker.set_attack_facing(Vector3.FORWARD)
	var hits: Array = attacker.server_process_attack([attacker, target])
	assert_equal(1, hits.size())
	assert_equal(2, hits[0]["target_peer_id"])
	assert_near(
		ConfigStore.player_tuning.base_health - ConfigStore.combat_tuning.damage,
		target.stats.current_health
	)

func test_server_process_attack_ignores_target_behind_attacker() -> void:
	var attacker := _create_player(1, "Alpha", Vector3.ZERO)
	var target := _create_player(2, "Bravo", Vector3(0.0, 0.0, 2.0))
	attacker.set_attack_facing(Vector3.FORWARD)
	var hits: Array = attacker.server_process_attack([attacker, target])
	assert_equal(0, hits.size())
	assert_near(ConfigStore.player_tuning.base_health, target.stats.current_health)

func test_server_register_kill_applies_growth_after_defeat() -> void:
	var attacker := _create_player(1, "Alpha", Vector3.ZERO)
	var target := _create_player(2, "Bravo", Vector3(0.0, 0.0, -2.0))
	target.stats.current_health = ConfigStore.combat_tuning.damage
	attacker.set_attack_facing(Vector3.FORWARD)
	var hits: Array = attacker.server_process_attack([attacker, target])
	assert_true(hits[0]["defeated"], "Low-health target should be defeated by the attack")
	assert_false(target.stats.alive, "Defeated target should enter the respawn state")
	assert_equal(1, target.stats.deaths)
	attacker.server_register_kill()
	assert_equal(1, attacker.stats.kills)
	assert_equal(2, attacker.stats.growth_level)

func test_server_respawn_restores_base_state() -> void:
	var player := _create_player(7, "Respawn", Vector3(4.0, 0.0, 4.0))
	player.stats.current_health = 0.0
	player.stats.begin_respawn(ConfigStore.match_tuning.respawn_delay)
	player.server_respawn(Vector3(-3.0, 0.0, 2.0))
	assert_true(player.stats.alive, "Respawn should mark the player alive")
	assert_vector3_near(Vector3(-3.0, 0.0, 2.0), player.global_position, 0.0001)
	assert_near(ConfigStore.player_tuning.base_health, player.stats.current_health)
	assert_equal(1, player.stats.growth_level)

func _create_player(peer_id: int, display_name: String, world_position: Vector3) -> PlayerController:
	var player := PlayerScene.instantiate() as PlayerController
	player.setup(peer_id, display_name, peer_id, true, Vector2(20.0, 20.0))
	track_temp_node(player, true)
	player.global_position = world_position
	return player
