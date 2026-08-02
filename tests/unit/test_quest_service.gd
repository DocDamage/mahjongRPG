extends RefCounted

const QuestService = preload("res://src/quests/quest_service.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var quests = QuestService.new()
	var definition := {"id": "first_lantern", "requirements": {"crop_beans": 1}, "stages": [{"id": "meet"}, {"id": "deliver"}, {"id": "restore"}], "rewards": {"helper": "mabel", "hall_milestone": "first_lantern"}}
	if quests.register_definition(definition) != OK or quests.start(&"first_lantern") != OK or quests.complete(&"first_lantern") != ERR_INVALID_DATA:
		failures.append("a staged quest should reject completion before its final stage")
	if quests.advance(&"first_lantern") != OK or quests.advance(&"first_lantern") != OK or quests.complete(&"first_lantern") != OK:
		failures.append("a defined staged quest should progress and complete")
	if not quests.unlocked_helpers.has(&"mabel") or not quests.hall_milestones.has(&"first_lantern"):
		failures.append("quest rewards should unlock helpers and hall milestones")
	var restored = QuestService.new()
	restored.register_definition(definition)
	if restored.restore(quests.snapshot()) != OK or restored.snapshot() != quests.snapshot():
		failures.append("quest state should round-trip through saves")
	var in_progress = QuestService.new()
	in_progress.register_definition(definition)
	in_progress.start(&"first_lantern")
	in_progress.advance(&"first_lantern")
	var staged_restore = QuestService.new()
	staged_restore.register_definition(definition)
	if staged_restore.restore(in_progress.snapshot()) != OK or staged_restore.stage(&"first_lantern") != 1:
		failures.append("active quest stages should round-trip through saves")
	var legacy_snapshot := in_progress.snapshot()
	legacy_snapshot.erase("progress")
	if staged_restore.restore(legacy_snapshot) != OK or staged_restore.stage(&"first_lantern") != 0:
		failures.append("pre-stage quest saves should safely start active quests at their first stage")
	return failures
