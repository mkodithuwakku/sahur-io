extends "res://tests/support/test_suite.gd"

const PlayerNetworkScript = preload("res://scripts/player/player_network.gd")
const ReplicationManagerScript = preload("res://scripts/network/replication_manager.gd")

func test_local_server_state_lerps_when_error_is_small() -> void:
	var player := track_temp_node(CharacterBody3D.new(), true) as CharacterBody3D
	var network = PlayerNetworkScript.new()
	player.global_position = Vector3.ZERO
	player.rotation.y = 0.0
	network.apply_server_state(player, Vector3(1.0, 0.0, 0.0), 0.5, Vector3(2.0, 0.0, 0.0), true, 2.0)
	assert_vector3_near(Vector3(0.18, 0.0, 0.0), player.global_position, 0.0001)
	assert_near(0.15, player.rotation.y, 0.0001)
	assert_vector3_near(Vector3(2.0, 0.0, 0.0), player.velocity, 0.0001)

func test_local_server_state_snaps_when_error_is_large() -> void:
	var player := track_temp_node(CharacterBody3D.new(), true) as CharacterBody3D
	var network = PlayerNetworkScript.new()
	network.apply_server_state(player, Vector3(6.0, 0.0, 0.0), 0.0, Vector3.ZERO, true, 2.0)
	assert_vector3_near(Vector3(6.0, 0.0, 0.0), player.global_position, 0.0001)

func test_remote_interpolation_moves_toward_target() -> void:
	var player := track_temp_node(CharacterBody3D.new(), true) as CharacterBody3D
	var network = PlayerNetworkScript.new()
	network.target_position = Vector3(10.0, 0.0, 0.0)
	network.target_velocity = Vector3(5.0, 0.0, 0.0)
	network.target_yaw = 1.0
	network.interpolate(player, 0.1)
	assert_true(player.global_position.x > 0.0, "Remote interpolation should move toward the target position")
	assert_true(player.velocity.x > 0.0, "Remote interpolation should move velocity toward the replicated velocity")
	assert_true(player.rotation.y > 0.0, "Remote interpolation should rotate toward the target yaw")

func test_replication_manager_ticks_at_interval() -> void:
	var replication = ReplicationManagerScript.new()
	assert_false(replication.tick(0.01, 10.0), "Replication should not tick before the interval is reached")
	assert_true(replication.tick(0.1, 10.0), "Replication should tick once the interval threshold is reached")
