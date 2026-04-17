extends Control
class_name MainMenu

const GameDirector = preload("res://scripts/core/game_manager.gd")
const NetworkService = preload("res://scripts/network/network_manager.gd")
const AudioService = preload("res://scripts/core/audio_manager.gd")
const MENU_BACKGROUND_SHADER = preload("res://resources/shaders/menu_background.gdshader")

@onready var background: ColorRect = $Background
@onready var frame: PanelContainer = $Shell/Center/Frame
@onready var title_label: Label = $Shell/Center/Frame/Margin/Content/HeroColumn/TitleBlock/Title
@onready var subtitle_label: Label = $Shell/Center/Frame/Margin/Content/HeroColumn/TitleBlock/Subtitle
@onready var eyebrow_label: Label = $Shell/Center/Frame/Margin/Content/HeroColumn/Eyebrow
@onready var footer_label: Label = $Shell/Center/Frame/Margin/Content/HeroColumn/Footer
@onready var action_heading: Label = $Shell/Center/Frame/Margin/Content/ActionColumn/ActionHeading
@onready var name_label: Label = $Shell/Center/Frame/Margin/Content/ActionColumn/NameLabel
@onready var ip_label: Label = $Shell/Center/Frame/Margin/Content/ActionColumn/IPLabel
@onready var name_input: LineEdit = $Shell/Center/Frame/Margin/Content/ActionColumn/NameInput
@onready var ip_input: LineEdit = $Shell/Center/Frame/Margin/Content/ActionColumn/IPInput
@onready var status_card: PanelContainer = $Shell/Center/Frame/Margin/Content/ActionColumn/StatusCard
@onready var status_label: Label = $Shell/Center/Frame/Margin/Content/ActionColumn/StatusCard/Margin/StatusLabel
@onready var hero_pills: Array[PanelContainer] = [
	$Shell/Center/Frame/Margin/Content/HeroColumn/HeroPills/PillPrimary,
	$Shell/Center/Frame/Margin/Content/HeroColumn/HeroPills/PillSecondary,
	$Shell/Center/Frame/Margin/Content/HeroColumn/HeroPills/PillTertiary
]
@onready var host_button: Button = $Shell/Center/Frame/Margin/Content/ActionColumn/Buttons/TopRow/HostButton
@onready var join_button: Button = $Shell/Center/Frame/Margin/Content/ActionColumn/Buttons/TopRow/JoinButton
@onready var settings_button: Button = $Shell/Center/Frame/Margin/Content/ActionColumn/Buttons/BottomRow/SettingsButton
@onready var quit_button: Button = $Shell/Center/Frame/Margin/Content/ActionColumn/Buttons/BottomRow/QuitButton
@onready var settings_backdrop: ColorRect = $SettingsBackdrop
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var settings_copy: Label = $SettingsPanel/Margin/VBox/Copy
@onready var settings_heading: Label = $SettingsPanel/Margin/VBox/Heading
@onready var music_slider: HSlider = $SettingsPanel/Margin/VBox/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/Margin/VBox/SfxSlider
@onready var vibration_toggle: CheckButton = $SettingsPanel/Margin/VBox/VibrationToggle
@onready var close_settings_button: Button = $SettingsPanel/Margin/VBox/CloseButton

func _ready() -> void:
	_apply_background_material()
	_apply_visual_theme()
	_apply_typography()
	_refresh_layout_metrics()
	_set_settings_visible(false, true)
	name_input.text = GameDirector.local_player_name if not GameDirector.local_player_name.is_empty() else GameDirector.generate_guest_name()
	ip_input.text = NetworkService.server_ip
	status_label.text = "Choose Host Match to start a local arena or Join Match for LAN testing."
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	settings_button.pressed.connect(func() -> void:
		_set_settings_visible(true)
	)
	close_settings_button.pressed.connect(func() -> void:
		_set_settings_visible(false)
	)
	settings_backdrop.gui_input.connect(_on_settings_backdrop_input)
	quit_button.visible = OS.has_feature("desktop")
	quit_button.pressed.connect(func() -> void:
		get_tree().quit()
	)
	music_slider.value = AudioService.music_volume
	sfx_slider.value = AudioService.sfx_volume
	vibration_toggle.button_pressed = AudioService.vibration_enabled
	music_slider.value_changed.connect(func(value: float) -> void:
		AudioService.music_volume = value
	)
	sfx_slider.value_changed.connect(func(value: float) -> void:
		AudioService.sfx_volume = value
	)
	vibration_toggle.toggled.connect(func(enabled: bool) -> void:
		AudioService.vibration_enabled = enabled
	)
	NetworkService.instance.connection_status_changed.connect(_set_status)
	call_deferred("_play_intro")
	host_button.grab_focus()

func _on_host_pressed() -> void:
	AudioService.play_ui_click()
	var error: int = GameDirector.start_host(name_input.text)
	if error != OK:
		_set_status("Unable to host match. Error code %d" % error)

