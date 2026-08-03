extends RefCounted

const GameSessionScript = preload("res://src/core/game_session.gd")
const FirstLanternCoordinator = preload("res://src/quests/first_lantern_coordinator.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var session = GameSessionScript.new()
	session.start_new_game(2026)
	var coordinator = FirstLanternCoordinator.new()
	coordinator.configure(session.quests, session.inventory, session.helpers, session.evidence, session.quest_events)
	if coordinator.introduce() != session.quests.STAGE_COMPLETED:
		failures.append("the Hall restoration quest should be available in a new slice session")
	if session.inventory.add_item(&"crop_beans") != OK or session.inventory.record_fish(&"anchovy", 45) != OK:
		failures.append("slice quest requirements should accept farm and fishing inventory")
	if coordinator.deliver_selected(&"fish_anchovy").has("error") or session.quests.stage_id(&"first_lantern") != &"light_lantern":
		failures.append("the explicit provision transaction should reach the lantern stage")
	var autosaves := [0]
	var result := coordinator.complete_lantern(func(): autosaves[0] += 1; return OK)
	if result.has("error"):
		failures.append("the supplied requirements should complete the first Hall restoration milestone")
	if not session.quests.unlocked_helpers.has(&"mabel") or not session.quests.hall_milestones.has(&"first_lantern"):
		failures.append("completion must unlock Mabel and Riverbend's access milestone")
	if not session.helpers.is_assigned(&"mabel") or not session.evidence.has(&"silas_first_lantern_note") or autosaves[0] != 1:
		failures.append("completion effects and autosave should occur exactly once")
	var snapshot := session.snapshot()
	var restored = GameSessionScript.new()
	if restored.restore(snapshot) != OK or not restored.quests.hall_milestones.has(&"first_lantern"):
		failures.append("progression state must survive save/load")
	session.free()
	restored.free()
	return failures
