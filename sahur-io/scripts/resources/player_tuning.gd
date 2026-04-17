extends Resource
class_name PlayerTuning

@export var base_move_speed: float = 8.5
@export var acceleration: float = 24.0
@export var base_health: float = 100.0
@export var health_per_growth: float = 18.0
@export var scale_per_growth: float = 0.12
@export var speed_penalty_per_growth: float = 0.08
@export var max_growth_level: int = 8
@export var base_scale: float = 1.0
@export var camera_height: float = 18.0
@export var camera_distance: float = 15.0
@export var camera_step_per_growth: float = 1.0
@export var knockback_resistance_per_growth: float = 0.06

func get_move_speed(growth_level: int) -> float:
	var level_offset: int = maxi(growth_level - 1, 0)
	return base_move_speed / (1.0 + speed_penalty_per_growth * level_offset)

func get_scale(growth_level: int) -> float:
	var level_offset: int = maxi(growth_level - 1, 0)
	return base_scale + scale_per_growth * level_offset

func get_max_health(growth_level: int) -> float:
	var level_offset: int = maxi(growth_level - 1, 0)
	return base_health + health_per_growth * level_offset

func get_camera_offset(growth_level: int) -> Vector3:
	var level_offset: float = float(maxi(growth_level - 1, 0))
	return Vector3(0.0, camera_height + camera_step_per_growth * level_offset, camera_distance + camera_step_per_growth * level_offset)
