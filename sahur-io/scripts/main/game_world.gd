extends Node3D
class_name GameWorld

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const NetworkService = preload("res://scripts/network/network_manager.gd")
const GameDirector = preload("res://scripts/core/game_manager.gd")
const ConfigStore = preload("res://scripts/core/config.gd")
const EventBusHub = preload("res://scripts/core/event_bus.gd")
const LocalBotController = preload("res://scripts/player/local_bot_controller.gd")

const LOCAL_PROTOTYPE_PLAYER_PEER_ID := 1
const LOCAL_BOT_PEER_ID_START := 1000

var server_state: ServerGameState = ServerGameState.new()
var spawn_manager: SpawnManager
var snapshot_replicator: ReplicationManager = ReplicationManager.new()
var input_replicator: ReplicationManager = ReplicationManager.new()
var player_nodes: Dictionary = {}
var bot_controllers: Dictionary = {}
var join_requested: bool = false
var local_player: PlayerController = null

@onready var arena: ArenaManager = $Arena01
@onready var players_root: Node3D = $Players
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var hud: HUD = $HUDLayer/HUD

func _ready() -> void:
	spawn_manager = SpawnManager.new(arena)
	NetworkService.instance.connected_to_server.connect(_on_connected_to_server)
	NetworkService.instance.connection_failed.connect(_on_connection_failed)
	NetworkService.instance.server_disconnected.connect(_on_server_disconnected)
	NetworkService.instance.peer_disconnected_from_session.connect(_on_peer_disconnected)
	NetworkService.instance.connection_status_changed.connect(hud.set_connection_status)
	hud.leave_requested.connect(_on_leave_requested)
	hud.set_connection_status(NetworkService.last_status)
	if GameDirector.is_local_prototype_mode():
		var local_spawn: Vector3 = _choose_spawn(LOCAL_PROTOTYPE_PLAYER_PEER_ID)
		_spawn_player_local(LOCAL_PROTOTYPE_PLAYER_PEER_ID, NetworkService.local_player_name, local_spawn)
		_spawn_local_bots(GameDirector.get_local_prototype_cpu_count())
		_broadcast_snapshot()
	elif NetworkService.is_server() and not _is_dedicated_server_mode():
		var host_spawn: Vector3 = _choose_spawn(multiplayer.get_unique_id())
		_spawn_player_everywhere(multiplayer.get_unique_id(), NetworkService.local_player_name, host_spawn)
	elif NetworkService.is_client() and NetworkService.last_status.begins_with("Connected"):
		_request_join_once()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("leave_match") and not _is_dedicated_server_mode():
		_on_leave_requested()
		return
	_collect_local_input(delta)
	if GameDirector.is_local_prototype_mode() and _has_authority():
		_update_local_bots()
	if _has_authority() and snapshot_replicator.tick(delta, ConfigStore.match_tuning.snapshot_rate):
		_broadcast_snapshot()
	_update_camera(delta)
	_update_hud()

@rpc("any_peer", "reliable")
func _server_request_join(player_name: String) -> void:
	if not NetworkService.is_server():
		return
	var requester_id: int = multiplayer.get_remote_sender_id()
	if requester_id <= 0:
		return
	var safe_name: String = GameDirector.sanitize_name(player_name)
	_sync_existing_players_to(requester_id)
	if server_state.has_player(requester_id):
		_send_snapshot_to(requester_id)
		return
	var spawn_position: Vector3 = _choose_spawn(requester_id)
	_spawn_player_everywhere(requester_id, safe_name, spawn_position)
	_send_snapshot_to(requester_id)
	_broadcast_snapshot()

@rpc("any_peer", "unreliable")
func _server_receive_input(move_input: Vector2) -> void:
	if not NetworkService.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	var player := server_state.get_player(sender_id) as PlayerController
	if player == null:
		return
	player.set_input_vector(move_input.limit_length(1.0))

@rpc("any_peer", "reliable")
func _server_receive_attack(facing: Vector3) -> void:
	if not NetworkService.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_handle_attack_for_peer(sender_id, facing)

@rpc("authority", "reliable")
func _spawn_player_remote(peer_id: int, player_name: String, spawn_position: Vector3) -> void:
	_spawn_player_local(peer_id, player_name, spawn_position)

@rpc("authority", "reliable")
func _remove_player_remote(peer_id: int) -> void:
	_remove_player_local(peer_id)

@rpc("authority", "reliable")
func _play_attack_remote(peer_id: int) -> void:
	var player := player_nodes.get(peer_id, null) as PlayerController
	if player == null or player.is_local_player:
		return
	player.combat.begin_attack()
	player._play_attack_feedback(false)

@rpc("authority", "unreliable")
func _receive_world_snapshot(snapshot: Dictionary) -> void:
	_apply_snapshot(snapshot)

