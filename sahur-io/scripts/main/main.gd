extends Node
class_name Main

const GameDirector = preload("res://scripts/core/game_manager.gd")
const NetworkService = preload("res://scripts/network/network_manager.gd")

@onready var scene_root: Node = $SceneRoot

func _ready() -> void:
	GameDirector.bind_root(scene_root)
	if _is_server_boot():
		NetworkService.local_player_name = "DedicatedServer"
		var error: int = NetworkService.host_match()
		if error == OK:
			GameDirector.show_game_world()
		else:
			push_error("Dedicated server failed to start: %d" % error)
	else:
		GameDirector.show_main_menu()

func _is_server_boot() -> bool:
	return "--server" in OS.get_cmdline_args()
