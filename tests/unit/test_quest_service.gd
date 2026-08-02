extends RefCounted

const QuestService = preload("res://src/quests/quest_service.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var quests = QuestService.new()
	var definition := {"id": "first_lantern", "requirements": {"crop_beans": 1}, "rewards": {"helper": "mabel", "hall_milestone": "first_lantern"}}
	if quests.register_definition(definition) != OK or quests.start(&"first_lantern") != OK or quests.complete(&"first_lantern") != OK:
		failures.append("a defined quest should start and complete")
	if not quests.unlocked_helpers.has(&"mabel") or not quests.hall_milestones.has(&"first_lantern"):
		failures.append("quest rewards should unlock helpers and hall milestones")
	var restored = QuestService.new()
	restored.register_definition(definition)
	if restored.restore(quests.snapshot()) != OK or restored.snapshot() != quests.snapshot():
		failures.append("quest state should round-trip through saves")
	return failures
