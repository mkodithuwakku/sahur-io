extends "res://tests/support/test_suite.gd"

const ArenaManagerScript = preload("res://scripts/arena/arena_manager.gd")
const SpawnManagerScript = preload("res://scripts/arena/spawn_manager.gd")

func test_choose_spawn_prefers_safest_candidate() -> void:
	var arena = _build_arena([
		Vector3(-12.0, 0.0, 0.0),
		Vector3(2.0, 0.0, 0.0),
		Vector3(9.0, 0.0, 0.0)
	])
	var spawn_manager = SpawnManagerScript.new(arena)
	var spawn: Vector3 = spawn_manager.choose_spawn([Vector3.ZERO], 8.0)
	assert_equal(Vector3(-12.0, 0.0, 0.0), spawn)

func test_choose_spawn_returns_best_available_when_no_candidate_meets_preferred_distance() -> void:
	var arena = _build_arena([
		Vector3(1.0, 0.0, 0.0),
		Vector3(3.0, 0.0, 0.0),
		Vector3(5.0, 0.0, 0.0)
	])
	var spawn_manager = SpawnManagerScript.new(arena)
	var spawn: Vector3 = spawn_manager.choose_spawn([Vector3.ZERO], 10.0)
	assert_equal(Vector3(5.0, 0.0, 0.0), spawn)

func _build_arena(spawn_positions: Array[Vector3]) -> ArenaManager:
	var arena = ArenaManagerScript.new() as ArenaManager
	var spawn_root := Node3D.new()
	spawn_root.name = "SpawnPoints"
	arena.add_child(spawn_root)
	arena.spawn_points_root = spawn_root
	for position in spawn_positions:
		var marker := Marker3D.new()
		marker.position = position
		spawn_root.add_child(marker)
	track_temp_node(arena, true)
	return arena
