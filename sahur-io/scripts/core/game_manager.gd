extends Node
class_name GameDirector

const NetworkService = preload("res://scripts/network/network_manager.gd")

const MAIN_MENU_SCENE := preload("res://scenes/main/MainMenu.tscn")
const GAME_WORLD_SCENE := preload("res://scenes/main/GameWorld.tscn")
const DEFAULT_LOCAL_CPU_COUNT := 4

enum MatchMode {
	ONLINE,
	LOCAL_PROTOTYPE
}

static var local_player_name: String = ""
static var root_container: Node = null
static var active_scene: Node = null
static var current_match_mode: MatchMode = MatchMode.ONLINE
static var local_prototype_cpu_count: int = 0

func _ready() -> void:
	randomize()
	_ensure_input_actions()

static func bind_root(scene_root: Node) -> void:
	root_container = scene_root

static func generate_guest_name() -> String:
	var prefixes := ["Tun", "Sahur", "Bat", "Bongo", "Boom", "Night", "Arena", "Drum"]
	var suffixes := ["Hero", "Brawler", "Runner", "Giant", "Chaser", "King", "Boss", "Scout"]
	return "%s%s%d" % [prefixes[randi() % prefixes.size()], suffixes[randi() % suffixes.size()], randi_range(10, 99)]

static func sanitize_name(raw_name: String) -> String:
	var regex := RegEx.new()
	regex.compile("[^A-Za-z0-9 _-]")
	var cleaned := regex.sub(raw_name.strip_edges(), "", true)
	if cleaned.is_empty():
		cleaned = generate_guest_name()
	return cleaned.substr(0, min(cleaned.length(), 14))

static func show_main_menu() -> void:
	_swap_scene(MAIN_MENU_SCENE.instantiate())

static func show_game_world() -> void:
	_swap_scene(GAME_WORLD_SCENE.instantiate())

static func start_host(display_name: String) -> int:
	local_player_name = sanitize_name(display_name)
	current_match_mode = MatchMode.ONLINE
	local_prototype_cpu_count = 0
	NetworkService.local_player_name = local_player_name
	var error: int = NetworkService.host_match()
	if error == OK:
		show_game_world()
	return error

static func start_join(display_name: String, ip_address: String) -> int:
	local_player_name = sanitize_name(display_name)
	current_match_mode = MatchMode.ONLINE
	local_prototype_cpu_count = 0
	NetworkService.local_player_name = local_player_name
	var error: int = NetworkService.join_match(ip_address)
	if error == OK:
		show_game_world()
	return error

static func start_local_prototype(display_name: String, cpu_count: int = DEFAULT_LOCAL_CPU_COUNT) -> int:
	local_player_name = sanitize_name(display_name)
	current_match_mode = MatchMode.LOCAL_PROTOTYPE
	local_prototype_cpu_count = maxi(cpu_count, 1)
	NetworkService.local_player_name = local_player_name
	NetworkService.close_peer()
	NetworkService.set_connection_status("Local Prototype · %d CPU Opponents" % local_prototype_cpu_count)
	show_game_world()
	return OK

static func is_local_prototype_mode() -> bool:
	return current_match_mode == MatchMode.LOCAL_PROTOTYPE

static func get_local_prototype_cpu_count() -> int:
	return local_prototype_cpu_count

static func leave_to_menu() -> void:
	current_match_mode = MatchMode.ONLINE
	local_prototype_cpu_count = 0
	NetworkService.close_peer()
	show_main_menu()

static func _swap_scene(new_scene: Node) -> void:
	if root_container == null:
		return
	if active_scene != null:
		active_scene.queue_free()
	active_scene = new_scene
	root_container.add_child(active_scene)

static func _ensure_input_actions() -> void:
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_left", KEY_LEFT)
	_add_key_action("move_right", KEY_D)
	_add_key_action("move_right", KEY_RIGHT)
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_up", KEY_UP)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_down", KEY_DOWN)
	_add_key_action("attack", KEY_SPACE)
	_add_mouse_button_action("attack", MOUSE_BUTTON_LEFT)
	_add_key_action("leave_match", KEY_ESCAPE)

static func _add_key_action(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if not _has_key_binding(action, keycode, false):
		var key_event := InputEventKey.new()
		key_event.keycode = keycode
		InputMap.action_add_event(action, key_event)
	if _should_add_physical_binding(keycode) and not _has_key_binding(action, keycode, true):
		var physical_event := InputEventKey.new()
		physical_event.physical_keycode = keycode
		InputMap.action_add_event(action, physical_event)

static func _add_mouse_button_action(action: String, button_index: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton and event.button_index == button_index:
			return
	var input_event := InputEventMouseButton.new()
	input_event.button_index = button_index
	InputMap.action_add_event(action, input_event)

static func _has_key_binding(action: String, keycode: Key, use_physical: bool) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			if use_physical and event.physical_keycode == keycode:
				return true
			if not use_physical and event.keycode == keycode:
				return true
	return false

static func _should_add_physical_binding(keycode: Key) -> bool:
	return (keycode >= KEY_A and keycode <= KEY_Z) or (keycode >= KEY_0 and keycode <= KEY_9)
