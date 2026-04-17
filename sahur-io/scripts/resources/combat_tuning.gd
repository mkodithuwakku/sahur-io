extends Resource
class_name CombatTuning

@export var damage: float = 34.0
@export var cooldown: float = 0.72
@export var startup: float = 0.08
@export var active_window: float = 0.12
@export var attack_range: float = 2.8
@export var attack_arc_degrees: float = 85.0
@export var range_growth_bonus: float = 0.18
@export var knockback_force: float = 9.5
@export var knockback_growth_bonus: float = 0.75
@export var local_reconcile_distance: float = 2.2

func get_attack_range(growth_level: int) -> float:
	var level_offset: int = maxi(growth_level - 1, 0)
	return attack_range + range_growth_bonus * level_offset

func get_knockback(growth_level: int) -> float:
	var level_offset: int = maxi(growth_level - 1, 0)
	return knockback_force + knockback_growth_bonus * level_offset
