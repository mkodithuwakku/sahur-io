extends RefCounted
class_name MathUtils

static func planar_direction(from: Vector3, to: Vector3) -> Vector3:
	var direction := Vector3(to.x - from.x, 0.0, to.z - from.z)
	if direction.length_squared() <= 0.0001:
		return Vector3.FORWARD
	return direction.normalized()

static func yaw_from_direction(direction: Vector3) -> float:
	var planar := Vector3(direction.x, 0.0, direction.z)
	if planar.length_squared() <= 0.0001:
		return 0.0
	return atan2(planar.x, planar.z)

static func is_in_attack_arc(origin: Vector3, forward: Vector3, target: Vector3, max_distance: float, half_arc_degrees: float) -> bool:
	var delta := Vector3(target.x - origin.x, 0.0, target.z - origin.z)
	if delta.length() > max_distance:
		return false
	if delta.length_squared() <= 0.0001:
		return true
	var forward_flat := Vector3(forward.x, 0.0, forward.z).normalized()
	if forward_flat.length_squared() <= 0.0001:
		forward_flat = Vector3.FORWARD
	var angle := rad_to_deg(forward_flat.angle_to(delta.normalized()))
	return angle <= half_arc_degrees

static func planar_velocity_from_input(input_vector: Vector2, speed: float) -> Vector3:
	return Vector3(input_vector.x, 0.0, input_vector.y) * speed
