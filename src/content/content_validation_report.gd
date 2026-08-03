extends RefCounted

const QuestDefinitionValidator = preload("res://src/quests/quest_definition_validator.gd")
const DialogueSequenceValidator = preload("res://src/dialogue/dialogue_sequence_validator.gd")
const CURRENT_SAVE_SCHEMA := 21
const REVIEW_LINES := 250
const MAX_LINES := 300
const CATALOG_PATHS := {
	"quests": "res://data/quests/vertical_slice_quests.json",
	"dialogue": "res://data/dialogue/vertical_slice_dialogue.json",
	"community": "res://data/community/community_arcs.json",
	"items": "res://data/items/vertical_slice_items.json",
	"runtime_assets": "res://data/runtime_assets/vertical_slice_assets.json",
}
const CATALOG_SCHEMAS := {"quests": 2, "dialogue": 4, "community": 1, "items": 4, "runtime_assets": 2}


static func validate_repository() -> Dictionary:
	var report := validate_catalogs(load_catalogs())
	var lengths := _collect_gdscript_lengths()
	var length_report := validate_source_lengths(lengths)
	report["errors"].append_array(length_report["errors"])
	report["warnings"].append_array(length_report["warnings"])
	report["source_lengths"] = lengths
	report["summary"] = "%d error(s), %d warning(s), %d GDScript file(s) checked" % [report["errors"].size(), report["warnings"].size(), lengths.size()]
	return report


static func load_catalogs() -> Dictionary:
	var catalogs: Dictionary = {}
	for catalog_id in CATALOG_PATHS:
		catalogs[catalog_id] = _load_json(CATALOG_PATHS[catalog_id])
	return catalogs


