extends RefCounted

const QuestService = preload("res://src/quests/quest_service.gd")
const QuestEvent = preload("res://src/quests/quest_event.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_legacy_compatibility(failures)
	_test_objective_events(failures)
	_test_restore_atomicity(failures)
	_test_schema_21_fixtures(failures)
	return failures


func _test_legacy_compatibility(failures: Array[String]) -> void:
	var quests = QuestService.new()
	var definition := _legacy_definition()
	if quests.register_definition(definition) != OK or quests.start(&"legacy_quest") != OK or quests.complete(&"legacy_quest") != ERR_INVALID_DATA:
		failures.append("a legacy staged quest should reject completion before its final stage")
	quests.advance(&"legacy_quest")
	quests.start(&"legacy_quest")
	if quests.stage(&"legacy_quest") != 0:
		failures.append("duplicate legacy start should preserve the characterized stage reset behavior")
	if quests.advance(&"legacy_quest") != OK or quests.advance(&"legacy_quest") != OK or quests.complete(&"legacy_quest") != OK:
		failures.append("legacy manual stage progression should remain compatible")
	if quests.complete(&"legacy_quest") != ERR_INVALID_DATA or not quests.unlocked_helpers.has(&"mabel") or not quests.hall_milestones.has(&"first_lantern"):
		failures.append("legacy completion and rewards should be idempotent")


func _test_objective_events(failures: Array[String]) -> void:
	var quests = QuestService.new()
	if quests.register_definition(_objective_definition()) != OK:
		failures.append("a valid objective quest should register")
		return
	var intro := QuestEvent.make_interaction(&"test.intro", &"test_source", &"event.intro")
	if quests.submit_event(intro) != quests.REJECTED_NOT_ACTIVE:
		failures.append("events before quest start should not progress")
	quests.start(&"objective_quest")
	if quests.advance(&"objective_quest") != ERR_UNAVAILABLE:
		failures.append("manual advance should reject event-owned stages")
	var early := QuestEvent.make_interaction(&"test.lantern", &"test_source", &"event.early")
	if quests.submit_event(early) != quests.REJECTED_OUT_OF_ORDER:
		failures.append("an event for a later stage should be rejected out of order")
	if quests.submit_event(intro) != quests.STAGE_COMPLETED or quests.stage(&"objective_quest") != 1:
		failures.append("a matching event_once objective should complete one stage")
	if quests.submit_event(intro) != quests.DUPLICATE or quests.stage(&"objective_quest") != 1:
		failures.append("a duplicate event ID should not count twice or cascade")
	var report := QuestEvent.make_inventory_report(&"crop_beans", 0, 3, &"test_sync")
	quests.submit_event(report)
	quests.submit_event(QuestEvent.make_inventory_report(&"crop_beans", 99, 2, &"test_sync"))
	if int(quests.projection(&"objective_quest")["live_counts"].get(&"crop_beans", 0)) != 2:
		failures.append("inventory state reports should replace rather than increment projection counts")
	var delivery := QuestEvent.make_delivery(&"test.provisions", &"test_source", {"transaction_id": &"inventory.tx.1", "items": [{"item_id": &"crop_beans", "quantity": 1}]})
	if quests.submit_event(delivery) != quests.REJECTED_INVALID or quests.stage(&"objective_quest") != 1:
		failures.append("a delivery event without an authenticated inventory receipt should not progress")
	quests.authorize_delivery_receipt(&"inventory.tx.1")
	if quests.submit_event(delivery) != quests.STAGE_COMPLETED or quests.stage(&"objective_quest") != 2:
		failures.append("a matching delivery should complete only the captured stage")
	var lantern := QuestEvent.make_interaction(&"test.lantern", &"test_source", &"event.lantern")
	if quests.submit_event(lantern) != quests.QUEST_COMPLETED or not quests.completed.has(&"objective_quest"):
		failures.append("the final objective event should complete the quest exactly once")
	if quests.submit_event(lantern) != quests.DUPLICATE:
		failures.append("a repeated final event should be deduplicated while its runtime record exists")
	if quests.submit_event(QuestEvent.make_interaction(&"test.lantern", &"test_source", &"event.lantern.again")) != quests.REJECTED_NOT_ACTIVE:
		failures.append("a new matching event after quest completion should be rejected as inactive")
	var invalid_service = QuestService.new()
	var invalid_definition := _objective_definition()
	invalid_definition["stages"][0]["objectives"][0]["type"] = "event_count"
	if invalid_service.register_definition(invalid_definition) != ERR_INVALID_DATA or not invalid_service.definitions.is_empty():
		failures.append("invalid objective content must not leave a partially registered playable quest")


func _test_restore_atomicity(failures: Array[String]) -> void:
	var quests = QuestService.new()
	quests.register_definition(_objective_definition())
	quests.start(&"objective_quest")
	var before := quests.snapshot()
	var invalid := before.duplicate(true)
	invalid["progress"]["objective_quest"] = 99
	if quests.restore(invalid) != ERR_INVALID_DATA or quests.snapshot() != before:
		failures.append("a rejected quest restore must leave prior state byte-for-byte equivalent")
	var progressed_signals := [0]
	var completion_signals := [0]
	var projection_signals := [0]
	quests.quest_progressed.connect(func(_id, _stage): progressed_signals[0] += 1)
	quests.quest_completed.connect(func(_id): completion_signals[0] += 1)
	quests.projection_refreshed.connect(func(): projection_signals[0] += 1)
	if quests.restore(before) != OK or progressed_signals[0] != 0 or completion_signals[0] != 0 or projection_signals[0] != 1:
		failures.append("restore should suppress progression/completion signals and emit one projection refresh")


func _test_schema_21_fixtures(failures: Array[String]) -> void:
	var expected := {"first_lantern_stage_0.json": 0, "first_lantern_stage_1.json": 1, "first_lantern_stage_2.json": 2}
	for filename in expected:
		var fixture := _fixture(filename)
		var service = QuestService.new()
		service.register_definition(_first_lantern_definition())
		if service.restore(fixture.get("quests", {})) != OK or service.stage(&"first_lantern") != expected[filename] or service.stage_id(&"first_lantern").is_empty():
			failures.append("schema-21 fixture %s should map to its equivalent stable stage" % filename)
	var completed_service = QuestService.new()
	completed_service.register_definition(_first_lantern_definition())
	if completed_service.restore(_fixture("first_lantern_completed.json").get("quests", {})) != OK or not completed_service.completed.has(&"first_lantern"):
		failures.append("the completed schema-21 First Lantern fixture should restore without replay")


func _legacy_definition() -> Dictionary:
	return {"id": "legacy_quest", "requirements": {"crop_beans": 1}, "stages": [{"id": "meet"}, {"id": "deliver"}, {"id": "restore"}], "rewards": {"helper": "mabel", "hall_milestone": "first_lantern"}}


func _objective_definition() -> Dictionary:
	return {"objective_schema": 1, "id": "objective_quest", "definition_version": 1, "title": "Objective test", "requirements": {"crop_beans": 1}, "stages": [
		{"id": "intro", "legacy_stage": 0, "completion_mode": "all", "objectives": [{"id": "intro", "type": "event_once", "label_key": "test.intro", "event_kind": "interaction.completed", "match": {"interaction_id": "test.intro"}}]},
		{"id": "delivery", "legacy_stage": 1, "completion_mode": "all", "objectives": [{"id": "delivery", "type": "event_once", "label_key": "test.delivery", "event_kind": "inventory.delivered", "match": {"delivery_id": "test.provisions"}}]},
		{"id": "lantern", "legacy_stage": 2, "completion_mode": "all", "objectives": [{"id": "lantern", "type": "event_once", "label_key": "test.lantern", "event_kind": "interaction.completed", "match": {"interaction_id": "test.lantern"}}]},
	]}


func _first_lantern_definition() -> Dictionary:
	var file := FileAccess.open("res://data/quests/vertical_slice_quests.json", FileAccess.READ)
	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	return parsed["quests"][0]


func _fixture(filename: String) -> Dictionary:
	var file := FileAccess.open("res://tests/fixtures/schema21/%s" % filename, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	return parsed if parsed is Dictionary else {}
