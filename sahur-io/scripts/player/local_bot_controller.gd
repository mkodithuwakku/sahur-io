extends RefCounted
class_name LocalBotController

const ConfigStore = preload("res://scripts/core/config.gd")

var strafe_sign: float = 1.0

func _init(seed_id: int = 0) -> void:
	strafe_sign = 1.0 if seed_id % 2 == 0 else -1.0

func build_decision(self_peer_id: int, self_position: Vector3, current_facing: Vector3, growth_level: int, candidates: Array) -> Dictionary:
	var target: Dictionary = _choose_target(self_peer_id, self_position, candidates)
	if target.is_empty():
		return {
			"move_input": Vector2.ZERO,
			"facing": current_facing,
			"attack": false,
			"target_peer_id": 0
		}

	var to_target := Vector3(target["position"].x - self_position.x, 0.0, target["position"].z - self_position.z)
	var distance_to_target: float = to_target.length()
	var desired_facing := current_facing
	if to_target.length_squared() > 0.0001:
		desired_facing = to_target.normalized()

	var attack_range: float = ConfigStore.combat_tuning.get_attack_range(growth_level)
	var flank := Vector3(-desired_facing.z * strafe_sign, 0.0, desired_facing.x * strafe_sign)
	var move_planar := desired_facing
	if distance_to_target < attack_range * 0.55:
		move_planar = (desired_facing * -0.45 + flank * 0.85).normalized()
	elif distance_to_target < attack_range * 1.05:
		move_planar = (desired_facing * 0.25 + flank * 0.65).normalized()

	return {
		"move_input": Vector2(move_planar.x, move_planar.z).limit_length(1.0),
		"facing": desired_facing,
		"attack": distance_to_target <= attack_range * 0.95,
		"target_peer_id": target["peer_id"]
	}

func _choose_target(self_peer_id: int, self_position: Vector3, candidates: Array) -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance := INF
	for candidate in candidates:
		if candidate.get("peer_id", 0) == self_peer_id:
			continue
		if not candidate.get("alive", false):
			continue
		var position: Vector3 = candidate.get("position", Vector3.ZERO)
		var distance_to_candidate := Vector2(position.x - self_position.x, position.z - self_position.z).length_squared()
		if distance_to_candidate < closest_distance:
			closest_distance = distance_to_candidate
			closest = candidate
	return closest
