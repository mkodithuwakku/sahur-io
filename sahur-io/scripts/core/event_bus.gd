extends Node
class_name EventBusHub

signal connection_status_changed(status: String)
signal leaderboard_updated(entries: Array)
signal local_player_changed(peer_id: int)

static var instance: EventBusHub

func _enter_tree() -> void:
	instance = self
