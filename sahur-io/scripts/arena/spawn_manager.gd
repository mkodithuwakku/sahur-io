extends RefCounted
class_name SpawnManager

var arena: ArenaManager

func _init(target_arena: ArenaManager) -> void:
	arena = target_arena

func choose_spawn(occupied_positions: Array[Vector3], preferred_distance: float) -> Vector3:
	var candidates := arena.get_spawn_points()
	if candidates.is_empty():
		return Vector3.ZERO
	var ranked: Array = []
	for candidate in candidates:
		var score := 0.0
		for occupied in occupied_positions:
			score += candidate.global_position.distance_to(occupied)
		ranked.append({
			"position": candidate.global_position,
			"score": score
		})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["score"] > b["score"]
	)
	for entry in ranked:
		if entry["score"] >= preferred_distance:
			return entry["position"]
	return ranked.front()["position"]