func _on_join_pressed() -> void:
	AudioService.play_ui_click()
	var error: int = GameDirector.start_join(name_input.text, ip_input.text)
	if error != OK:
		_set_status("Unable to join match. Error code %d" % error)

func _set_status(status: String) -> void:
	status_label.text = status

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_refresh_layout_metrics()

func _apply_background_material() -> void:
	var material := ShaderMaterial.new()
	material.shader = MENU_BACKGROUND_SHADER
	background.material = material

func _apply_visual_theme() -> void:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", Color(0.92, 0.95, 0.98))
	theme.set_color("font_color", "Button", Color(0.97, 0.99, 1.0))
	theme.set_color("font_focus_color", "Button", Color(0.97, 0.99, 1.0))
	theme.set_color("font_hover_color", "Button", Color(0.97, 0.99, 1.0))
	theme.set_color("font_pressed_color", "Button", Color(0.97, 0.99, 1.0))
	theme.set_color("font_disabled_color", "Button", Color(0.52, 0.58, 0.66, 0.9))
	theme.set_color("font_color", "LineEdit", Color(0.93, 0.97, 1.0))
	theme.set_color("caret_color", "LineEdit", Color(0.84, 0.93, 0.96))
	theme.set_color("selection_color", "LineEdit", Color(0.21, 0.45, 0.58, 0.65))
	theme.set_color("font_color", "CheckButton", Color(0.88, 0.92, 0.96))
	theme.set_stylebox("normal", "LineEdit", _rounded_style(Color(0.09, 0.12, 0.16, 0.92), Color(1, 1, 1, 0.06), 1, 18, 18, 14))
	theme.set_stylebox("focus", "LineEdit", _rounded_style(Color(0.1, 0.14, 0.18, 0.96), Color(0.34, 0.76, 0.67, 0.78), 1, 18, 18, 14))
	theme.set_stylebox("read_only", "LineEdit", _rounded_style(Color(0.08, 0.1, 0.13, 0.82), Color(1, 1, 1, 0.05), 1, 18, 18, 14))
	theme.set_stylebox("normal", "Button", _button_style(Color(0.11, 0.15, 0.19, 0.95), Color(1, 1, 1, 0.08)))
	theme.set_stylebox("hover", "Button", _button_style(Color(0.14, 0.18, 0.23, 0.98), Color(0.41, 0.7, 0.74, 0.32)))
	theme.set_stylebox("pressed", "Button", _button_style(Color(0.09, 0.12, 0.16, 0.98), Color(0.41, 0.7, 0.74, 0.22)))
	theme.set_stylebox("focus", "Button", _button_style(Color(0.14, 0.18, 0.23, 0.98), Color(0.41, 0.7, 0.74, 0.32)))
	theme.set_stylebox("disabled", "Button", _button_style(Color(0.09, 0.11, 0.14, 0.82), Color(1, 1, 1, 0.03)))
	self.theme = theme

	frame.add_theme_stylebox_override("panel", _rounded_style(Color(0.03, 0.06, 0.09, 0.82), Color(1, 1, 1, 0.08), 1, 32, 28, 24))
	status_card.add_theme_stylebox_override("panel", _rounded_style(Color(0.08, 0.11, 0.15, 0.88), Color(1, 1, 1, 0.06), 1, 22, 16, 14))
	settings_panel.add_theme_stylebox_override("panel", _rounded_style(Color(0.04, 0.07, 0.1, 0.96), Color(1, 1, 1, 0.07), 1, 28, 22, 18))
	for pill in hero_pills:
		pill.add_theme_stylebox_override("panel", _rounded_style(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.08), 1, 18, 14, 12))

	_style_action_button(host_button, Color(0.18, 0.53, 0.46, 0.96), Color(0.24, 0.61, 0.53, 1.0), Color(0.14, 0.42, 0.37, 1.0))
	_style_action_button(join_button, Color(0.2, 0.32, 0.55, 0.96), Color(0.26, 0.4, 0.65, 1.0), Color(0.15, 0.25, 0.44, 1.0))
	_style_action_button(settings_button, Color(0.12, 0.16, 0.21, 0.94), Color(0.16, 0.21, 0.27, 1.0), Color(0.09, 0.12, 0.16, 1.0))
	_style_action_button(quit_button, Color(0.16, 0.13, 0.17, 0.94), Color(0.22, 0.16, 0.21, 1.0), Color(0.11, 0.08, 0.11, 1.0))
	_style_action_button(close_settings_button, Color(0.16, 0.2, 0.26, 0.94), Color(0.21, 0.26, 0.33, 1.0), Color(0.12, 0.15, 0.2, 1.0))

