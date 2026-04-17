extends RefCounted
class_name PlayerNetwork

var target_position: Vector3 = Vector3.ZERO
var target_velocity: Vector3 = Vector3.ZERO
var target_yaw: float = 0.0

func apply_server_state(player: CharacterBody3D, position: Vector3, yaw: float, new_velocity: Vector3, is_local_player: bool, snap_distance: float) -> void:
	target_position = position
	target_velocity = new_velocity
	target_yaw = yaw
	if is_local_player:
		if player.global_position.distance_to(position) > snap_distance:
			player.global_position = position
		else:
			player.global_position = player.global_position.lerp(position, 0.18)
		player.rotation.y = lerp_angle(player.rotation.y, yaw, 0.3)
		player.velocity = new_velocity

func interpolate(player: CharacterBody3D, delta: float) -> void:
	player.global_position = player.global_position.lerp(target_position, clamp(delta * 10.0, 0.0, 1.0))
	player.rotation.y = lerp_angle(player.rotation.y, target_yaw, clamp(delta * 12.0, 0.0, 1.0))
	player.velocity = player.velocity.lerp(target_velocity, clamp(delta * 8.0, 0.0, 1.0))
