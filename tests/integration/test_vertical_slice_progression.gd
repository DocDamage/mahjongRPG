extends RefCounted

const GameSessionScript = preload("res://src/core/game_session.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var session = GameSessionScript.new()
	session.start_new_game(2026)
	if session.quests.start(&"first_lantern") != OK:
		failures.append("the Hall restoration quest should be available in a new slice session")
	if session.inventory.add_item(&"crop_beans") != OK or session.inventory.record_fish(&"anchovy", 45) != OK:
		failures.append("slice quest requirements should accept farm and fishing inventory")
	if session.quests.complete(&"first_lantern") != OK:
		failures.append("the supplied requirements should complete the first Hall restoration milestone")
	if not session.quests.unlocked_helpers.has(&"mabel") or not session.quests.hall_milestones.has(&"first_lantern"):
		failures.append("completion must unlock Mabel and Riverbend's access milestone")
	var snapshot := session.snapshot()
	var restored = GameSessionScript.new()
	if restored.restore(snapshot) != OK or not restored.quests.hall_milestones.has(&"first_lantern"):
		failures.append("progression state must survive save/load")
	session.free()
	restored.free()
	return failures