func _apply_typography() -> void:
	eyebrow_label.add_theme_font_size_override("font_size", 13)
	eyebrow_label.add_theme_color_override("font_color", Color(0.47, 0.86, 0.75))
	title_label.add_theme_font_size_override("font_size", 56)
	title_label.add_theme_color_override("font_color", Color(0.97, 0.99, 1.0))
	subtitle_label.add_theme_font_size_override("font_size", 19)
	subtitle_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.9))
	footer_label.add_theme_font_size_override("font_size", 15)
	footer_label.add_theme_color_override("font_color", Color(0.62, 0.69, 0.77))
	action_heading.add_theme_font_size_override("font_size", 30)
	action_heading.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	settings_heading.add_theme_font_size_override("font_size", 28)
	settings_heading.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	settings_copy.add_theme_font_size_override("font_size", 15)
	settings_copy.add_theme_color_override("font_color", Color(0.72, 0.79, 0.86))
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.8, 0.86, 0.92))
	for label in [name_label, ip_label]:
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.55, 0.64, 0.73))
	for pill in hero_pills:
		var label := pill.get_node("Margin/Label") as Label
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.96))
	for input in [name_input, ip_input]:
		input.add_theme_font_size_override("font_size", 18)
	for button in [host_button, join_button, settings_button, quit_button, close_settings_button]:
		button.add_theme_font_size_override("font_size", 18)
	vibration_toggle.add_theme_font_size_override("font_size", 16)

func _refresh_layout_metrics() -> void:
	var compact := size.x < 1280 or size.y < 840
	frame.custom_minimum_size = Vector2(900, 0) if compact else Vector2(1100, 0)
	title_label.add_theme_font_size_override("font_size", 46 if compact else 56)
	subtitle_label.add_theme_font_size_override("font_size", 17 if compact else 19)
	action_heading.add_theme_font_size_override("font_size", 26 if compact else 30)
	var input_height := 58.0 if compact else 64.0
	var button_height := 68.0 if compact else 76.0
	name_input.custom_minimum_size.y = input_height
	ip_input.custom_minimum_size.y = input_height
	host_button.custom_minimum_size.y = button_height
	join_button.custom_minimum_size.y = button_height
	settings_button.custom_minimum_size.y = button_height - 4.0
	quit_button.custom_minimum_size.y = button_height - 4.0
	close_settings_button.custom_minimum_size.y = 54.0 if compact else 58.0

func _play_intro() -> void:
	await get_tree().process_frame
	frame.pivot_offset = frame.size * 0.5
	frame.scale = Vector2(0.975, 0.975)
	frame.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(frame, "modulate", Color.WHITE, 0.45)
	tween.parallel().tween_property(frame, "scale", Vector2.ONE, 0.45)

func _set_settings_visible(visible: bool, immediate: bool = false) -> void:
	if immediate:
		settings_backdrop.visible = visible
		settings_panel.visible = visible
		settings_backdrop.modulate = Color(1, 1, 1, 1 if visible else 0)
		settings_panel.modulate = Color(1, 1, 1, 1 if visible else 0)
		settings_panel.scale = Vector2.ONE if visible else Vector2(0.96, 0.96)
		return

	settings_panel.pivot_offset = settings_panel.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if visible:
		settings_backdrop.visible = true
		settings_panel.visible = true
		settings_backdrop.modulate = Color(1, 1, 1, 0)
		settings_panel.modulate = Color(1, 1, 1, 0)
		settings_panel.scale = Vector2(0.96, 0.96)
		tween.tween_property(settings_backdrop, "modulate:a", 1.0, 0.18)
		tween.parallel().tween_property(settings_panel, "modulate:a", 1.0, 0.24)
		tween.parallel().tween_property(settings_panel, "scale", Vector2.ONE, 0.24)
		close_settings_button.grab_focus()
	else:
		tween.tween_property(settings_backdrop, "modulate:a", 0.0, 0.16)
		tween.parallel().tween_property(settings_panel, "modulate:a", 0.0, 0.16)
		tween.parallel().tween_property(settings_panel, "scale", Vector2(0.96, 0.96), 0.16)
		tween.finished.connect(func() -> void:
			settings_backdrop.visible = false
			settings_panel.visible = false
		)
		settings_button.grab_focus()

func _on_settings_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_settings_visible(false)

func _rounded_style(color: Color, border_color: Color, border_width: int, radius: int, margin_x: int, margin_y: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = margin_y
	style.content_margin_bottom = margin_y
	return style

func _button_style(color: Color, border_color: Color) -> StyleBoxFlat:
	return _rounded_style(color, border_color, 1, 20, 18, 14)

func _style_action_button(button: Button, normal_color: Color, hover_color: Color, pressed_color: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_style(normal_color, Color(1, 1, 1, 0.06)))
	button.add_theme_stylebox_override("hover", _button_style(hover_color, Color(1, 1, 1, 0.12)))
	button.add_theme_stylebox_override("pressed", _button_style(pressed_color, Color(1, 1, 1, 0.04)))
	button.add_theme_stylebox_override("focus", _button_style(hover_color, Color(1, 1, 1, 0.12)))
