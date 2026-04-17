extends Node
class_name ConfigStore

const PLAYER_TUNING_PATH := "res://resources/data/tuning/player_tuning.tres"
const COMBAT_TUNING_PATH := "res://resources/data/tuning/combat_tuning.tres"
const MATCH_TUNING_PATH := "res://resources/data/tuning/match_tuning.tres"

static var player_tuning: PlayerTuning
static var combat_tuning: CombatTuning
static var match_tuning: MatchTuning

func _ready() -> void:
	reload_resources()

func reload_resources() -> void:
	player_tuning = load(PLAYER_TUNING_PATH) as PlayerTuning
	combat_tuning = load(COMBAT_TUNING_PATH) as CombatTuning
	match_tuning = load(MATCH_TUNING_PATH) as MatchTuning
