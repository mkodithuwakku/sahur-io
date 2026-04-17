extends "res://tests/support/test_suite.gd"

const LocalBotControllerScript = preload("res://scripts/player/local_bot_controller.gd")

func test_bot_attacks_when_target_is_in_range() -> void:
	var controller = LocalBotControllerScript.new(2)
	var decision: Dictionary = controller.build_decision(
		1001,
		Vector3.ZERO,
		Vector3.FORWARD,
		1,
		[
			{"peer_id": 2, "position": Vector3(0.0, 0.0, -2.0), "alive": true}
		]
	)
	assert_true(decision["attack"], "Bot should attack once a target is inside melee range")
	assert_equal(2, decision["target_peer_id"])
	assert_true(decision["move_input"].length() > 0.0, "Bot should still keep moving while engaging a target")

func test_bot_ignores_self_and_dead_targets() -> void:
	var controller = LocalBotControllerScript.new(3)
	var decision: Dictionary = controller.build_decision(
		1002,
		Vector3.ZERO,
		Vector3.FORWARD,
		1,
		[
			{"peer_id": 1002, "position": Vector3(0.0, 0.0, -1.0), "alive": true},
			{"peer_id": 4, "position": Vector3(0.0, 0.0, -0.5), "alive": false},
			{"peer_id": 5, "position": Vector3(5.0, 0.0, 0.0), "alive": true}
		]
	)
	assert_equal(5, decision["target_peer_id"])
	assert_false(decision["attack"], "Bot should not attack distant targets")

func test_bot_returns_idle_decision_without_targets() -> void:
	var controller = LocalBotControllerScript.new(4)
	var decision: Dictionary = controller.build_decision(1003, Vector3.ZERO, Vector3.FORWARD, 1, [])
	assert_equal(0, decision["target_peer_id"])
	assert_equal(Vector2.ZERO, decision["move_input"])
	assert_false(decision["attack"], "Bot should idle when no living targets exist")
