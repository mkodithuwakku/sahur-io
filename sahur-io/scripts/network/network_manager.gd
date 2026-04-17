extends Node
class_name NetworkService

const ConfigStore = preload("res://scripts/core/config.gd")
const EventBusHub = preload("res://scripts/core/event_bus.gd")

signal hosting_started
signal connected_to_server
signal connection_failed
signal server_disconnected
signal peer_connected_to_session(peer_id: int)
signal peer_disconnected_from_session(peer_id: int)
signal connection_status_changed(status: String)

static var instance: NetworkService
static var local_player_name: String = "Guest"
static var server_ip: String = "127.0.0.1"
static var last_status: String = "Offline"

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

static func host_match(port: int = 0) -> int:
	return instance._host_match(port)

static func join_match(ip_address: String, port: int = 0) -> int:
	return instance._join_match(ip_address, port)

static func close_peer() -> void:
	if instance != null:
		instance._close_peer()

static func set_connection_status(status: String) -> void:
	if instance != null:
		instance._set_status(status)
	else:
		last_status = status

static func is_server() -> bool:
	return instance != null and instance.multiplayer.has_multiplayer_peer() and instance.multiplayer.is_server()

static func is_client() -> bool:
	return instance != null and instance.multiplayer.has_multiplayer_peer() and not instance.multiplayer.is_server()

static func is_online() -> bool:
	return instance != null and instance.multiplayer.has_multiplayer_peer()

static func get_local_peer_id() -> int:
	if instance == null or not instance.multiplayer.has_multiplayer_peer():
		return 0
	return instance.multiplayer.get_unique_id()

func _host_match(port: int = 0) -> int:
	close_peer()
	var peer := ENetMultiplayerPeer.new()
	var effective_port: int = port if port > 0 else ConfigStore.match_tuning.network_port
	var error := peer.create_server(effective_port, ConfigStore.match_tuning.max_players)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	_set_status("Hosting on port %d" % effective_port)
	hosting_started.emit()
	return OK

func _join_match(ip_address: String, port: int = 0) -> int:
	_close_peer()
	server_ip = ip_address.strip_edges()
	if server_ip.is_empty():
		server_ip = "127.0.0.1"
	var peer := ENetMultiplayerPeer.new()
	var effective_port: int = port if port > 0 else ConfigStore.match_tuning.network_port
	var error := peer.create_client(server_ip, effective_port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	_set_status("Connecting to %s:%d" % [server_ip, effective_port])
	return OK

func _close_peer() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	_set_status("Offline")

func _set_status(status: String) -> void:
	last_status = status
	connection_status_changed.emit(status)
	if EventBusHub.instance != null:
		EventBusHub.instance.connection_status_changed.emit(status)

func _on_connected_to_server() -> void:
	_set_status("Connected to %s" % server_ip)
	connected_to_server.emit()

func _on_connection_failed() -> void:
	_set_status("Connection failed")
	connection_failed.emit()

func _on_server_disconnected() -> void:
	_set_status("Disconnected from server")
	server_disconnected.emit()

func _on_peer_connected(peer_id: int) -> void:
	peer_connected_to_session.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	peer_disconnected_from_session.emit(peer_id)
