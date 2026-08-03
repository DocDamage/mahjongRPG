extends RefCounted

const GameSessionScript = preload("res://src/core/game_session.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var session = GameSessionScript.new()
	session.start_new_game(404)
	var pre_phase_four := session.snapshot()
	pre_phase_four["schema_version"] = 8
	pre_phase_four["brands"].erase("upgrades")
	pre_phase_four["brands"].erase("upgrade_points")
	pre_phase_four["brands"].erase("match_wins")
	pre_phase_four["brands"].erase("hall_stage")
	pre_phase_four["brands"].erase("unlocked_rulesets")
	pre_phase_four["brands"].erase("discovered_deeds")
	var restored = GameSessionScript.new()
	if restored.restore(pre_phase_four) != OK or restored.brands.hall_stage != 1 or not restored.brands.match_wins.is_empty() or restored.brands.upgrade_points != 0 or not restored.brands.unlocked_rulesets.has(&"trail") or not restored.brands.discovered_deeds.is_empty():
		failures.append("pre-P4 schema-eight saves must migrate safe rules, mastery, upgrade, and Hall-cleanup defaults")
	session.free(); restored.free()
	return failures