static func validate_catalogs(catalogs: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var malformed_catalog := false
	for catalog_id in CATALOG_PATHS:
		if not catalogs.get(catalog_id) is Dictionary or catalogs[catalog_id].is_empty():
			errors.append("%s $ catalog is missing or malformed" % CATALOG_PATHS[catalog_id])
			malformed_catalog = true
		elif int(catalogs[catalog_id].get("schema_version", -1)) != int(CATALOG_SCHEMAS[catalog_id]):
			errors.append("%s $.schema_version unsupported %s catalog schema; expected %d" % [CATALOG_PATHS[catalog_id], String(catalog_id).trim_suffix("s"), CATALOG_SCHEMAS[catalog_id]])
	if malformed_catalog:
		return {"errors": errors, "warnings": warnings, "source_lengths": {}, "summary": "%d malformed catalog(s)" % errors.size()}
	var quests: Dictionary = catalogs["quests"]
	var dialogue: Dictionary = catalogs["dialogue"]
	var community: Dictionary = catalogs["community"]
	var items: Dictionary = catalogs["items"]
	var runtime_assets: Dictionary = catalogs["runtime_assets"]
	var localization_keys := _localization_keys(dialogue)
	var community_ids := _collection_ids(community.get("arcs", []), CATALOG_PATHS["community"], "$.arcs", errors)
	var item_ids := _collection_ids(items.get("items", []), CATALOG_PATHS["items"], "$.items", errors)
	var portrait_data: Variant = runtime_assets.get("portraits", {})
	var portrait_expressions: Variant = portrait_data.get("expressions", []) if portrait_data is Dictionary else []
	var portrait_speaker_ids: Variant = portrait_data.get("residents", []) if portrait_data is Dictionary else []
	var quest_context := {
		"localization_keys": localization_keys,
		"interaction_ids": [&"first_lantern.meet_mabel", &"first_lantern.lantern"],
		"item_ids": item_ids,
		"save_schema": CURRENT_SAVE_SCHEMA,
	}
	var quest_values: Variant = quests.get("quests", [])
	if not quest_values is Array:
		errors.append("%s $.quests quests must be an array" % CATALOG_PATHS["quests"])
	else:
		_collection_ids(quest_values, CATALOG_PATHS["quests"], "$.quests", errors)
		for index in quest_values.size():
			_append_diagnostics(errors, QuestDefinitionValidator.validate(quest_values[index], CATALOG_PATHS["quests"], quest_context), "$.quests[%d]" % index)
	var dialogue_context := {
		"localization_keys": localization_keys,
		"speaker_ids": community_ids,
		"portrait_speaker_ids": portrait_speaker_ids,
		"portrait_expressions": portrait_expressions,
	}
	_append_diagnostics(errors, DialogueSequenceValidator.validate_catalog(dialogue, CATALOG_PATHS["dialogue"], dialogue_context))
	_validate_community_sequences(community, dialogue, errors)
	return {"errors": errors, "warnings": warnings, "source_lengths": {}, "summary": "%d error(s), %d warning(s)" % [errors.size(), warnings.size()]}


static func validate_source_lengths(lengths: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var paths: Array = lengths.keys()
	paths.sort()
	for path_value in paths:
		var path := String(path_value)
		var lines := int(lengths[path_value])
		if lines > MAX_LINES:
			errors.append("%s exceeds the %d-line handwritten GDScript maximum (%d)" % [path, MAX_LINES, lines])
		elif lines >= REVIEW_LINES:
			warnings.append("%s is at the %d-line review threshold (%d)" % [path, REVIEW_LINES, lines])
	return {"errors": errors, "warnings": warnings}


static func format_report(report: Dictionary) -> String:
	var lines: Array[String] = ["Content validation report", "========================="]
	for error in report.get("errors", []):
		lines.append("ERROR: %s" % error)
	for warning in report.get("warnings", []):
		lines.append("WARNING: %s" % warning)
	lines.append(String(report.get("summary", "validation complete")))
	return "\n".join(lines)


static func _validate_community_sequences(community: Dictionary, dialogue: Dictionary, errors: Array[String]) -> void:
	var sequence_ids: Dictionary = {}
	for sequence_value in dialogue.get("sequences", []):
		if sequence_value is Dictionary:
			sequence_ids[StringName(sequence_value.get("id", ""))] = true
	var arcs_value: Variant = community.get("arcs", [])
	if not arcs_value is Array:
		errors.append("%s $.arcs arcs must be an array" % CATALOG_PATHS["community"])
		return
	for arc_index in arcs_value.size():
		var arc_value: Variant = arcs_value[arc_index]
		if not arc_value is Dictionary:
			continue
		var stages_value: Variant = arc_value.get("stages", [])
		if not stages_value is Array:
			continue
		for stage_index in stages_value.size():
			var stage_value: Variant = stages_value[stage_index]
			if not stage_value is Dictionary:
				continue
			var sequence_id := StringName(stage_value.get("dialogue_sequence_id", ""))
			if not sequence_id.is_empty() and not sequence_ids.has(sequence_id):
				errors.append("%s $.arcs[%d].stages[%d].dialogue_sequence_id dialogue sequence does not exist" % [CATALOG_PATHS["community"], arc_index, stage_index])


static func _append_diagnostics(errors: Array[String], diagnostics: Array[Dictionary], prefix := "") -> void:
	for diagnostic in diagnostics:
		var path := String(diagnostic.get("path", "$"))
		if not prefix.is_empty():
			path = "%s%s" % [prefix, path.trim_prefix("$")]
		errors.append("%s %s %s" % [diagnostic.get("source", "<memory>"), path, diagnostic.get("message", "invalid content")])


static func _collection_ids(values: Variant, source: String, path: String, errors: Array[String]) -> Array[StringName]:
	var ids: Array[StringName] = []
	var seen: Dictionary = {}
	if not values is Array:
		errors.append("%s %s collection must be an array" % [source, path])
		return ids
	for index in values.size():
		var value: Variant = values[index]
		var item_id := StringName(value.get("id", "")) if value is Dictionary else &""
		if item_id.is_empty():
			errors.append("%s %s[%d].id stable ID is required" % [source, path, index])
		elif seen.has(item_id):
			errors.append("%s %s[%d].id duplicate ID: %s" % [source, path, index, item_id])
		else:
			seen[item_id] = true
			ids.append(item_id)
	return ids


static func _localization_keys(dialogue: Dictionary) -> Array:
	var locales_value: Variant = dialogue.get("locales", {})
	var locale: Variant = locales_value.get(dialogue.get("default_locale", "en"), {}) if locales_value is Dictionary else {}
	var lines: Variant = locale.get("lines", {}) if locale is Dictionary else {}
	return lines.keys() if lines is Dictionary else []


static func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


static func _collect_gdscript_lengths() -> Dictionary:
	var lengths: Dictionary = {}
	for root in ["res://src", "res://tests", "res://tools"]:
		_collect_directory(root, lengths)
	return lengths


static func _collect_directory(path: String, lengths: Dictionary) -> void:
	for file_name in DirAccess.get_files_at(path):
		if not file_name.ends_with(".gd"):
			continue
		var file := FileAccess.open("%s/%s" % [path, file_name], FileAccess.READ)
		if file != null:
			var contents := file.get_as_text()
			var line_count := contents.split("\n").size() - (1 if contents.ends_with("\n") else 0)
			lengths["%s/%s" % [path.trim_prefix("res://"), file_name]] = line_count
	for directory_name in DirAccess.get_directories_at(path):
		_collect_directory("%s/%s" % [path, directory_name], lengths)
