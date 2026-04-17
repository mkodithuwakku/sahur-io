extends Control
class_name HUD

const ConfigStore = preload("res://scripts/core/config.gd")

signal leave_requested

@onready var joystick: VirtualJoystick = $VirtualJoystick
@onready var attack_button: AttackButton = $AttackButton
@onready var health_bar: ProgressBar = $TopBar/HealthBar
@onready var stats_label: Label = $TopBar/StatsLabel
@onready var growth_label: Label = $TopBar/GrowthLabel
@onready var status_label: Label = $TopBar/StatusLabel
@onready var cooldown_bar: ProgressBar = $TopBar/CooldownBar
@onready var leaderboard: Leaderboard = $Leaderboard
@onready var respawn_overlay: RespawnOverlay = $RespawnOverlay
@onready var leave_button: Button = $LeaveButton

func _ready() -> void:
	leave_button.pressed.connect(func() -> void:
		leave_requested.emit()
	)

func get_move_vector() -> Vector2:
	var keyboard: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var touch_vector: Vector2 = joystick.get_vector()
	if touch_vector.length_squared() > keyboard.length_squared():
		return touch_vector
	return keyboard

func consume_attack_pressed() -> bool:
	return attack_button.consume_attack() or Input.is_action_just_pressed("attack")

func set_local_state(state: Dictionary) -> void:
	if state.is_empty():
		health_bar.max_value = 100.0
		health_bar.value = 0.0
		stats_label.text = "Waiting for spawn..."
		growth_label.text = "Growth 1"
		cooldown_bar.value = 0.0
		respawn_overlay.update_state(false, 0.0, "")
		return
	var max_health: float = float(state.get("max_health", 100.0))
	max_health = maxf(max_health, 1.0)
	var current_health: float = float(state.get("health", max_health))
	health_bar.max_value = max_health
	health_bar.value = current_health
	stats_label.text = "Kills %d  Deaths %d" % [state.get("kills", 0), state.get("deaths", 0)]
	growth_label.text = "Growth %d" % state.get("growth", 1)
	var cooldown: float = float(state.get("cooldown", 0.0))
	var cooldown_fraction: float = 1.0 - clampf(cooldown / maxf(ConfigStore.combat_tuning.cooldown, 0.01), 0.0, 1.0)
	cooldown_bar.value = cooldown_fraction * 100.0
	respawn_overlay.update_state(not state.get("alive", true), state.get("respawn", 0.0), state.get("killer_name", ""))

func set_connection_status(status: String) -> void:
	status_label.text = status

func set_leaderboard(entries: Array) -> void:
	leaderboard.set_entries(entries)
