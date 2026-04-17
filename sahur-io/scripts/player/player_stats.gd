extends RefCounted
class_name PlayerStats

const ConfigStore = preload("res://scripts/core/config.gd")

var peer_id: int = 0
var display_name: String = "Guest"
var growth_level: int = 1
var kills: int = 0
var deaths: int = 0
var current_health: float = 0.0
var max_health: float = 0.0
var alive: bool = true
var respawn_remaining: float = 0.0
var last_attacker_id: int = 0

func _init(initial_peer_id: int = 0, initial_name: String = "Guest") -> void:
	peer_id = initial_peer_id
	display_name = initial_name
	current_health = ConfigStore.player_tuning.base_health
	max_health = ConfigStore.player_tuning.base_health

func reset_for_respawn(player_tuning: PlayerTuning) -> void:
	growth_level = 1
	max_health = player_tuning.get_max_health(growth_level)
	current_health = max_health
	alive = true
	respawn_remaining = 0.0
	last_attacker_id = 0

func apply_growth(player_tuning: PlayerTuning) -> void:
	growth_level = min(growth_level + 1, player_tuning.max_growth_level)
	var previous_max_health := max_health
	max_health = player_tuning.get_max_health(growth_level)
	current_health = min(max_health, current_health + (max_health - previous_max_health))

func take_damage(amount: float, attacker_peer_id: int) -> bool:
	if not alive:
		return false
	last_attacker_id = attacker_peer_id
	current_health = max(current_health - amount, 0.0)
	return current_health <= 0.0

func begin_respawn(delay_seconds: float) -> void:
	alive = false
	current_health = 0.0
	respawn_remaining = delay_seconds
	deaths += 1

func tick_respawn(delta: float) -> bool:
	if alive:
		return false
	respawn_remaining = max(respawn_remaining - delta, 0.0)
	return is_equal_approx(respawn_remaining, 0.0)
