extends SceneTree

const ConfigStore = preload("res://scripts/core/config.gd")
const TestPlayerTuning = preload("res://tests/cases/test_player_tuning.gd")
const TestPlayerStats = preload("res://tests/cases/test_player_stats.gd")
const TestPlayerCombat = preload("res://tests/cases/test_player_combat.gd")
const TestSpawnManager = preload("res://tests/cases/test_spawn_manager.gd")
const TestServerGameState = preload("res://tests/cases/test_server_game_state.gd")
const TestReplicationHelpers = preload("res://tests/cases/test_replication_helpers.gd")
const TestPlayerController = preload("res://tests/cases/test_player_controller.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_load_tuning_resources()
	var suites: Array = [
		TestPlayerTuning.new(),
		TestPlayerStats.new(),
		TestPlayerCombat.new(),
		TestSpawnManager.new(),
		TestServerGameState.new(),
		TestReplicationHelpers.new(),
		TestPlayerController.new()
	]
	var total_tests: int = 0
	var total_assertions: int = 0
	var total_failures: int = 0
	print("Running Godot gameplay tests...")
	for suite in suites:
		suite.test_root = root
		var suite_results: Array = suite.run_suite()
		print("")
		print("Suite: %s" % suite.suite_name())
		for result in suite_results:
			total_tests += 1
			total_assertions += result["assertions"]
			if result["passed"]:
				print("  PASS %s (%d assertions)" % [result["name"], result["assertions"]])
			else:
				total_failures += 1
				print("  FAIL %s (%d assertions)" % [result["name"], result["assertions"]])
				for failure in result["failures"]:
					print("    %s" % failure)
	print("")
	print("Summary: %d suites, %d tests, %d assertions, %d failures" % [
		suites.size(),
		total_tests,
		total_assertions,
		total_failures
	])
	quit(0 if total_failures == 0 else 1)

func _load_tuning_resources() -> void:
	ConfigStore.player_tuning = load(ConfigStore.PLAYER_TUNING_PATH) as PlayerTuning
	ConfigStore.combat_tuning = load(ConfigStore.COMBAT_TUNING_PATH) as CombatTuning
	ConfigStore.match_tuning = load(ConfigStore.MATCH_TUNING_PATH) as MatchTuning
