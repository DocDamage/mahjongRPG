extends RefCounted

const QuestService = preload("res://src/quests/quest_service.gd")
const QuestEventAdapter = preload("res://src/quests/quest_event_adapter.gd")
const QuestJournalPresenter = preload("res://src/quests/quest_journal_presenter.gd")
const QUEST_PATH := "res://data/quests/vertical_slice_quests.json"
const DIALOGUE_PATH := "res://data/dialogue/vertical_slice_dialogue.json"
const ITEM_PATH := "res://data/items/vertical_slice_items.json"
const INTERACTION_IDS := [&"first_lantern.meet_mabel", &"first_lantern.lantern"]

var event_adapter = QuestEventAdapter.new()
var journal = QuestJournalPresenter.new()


func ensure_service(session):
	if session.quests == null:
		session.quests = _load_service()
	return session.quests


func bind(session) -> Error:
	var quests = ensure_service(session)
	var inventory = session._ensure_inventory()
	var result := event_adapter.bind(quests, inventory)
	if result == OK:
		journal.bind(quests)
	return result


func unbind() -> void:
	event_adapter.unbind()
	journal.unbind()


func _load_service():
	var service = QuestService.new()
	var file := FileAccess.open(QUEST_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	if not parsed is Dictionary:
		push_error("Invalid quest catalog: %s" % QUEST_PATH)
		return service
	var context := {"localization_keys": _localization_keys(), "interaction_ids": INTERACTION_IDS, "item_ids": _catalog_ids(ITEM_PATH, "items")}
	var quest_values: Variant = parsed.get("quests", [])
	if not quest_values is Array:
		push_error("Invalid quest catalog collection: %s $.quests" % QUEST_PATH)
		return service
	for index in quest_values.size():
		if not quest_values[index] is Dictionary or service.register_definition(quest_values[index], QUEST_PATH, context) != OK:
			for diagnostic in service.last_diagnostics:
				diagnostic["path"] = "$.quests[%d]%s" % [index, String(diagnostic.get("path", "$")).trim_prefix("$")]
				push_error("%s %s %s" % [diagnostic.get("source", QUEST_PATH), diagnostic.get("path", "$"), diagnostic.get("message", "invalid quest")])
	return service


func _localization_keys() -> Array:
	var file := FileAccess.open(DIALOGUE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	if not parsed is Dictionary:
		return []
	var locales_value: Variant = parsed.get("locales", {})
	var locale: Variant = locales_value.get(parsed.get("default_locale", "en"), {}) if locales_value is Dictionary else {}
	var lines: Variant = locale.get("lines", {}) if locale is Dictionary else {}
	return lines.keys() if lines is Dictionary else []


func _catalog_ids(path: String, collection_key: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	var values: Variant = parsed.get(collection_key, []) if parsed is Dictionary else []
	if values is Array:
		for value in values:
			if value is Dictionary and not StringName(value.get("id", "")).is_empty():
				ids.append(StringName(value["id"]))
	return ids
