extends CenterContainer
class_name RespawnOverlay

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var detail_label: Label = $Panel/Margin/VBox/Detail

func update_state(is_dead: bool, remaining: float, killer_name: String) -> void:
	visible = is_dead
	if not is_dead:
		return
	title_label.text = "You were eliminated"
	if killer_name.is_empty():
		detail_label.text = "Respawning in %.1fs" % remaining
	else:
		detail_label.text = "KO by %s\nRespawning in %.1fs" % [killer_name, remaining]