func _collect_local_input(delta: float) -> void:
	if local_player == null or _is_dedicated_server_mode():
		return
	var move_input: Vector2 = hud.get_move_vector()
	local_player.set_input_vector(move_input)
	if not GameDirector.is_local_prototype_mode() and not NetworkService.is_server() and input_replicator.tick(delta, ConfigStore.match_tuning.input_send_rate):
		rpc_id(1, "_server_receive_input", move_input)
	var should_attack := false
	if local_player.is_targetable() and local_player.combat.can_attack() and hud.has_queued_attack():
		should_attack = hud.consume_attack_pressed()
	elif Input.is_action_just_pressed("attack"):
		should_attack = true
	if should_attack:
		var attack_facing: Vector3 = local_player.get_attack_facing()
		if move_input.length_squared() > 0.0001:
			attack_facing = Vector3(move_input.x, 0.0, move_input.y).normalized()
		local_player.set_attack_facing(attack_facing)
		if _has_authority():
			_handle_attack_for_peer(local_player.peer_id, attack_facing)
		elif local_player.begin_attack_preview():
				rpc_id(1, "_server_receive_attack", attack_facing)

func _handle_attack_for_peer(peer_id: int, facing: Vector3, should_broadcast: bool = true) -> bool:
	var player := server_state.get_player(peer_id) as PlayerController
	if player == null:
		return false
	if not player.can_start_attack():
		return false
	player.set_attack_facing(facing)
	var hits: Array = player.server_process_attack(server_state.get_players())
	if NetworkService.is_online():
		rpc("_play_attack_remote", peer_id)
	for hit in hits:
		if hit.get("defeated", false):
			player.server_register_kill()
	if should_broadcast:
		_broadcast_snapshot()
	return true

func _request_join_once() -> void:
	if join_requested:
		return
	join_requested = true
	rpc_id(1, "_server_request_join", NetworkService.local_player_name)

func _spawn_player_everywhere(peer_id: int, player_name: String, spawn_position: Vector3) -> void:
	_spawn_player_local(peer_id, player_name, spawn_position)
	if NetworkService.is_online():
		rpc("_spawn_player_remote", peer_id, player_name, spawn_position)

func _spawn_player_local(peer_id: int, player_name: String, spawn_position: Vector3) -> PlayerController:
	if player_nodes.has(peer_id):
		return player_nodes[peer_id]
	var player := PLAYER_SCENE.instantiate() as PlayerController
	player.name = "Player_%d" % peer_id
	var local_peer_id: int = NetworkService.get_local_peer_id() if NetworkService.is_online() else LOCAL_PROTOTYPE_PLAYER_PEER_ID
	var has_server_authority: bool = NetworkService.is_server() or GameDirector.is_local_prototype_mode()
	player.setup(peer_id, player_name, local_peer_id, has_server_authority, arena.bounds_extents)
	players_root.add_child(player)
	player.global_position = spawn_position
	player.respawn_requested.connect(_on_player_respawn_requested)
	player_nodes[peer_id] = player
	if has_server_authority:
		server_state.register_player(peer_id, player_name, player)
	if peer_id == local_peer_id and not _is_dedicated_server_mode():
		local_player = player
		EventBusHub.instance.local_player_changed.emit(peer_id)
	return player

func _spawn_local_bots(cpu_count: int) -> void:
	for index in range(cpu_count):
		var bot_peer_id := LOCAL_BOT_PEER_ID_START + index + 1
		if player_nodes.has(bot_peer_id):
			continue
		var bot_name := "CPU %d" % (index + 1)
		var bot := _spawn_player_local(bot_peer_id, bot_name, _choose_spawn(bot_peer_id))
		bot.set_attack_facing(Vector3.FORWARD.rotated(Vector3.UP, float(index) * 1.3))
		bot_controllers[bot_peer_id] = LocalBotController.new(bot_peer_id)
	_broadcast_snapshot()

func _remove_player_local(peer_id: int) -> void:
	var player := player_nodes.get(peer_id, null) as PlayerController
	if player == null:
		return
	if local_player == player:
		local_player = null
	player_nodes.erase(peer_id)
	if _has_authority():
		server_state.unregister_player(peer_id)
	bot_controllers.erase(peer_id)
	player.queue_free()

func _sync_existing_players_to(peer_id: int) -> void:
	for player in server_state.get_players():
		rpc_id(peer_id, "_spawn_player_remote", player.peer_id, player.display_name, player.global_position)

func _send_snapshot_to(peer_id: int) -> void:
	rpc_id(peer_id, "_receive_world_snapshot", server_state.build_snapshot())

func _broadcast_snapshot() -> void:
	if not _has_authority():
		return
	var snapshot: Dictionary = server_state.build_snapshot()
	_apply_snapshot(snapshot)
	if NetworkService.is_online():
		rpc("_receive_world_snapshot", snapshot)

