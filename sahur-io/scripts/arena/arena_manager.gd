extends Node3D
class_name ArenaManager

@export var bounds_extents: Vector2 = Vector2(20.0, 20.0)

@onready var spawn_points_root: Node = $SpawnPoints

func get_spawn_points() -> Array:
	var points: Array = []
	for child in spawn_points_root.get_children():
		if child is Marker3D:
			points.append(child)
	return points

func clamp_position(world_position: Vector3) -> Vector3:
	return Vector3(
		clamp(world_position.x, -bounds_extents.x, bounds_extents.x),
		world_position.y,
		clamp(world_position.z, -bounds_extents.y, bounds_extents.y)
	)
