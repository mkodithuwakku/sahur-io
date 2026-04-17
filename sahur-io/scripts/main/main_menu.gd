extends Control
class_name MainMenu

const GameDirector = preload("res://scripts/core/game_manager.gd")
const NetworkService = preload("res://scripts/network/network_manager.gd")
const AudioService = preload("res://scripts/core/audio_manager.gd")

@onready var name_input: LineEdit = $Center/VBox/NameInput
@onready var ip_input: LineEdit = $Center/VBox/IPInput
@onready var status_label: Label = $Center/VBox/StatusLabel
@onready var host_button: Button = $Center/VBox/Buttons/HostButton
@onready var join_button: Button = $Center/VBox/Buttons/JoinButton
@onready var settings_button: Button = $Center/VBox/Buttons/SettingsButton
@onready var quit_button: Button = $Center/VBox/Buttons/QuitButton
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var music_slider: HSlider = $SettingsPanel/Margin/VBox/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/Margin/VBox/SfxSlider
@onready var vibration_toggle: CheckButton = $SettingsPanel/Margin/VBox/VibrationToggle
@onready var close_settings_button: Button = $SettingsPanel/Margin/VBox/CloseButton

func _ready() -> void:
	name_input.text = GameDirector.local_player_name if not GameDirector.local_player_name.is_empty() else GameDirector.generate_guest_name()
	ip_input.text = NetworkService.server_ip
	status_label.text = "Choose Host Match to start a local arena or Join Match for LAN testing."
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	settings_button.pressed.connect(_toggle_settings)
	close_settings_button.pressed.connect(_toggle_settings)
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

func _toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible

func _set_status(status: String) -> void:
	status_label.text = status
