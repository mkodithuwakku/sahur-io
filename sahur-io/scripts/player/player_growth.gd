extends RefCounted
class_name PlayerGrowth

func apply_kill_growth(stats: PlayerStats, player_tuning: PlayerTuning) -> void:
	stats.apply_growth(player_tuning)

func get_scale(stats: PlayerStats, player_tuning: PlayerTuning) -> float:
	return player_tuning.get_scale(stats.growth_level)

func get_move_speed(stats: PlayerStats, player_tuning: PlayerTuning) -> float:
	return player_tuning.get_move_speed(stats.growth_level)
