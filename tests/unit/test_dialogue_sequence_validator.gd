extends RefCounted

const DialogueSequenceValidator = preload("res://src/dialogue/dialogue_sequence_validator.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var context := {
		"localization_keys": [&"bell.open", &"bell.close"],
		"speaker_ids": [&"mayor_bell"],
		"portrait_speaker_ids": [&"mayor_bell"],
		"portrait_expressions": [&"steady", &"warm"],
	}
	var valid := _sequence()
	if not DialogueSequenceValidator.validate(valid, "dialogue.json", context).is_empty():
		failures.append("a finite, fully referenced linear sequence should validate")
	_test_catalog_and_duplicate_ids(failures, valid, context)
	_test_missing_references(failures, valid, context)
	_test_graph_failures(failures, valid, context)
	_test_closed_schema(failures, valid, context)
	return failures


func _test_catalog_and_duplicate_ids(failures: Array[String], valid: Dictionary, context: Dictionary) -> void:
	var catalog := {"schema_version": 4, "sequences": [valid, valid.duplicate(true)]}
	var diagnostics: Array[Dictionary] = DialogueSequenceValidator.validate_catalog(catalog, "dialogue.json", context)
	if not _has_message(diagnostics, "duplicate sequence ID"):
		failures.append("dialogue catalogs must reject duplicate stable sequence IDs")
	var unsupported := catalog.duplicate(true)
	unsupported["schema_version"] = 99
	if not _has_message(DialogueSequenceValidator.validate_catalog(unsupported, "dialogue.json", context), "unsupported dialogue catalog schema"):
		failures.append("dialogue catalogs must fail closed on unsupported schema versions")


func _test_missing_references(failures: Array[String], valid: Dictionary, context: Dictionary) -> void:
	var missing_key := valid.duplicate(true)
	missing_key["nodes"][0]["text_key"] = "bell.missing"
	var diagnostics: Array[Dictionary] = DialogueSequenceValidator.validate(missing_key, "dialogue.json", context)
	if not _has_path(diagnostics, "$.nodes[0].text_key"):
		failures.append("missing localization keys must identify their JSON path")
	var bad_speaker := valid.duplicate(true)
	bad_speaker["nodes"][0]["speaker_id"] = "unknown"
	if not _has_message(DialogueSequenceValidator.validate(bad_speaker, "dialogue.json", context), "speaker does not exist"):
		failures.append("invalid dialogue speakers must fail validation")
	var missing_portrait := valid.duplicate(true)
	var portrait_context := context.duplicate(true)
	portrait_context["portrait_speaker_ids"] = [&"river_rose"]
	if not _has_message(DialogueSequenceValidator.validate(missing_portrait, "dialogue.json", portrait_context), "speaker portrait does not exist"):
		failures.append("speakers without an authored portrait must fail validation")
	var bad_portrait := valid.duplicate(true)
	bad_portrait["nodes"][0]["portrait_expression"] = "surprised"
	if not _has_message(DialogueSequenceValidator.validate(bad_portrait, "dialogue.json", context), "portrait expression is unsupported"):
		failures.append("unsupported portrait expressions must fail validation")


func _test_graph_failures(failures: Array[String], valid: Dictionary, context: Dictionary) -> void:
	var duplicate_node := valid.duplicate(true)
	duplicate_node["nodes"][1]["id"] = "opening"
	if not _has_message(DialogueSequenceValidator.validate(duplicate_node, "dialogue.json", context), "duplicate node ID"):
		failures.append("duplicate dialogue node IDs must fail validation")
	var unreachable := valid.duplicate(true)
	unreachable["nodes"][0]["next"] = ""
	if not _has_message(DialogueSequenceValidator.validate(unreachable, "dialogue.json", context), "unreachable node"):
		failures.append("unreachable dialogue nodes must fail validation")
	var cycle := valid.duplicate(true)
	cycle["nodes"][1]["next"] = "opening"
	if not _has_message(DialogueSequenceValidator.validate(cycle, "dialogue.json", context), "cycles are unsupported"):
		failures.append("linear dialogue cycles must fail validation")


func _test_closed_schema(failures: Array[String], valid: Dictionary, context: Dictionary) -> void:
	var command := valid.duplicate(true)
	command["nodes"][0]["command"] = "advance_arc"
	var diagnostics: Array[Dictionary] = DialogueSequenceValidator.validate(command, "dialogue.json", context)
	if not _has_path(diagnostics, "$.nodes[0].command"):
		failures.append("dialogue definitions must reject side-effect commands and unknown fields")


func _sequence() -> Dictionary:
	return {
		"schema_version": 1,
		"id": "mayor_bell.meet",
		"start_node": "opening",
		"nodes": [
			{"id": "opening", "speaker_id": "mayor_bell", "text_key": "bell.open", "portrait_expression": "steady", "next": "closing"},
			{"id": "closing", "speaker_id": "mayor_bell", "text_key": "bell.close", "portrait_expression": "warm", "next": ""},
		],
	}


func _has_message(diagnostics: Array[Dictionary], fragment: String) -> bool:
	for diagnostic in diagnostics:
		if fragment in String(diagnostic.get("message", "")):
			return true
	return false


func _has_path(diagnostics: Array[Dictionary], path: String) -> bool:
	for diagnostic in diagnostics:
		if String(diagnostic.get("path", "")) == path:
			return true
	return false
