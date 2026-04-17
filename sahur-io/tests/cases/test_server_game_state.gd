extends "res://tests/support/test_suite.gd"

const ConfigStore = preload("res://scripts/core/config.gd")
const PlayerStatsScript = preload("res://scripts/player/player_stats.gd")
const ServerGameStateScript = preload("res://scripts/network/server_game_state.gd")

class MockPlayer extends Node3D:
	var peer_id: int = 0
	var display_name: String = "Guest"
	var stats

	func _init(initial_peer_id: int, initial_name: String, world_position: Vector3) -> void:
		peer_id = initial_peer_id
		display_name = initial_name
		position = world_position
		stats = PlayerStatsScript.new(peer_id, display_name)
		stats.reset_for_respawn(ConfigStore.player_tuning)

	func build_state_snapshot() -> Dictionary:
		return {
			"peer_id": peer_id,
			"name": display_name,
			"position": global_position,
			"health": stats.current_health,
			"growth": stats.growth_level,
			"kills": stats.kills,
			"deaths": stats.deaths
		}

func test_build_snapshot_includes_players_and_leaderboard() -> void:
	var state = ServerGameStateScript.new()
	var player_a := _create_player(1, "Alpha", Vector3(1.0, 0.0, 0.0))
	var player_b := _create_player(2, "Bravo", Vector3(2.0, 0.0, 0.0))
	player_a.stats.kills = 2
	state.register_player(1, "Alpha", player_a)
	state.register_player(2, "Bravo", player_b)
	var snapshot: Dictionary = state.build_snapshot()
	assert_equal(2, snapshot.get("players", []).size())
	assert_equal(2, snapshot.get("leaderboard", []).size())
	assert_true(snapshot.get("uptime", -1) >= 0, "Snapshot should include non-negative uptime")

func test_get_active_positions_excludes_dead_players_and_requested_peer() -> void:
	var state = ServerGameStateScript.new()
	var player_a := _create_player(1, "Alpha", Vector3(1.0, 0.0, 0.0))
	var player_b := _create_player(2, "Bravo", Vector3(5.0, 0.0, 0.0))
	player_b.stats.begin_respawn(3.0)
	state.register_player(1, "Alpha", player_a)
	state.register_player(2, "Bravo", player_b)
	var positions: Array[Vector3] = state.get_active_positions(1)
	assert_equal(0, positions.size())

func test_leaderboard_sorts_by_score_then_deaths() -> void:
	var state = ServerGameStateScript.new()
	var player_a := _create_player(1, "Alpha", Vector3.ZERO)
	var player_b := _create_player(2, "Bravo", Vector3.ONE)
	player_a.stats.kills = 1
	player_a.stats.growth_level = 2
	player_a.stats.deaths = 2
	player_b.stats.kills = 1
	player_b.stats.growth_level = 1
	player_b.stats.deaths = 0
	state.register_player(1, "Alpha", player_a)
	state.register_player(2, "Bravo", player_b)
	var leaderboard: Array = state.build_leaderboard(5)
	assert_equal(2, leaderboard.size())
	assert_equal(2, leaderboard[0]["peer_id"], "Lower deaths should win when scores tie")

func _create_player(peer_id: int, display_name: String, world_position: Vector3) -> MockPlayer:
	return track_temp_node(MockPlayer.new(peer_id, display_name, world_position), true) as MockPlayer
