extends Resource
class_name CombatTuning

@export var damage: float = 34.0
@export var cooldown: float = 0.3
@export var startup: float = 0.035
@export var active_window: float = 0.09
@export var attack_range: float = 2.8
@export var attack_arc_degrees: float = 85.0
@export var range_growth_bonus: float = 0.18
@export var lunge_speed: float = 3.6
@export var lunge_growth_bonus: float = 0.2
@export var hit_react_duration: float = 0.18
@export var defeat_delay: float = 0.24
@export var knockback_force: float = 5.4
@export var knockback_growth_bonus: float = 0.45
@export var knockback_decay: float = 24.0
@export var max_received_knockback_speed: float = 6.2
@export var local_reconcile_distance: float = 2.2

func get_attack_range(growth_level: int) -> float:
	var level_offset: int = maxi(growth_level - 1, 0)
	return attack_range + range_growth_bonus * level_offset

func get_knockback(growth_level: int) -> float:
	var level_offset: int = maxi(growth_level - 1, 0)
	return knockback_force + knockback_growth_bonus * level_offset

func get_lunge(growth_level: int) -> float:
	var level_offset: int = maxi(growth_level - 1, 0)
	return lunge_speed + lunge_growth_bonus * level_offset
