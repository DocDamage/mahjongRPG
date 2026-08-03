extends RefCounted

const Validator = preload("res://src/quests/quest_definition_validator.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var valid := _definition()
	var context := {"localization_keys": [&"test.label"], "interaction_ids": [&"test.interaction"], "item_ids": []}
	if not Validator.validate(valid, "fixture.json", context).is_empty():
		failures.append("a supported schema-1 event_once definition should validate")
	var bad_schema := valid.duplicate(true)
	bad_schema["objective_schema"] = 2
	_assert_path(Validator.validate(bad_schema, "fixture.json", context), "$.objective_schema", "unknown objective schemas", failures)
	var bad_kind := valid.duplicate(true)
	bad_kind["stages"][0]["objectives"][0]["event_kind"] = "story.choice"
	_assert_path(Validator.validate(bad_kind, "fixture.json", context), "$.stages[0].objectives[0].event_kind", "reserved event kinds", failures)
	var observer_objective := valid.duplicate(true)
	observer_objective["stages"][0]["objectives"][0]["event_kind"] = "inventory.changed"
	observer_objective["stages"][0]["objectives"][0]["match"] = {"item_id": "crop_beans"}
	_assert_path(Validator.validate(observer_objective, "fixture.json", context), "$.stages[0].objectives[0].event_kind", "observer-only state reports as objectives", failures)
	var missing_text := valid.duplicate(true)
	missing_text["stages"][0]["objectives"][0]["label_key"] = "missing.label"
	_assert_path(Validator.validate(missing_text, "fixture.json", context), "$.stages[0].objectives[0].label_key", "missing localization keys", failures)
	var missing_target := valid.duplicate(true)
	missing_target["stages"][0]["objectives"][0]["match"]["interaction_id"] = "missing.interaction"
	_assert_path(Validator.validate(missing_target, "fixture.json", context), "$.stages[0].objectives[0].match.interaction_id", "missing interaction targets", failures)
	var command := valid.duplicate(true)
	command["stages"][0]["objectives"][0]["command"] = "award_everything"
	_assert_path(Validator.validate(command, "fixture.json", context), "$.stages[0].objectives[0].command", "content-authored commands", failures)
	var unknown_field := valid.duplicate(true)
	unknown_field["stages"][0]["mystery"] = true
	_assert_path(Validator.validate(unknown_field, "fixture.json", context), "$.stages[0].mystery", "unknown stage fields", failures)
	var bad_quantity := valid.duplicate(true)
	bad_quantity["requirements"]["crop_beans"] = -1
	_assert_path(Validator.validate(bad_quantity, "fixture.json", context), "$.requirements", "invalid requirement quantities", failures)
	var duplicate_stage := valid.duplicate(true)
	var second: Dictionary = duplicate_stage["stages"][0].duplicate(true)
	second["legacy_stage"] = 1
	second["objectives"][0]["id"] = "other_objective"
	duplicate_stage["stages"].append(second)
	_assert_path(Validator.validate(duplicate_stage, "fixture.json", context), "$.stages[1].id", "duplicate stage IDs", failures)
	var partial := valid.duplicate(true)
	partial["stages"][0]["objectives"].append(partial["stages"][0]["objectives"][0].duplicate(true))
	_assert_path(Validator.validate(partial, "fixture.json", context), "$.stages[0].objectives", "schema-21 partial objective state", failures)
	var legacy := {"id": "legacy", "requirements": {}, "stages": [{"id": "one"}]}
	if not Validator.validate(legacy).is_empty():
		failures.append("legacy quest definitions should remain valid through Q2")
	return failures


func _definition() -> Dictionary:
	return {"objective_schema": 1, "id": "test_quest", "definition_version": 1, "requirements": {}, "stages": [{"id": "stage_one", "legacy_stage": 0, "completion_mode": "all", "objectives": [{"id": "objective_one", "type": "event_once", "label_key": "test.label", "event_kind": "interaction.completed", "match": {"interaction_id": "test.interaction"}}]}]}


func _assert_path(diagnostics: Array[Dictionary], path: String, subject: String, failures: Array[String]) -> void:
	if not diagnostics.any(func(entry): return entry.get("path", "") == path and entry.get("source", "") == "fixture.json"):
		failures.append("validator should report %s at %s with its source" % [subject, path])