func _apply_snapshot(snapshot: Dictionary) -> void:
	var leaderboard_entries: Array = snapshot.get("leaderboard", [])
	hud.set_leaderboard(leaderboard_entries)
	EventBusHub.instance.leaderboard_updated.emit(leaderboard_entries)
	var players: Array = snapshot.get("players", [])
	for state in players:
		var peer_id: int = state.get("peer_id", 0)
		if not player_nodes.has(peer_id):
			_spawn_player_local(peer_id, state.get("name", "Guest"), state.get("position", Vector3.ZERO))
		var player := player_nodes.get(peer_id, null) as PlayerController
		if player != null:
			player.apply_state_snapshot(state)
			var local_peer_id: int = NetworkService.get_local_peer_id() if NetworkService.is_online() else LOCAL_PROTOTYPE_PLAYER_PEER_ID
			if peer_id == local_peer_id and not _is_dedicated_server_mode():
				local_player = player

func _update_camera(delta: float) -> void:
	if local_player == null:
		return
	camera_rig.global_position = camera_rig.global_position.lerp(local_player.global_position, clamp(delta * 6.0, 0.0, 1.0))
	camera.position = camera.position.lerp(ConfigStore.player_tuning.get_camera_offset(local_player.stats.growth_level), clamp(delta * 5.0, 0.0, 1.0))

func _update_hud() -> void:
	if GameDirector.is_local_prototype_mode():
		var leaderboard_entries: Array = server_state.build_leaderboard(ConfigStore.match_tuning.leaderboard_size)
		hud.set_leaderboard(leaderboard_entries)
		EventBusHub.instance.leaderboard_updated.emit(leaderboard_entries)
	if local_player == null:
		hud.set_local_state({})
		return
	var killer_name: String = _get_player_name(local_player.stats.last_attacker_id)
	hud.set_local_state(local_player.build_ui_state(killer_name))

func _choose_spawn(excluded_peer_id: int) -> Vector3:
	var occupied: Array[Vector3] = server_state.get_active_positions(excluded_peer_id)
	return spawn_manager.choose_spawn(occupied, ConfigStore.match_tuning.spawn_safety_radius)

func _update_local_bots() -> void:
	var any_attack_started := false
	var candidates: Array = _build_bot_candidates()
	for peer_id in bot_controllers.keys():
		var player := player_nodes.get(peer_id, null) as PlayerController
		if player == null:
			continue
		if not player.stats.alive:
			player.set_input_vector(Vector2.ZERO)
			continue
		var controller := bot_controllers.get(peer_id) as LocalBotController
		var decision: Dictionary = controller.build_decision(
			peer_id,
			player.global_position,
			player.get_attack_facing(),
			player.stats.growth_level,
			candidates
		)
		player.set_input_vector(decision.get("move_input", Vector2.ZERO))
		player.set_attack_facing(decision.get("facing", player.get_attack_facing()))
		if decision.get("attack", false):
			any_attack_started = _handle_attack_for_peer(peer_id, decision.get("facing", player.get_attack_facing()), false) or any_attack_started
	if any_attack_started:
		_broadcast_snapshot()

func _build_bot_candidates() -> Array:
	var candidates: Array = []
	for player in server_state.get_players():
		candidates.append({
			"peer_id": player.peer_id,
			"position": player.global_position,
			"alive": player.stats.alive
		})
	return candidates

func _get_player_name(peer_id: int) -> String:
	var player := player_nodes.get(peer_id, null) as PlayerController
	if player == null:
		return ""
	return player.display_name

func _on_player_respawn_requested(peer_id: int) -> void:
	if not _has_authority():
		return
	var player := server_state.get_player(peer_id) as PlayerController
	if player == null:
		return
	player.server_respawn(_choose_spawn(peer_id))
	_broadcast_snapshot()

func _on_connected_to_server() -> void:
	_request_join_once()

func _on_connection_failed() -> void:
	if _is_dedicated_server_mode():
		return
	GameDirector.leave_to_menu()

func _on_server_disconnected() -> void:
	if _is_dedicated_server_mode():
		return
	GameDirector.leave_to_menu()

func _on_peer_disconnected(peer_id: int) -> void:
	if not NetworkService.is_server():
		return
	if not server_state.has_player(peer_id):
		return
	_remove_player_local(peer_id)
	rpc("_remove_player_remote", peer_id)
	_broadcast_snapshot()

func _on_leave_requested() -> void:
	if _is_dedicated_server_mode():
		return
	GameDirector.leave_to_menu()

func _is_dedicated_server_mode() -> bool:
	return "--server" in OS.get_cmdline_args()

func _has_authority() -> bool:
	return NetworkService.is_server() or GameDirector.is_local_prototype_mode()
