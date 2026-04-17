extends RefCounted
class_name PlayerCombat

const ConfigStore = preload("res://scripts/core/config.gd")

var cooldown_remaining: float = 0.0
var swing_elapsed: float = 0.0
var swinging: bool = false
var hit_targets: Dictionary = {}

func tick(delta: float) -> void:
	cooldown_remaining = max(cooldown_remaining - delta, 0.0)
	if swinging:
		swing_elapsed += delta
		var total_duration: float = ConfigStore.combat_tuning.startup + ConfigStore.combat_tuning.active_window + 0.18
		if swing_elapsed >= total_duration:
			swinging = false
			swing_elapsed = total_duration

func can_attack() -> bool:
	return cooldown_remaining <= 0.0

func begin_attack() -> void:
	cooldown_remaining = ConfigStore.combat_tuning.cooldown
	swing_elapsed = 0.0
	swinging = true
	hit_targets.clear()

func is_active_window() -> bool:
	return swinging and swing_elapsed >= ConfigStore.combat_tuning.startup and swing_elapsed <= ConfigStore.combat_tuning.startup + ConfigStore.combat_tuning.active_window

func mark_target_hit(target_peer_id: int) -> void:
	hit_targets[target_peer_id] = true

func has_hit_target(target_peer_id: int) -> bool:
	return hit_targets.has(target_peer_id)

func get_animation_weight() -> float:
	var total_duration: float = ConfigStore.combat_tuning.startup + ConfigStore.combat_tuning.active_window + 0.18
	if total_duration <= 0.0:
		return 0.0
	return clamp(swing_elapsed / total_duration, 0.0, 1.0)
