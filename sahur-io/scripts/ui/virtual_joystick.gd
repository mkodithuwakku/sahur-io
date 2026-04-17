extends Control
class_name VirtualJoystick

signal vector_changed(new_vector: Vector2)

@export var radius: float = 72.0

var _vector: Vector2 = Vector2.ZERO
var _touch_id: int = -1

@onready var knob: Control = $Knob

func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.4, radius * 2.4)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_reset_knob()

func get_vector() -> Vector2:
	return _vector

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_id = -2
			_update_vector(get_local_mouse_position())
		else:
			_release_pointer()
	elif event is InputEventMouseMotion and _touch_id == -2:
		_update_vector(get_local_mouse_position())

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and _touch_id == -1:
		_touch_id = event.index
		_update_vector(event.position - global_position)
	elif not event.pressed and event.index == _touch_id:
		_release_pointer()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_id:
		return
	_update_vector(event.position - global_position)

func _update_vector(local_position: Vector2) -> void:
	var center := size * 0.5
	var delta := local_position - center
	_vector = delta.limit_length(radius) / max(radius, 1.0)
	knob.position = center - knob.size * 0.5 + _vector * radius
	vector_changed.emit(_vector)

func _release_pointer() -> void:
	_touch_id = -1
	_vector = Vector2.ZERO
	_reset_knob()
	vector_changed.emit(_vector)

func _reset_knob() -> void:
	if knob != null:
		knob.position = size * 0.5 - knob.size * 0.5
