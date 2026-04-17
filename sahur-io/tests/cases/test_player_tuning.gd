extends "res://tests/support/test_suite.gd"

const ConfigStore = preload("res://scripts/core/config.gd")

func test_camera_offset_expands_with_growth() -> void:
	var tuning := ConfigStore.player_tuning
	var base_offset: Vector3 = tuning.get_camera_offset(1)
	var grown_offset: Vector3 = tuning.get_camera_offset(4)
	assert_true(grown_offset.y > base_offset.y, "Camera height should increase with growth")
	assert_true(grown_offset.z > base_offset.z, "Camera distance should increase with growth")

func test_health_and_scale_increase_with_growth() -> void:
	var tuning := ConfigStore.player_tuning
	assert_true(tuning.get_max_health(3) > tuning.get_max_health(1), "Max health should increase with growth")
	assert_true(tuning.get_scale(3) > tuning.get_scale(1), "Scale should increase with growth")

func test_move_speed_decreases_with_growth() -> void:
	var tuning := ConfigStore.player_tuning
	assert_near(tuning.base_move_speed, tuning.get_move_speed(1))
	assert_true(tuning.get_move_speed(4) < tuning.get_move_speed(1), "Move speed should decrease at higher growth levels")
