extends Button
class_name AttackButton

signal attack_requested

const MAX_QUEUED_ATTACKS := 4

var queued_attack_count: int = 0
var _touch_id: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button_down.connect(_queue_attack)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_touch_id = touch_event.index
			_queue_attack()
			accept_event()
		elif touch_event.index == _touch_id:
			_touch_id = -1
			accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_queue_attack()
		accept_event()

func consume_attack() -> bool:
	if queued_attack_count <= 0:
		return false
	queued_attack_count -= 1
	return true

func _queue_attack() -> void:
	queued_attack_count = mini(queued_attack_count + 1, MAX_QUEUED_ATTACKS)
	attack_requested.emit()
