extends Button
class_name AttackButton

signal attack_requested

var queued_attack: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)

func consume_attack() -> bool:
	var result := queued_attack
	queued_attack = false
	return result

func _on_pressed() -> void:
	queued_attack = true
	attack_requested.emit()
