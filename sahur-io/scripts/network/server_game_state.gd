extends RefCounted
class_name ServerGameState

const ConfigStore = preload("res://scripts/core/config.gd")

var player_nodes: Dictionary = {}
var player_names: Dictionary = {}
var started_at_unix: int = 0

func _init() -> void:
	started_at_unix = Time.get_unix_time_from_system()

func register_player(peer_id: int, player_name: String, player_node: Node) -> void:
	player_names[peer_id] = player_name
	player_nodes[peer_id] = player_node

func unregister_player(peer_id: int) -> void:
	player_names.erase(peer_id)
	player_nodes.erase(peer_id)

func has_player(peer_id: int) -> bool:
	return player_nodes.has(peer_id)

func get_player(peer_id: int) -> Node:
	return player_nodes.get(peer_id, null)

func get_players() -> Array:
	var result: Array = []
	for player in player_nodes.values():
		if is_instance_valid(player):
			result.append(player)
	return result

func get_active_positions(excluded_peer_id: int = 0) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for peer_id in player_nodes.keys():
		if peer_id == excluded_peer_id:
			continue
		var player = player_nodes[peer_id]
		if is_instance_valid(player) and player.stats.alive:
			positions.append(player.global_position)
	return positions

func build_leaderboard(limit: int) -> Array:
	var entries: Array = []
	for player in get_players():
		var score: int = player.stats.kills * 100 + player.stats.growth_level * 10 - player.stats.deaths * 5
		entries.append({
			"peer_id": player.peer_id,
			"name": player.display_name,
			"kills": player.stats.kills,
			"deaths": player.stats.deaths,
			"growth": player.stats.growth_level,
			"score": score
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["score"] == b["score"]:
			return a["deaths"] < b["deaths"]
		return a["score"] > b["score"]
	)
	if limit <= 0 or entries.size() <= limit:
		return entries
	return entries.slice(0, limit)

func build_snapshot() -> Dictionary:
	var players: Array = []
	for player in get_players():
		players.append(player.build_state_snapshot())
	return {
		"players": players,
		"leaderboard": build_leaderboard(ConfigStore.match_tuning.leaderboard_size),
		"uptime": Time.get_unix_time_from_system() - started_at_unix
	}
