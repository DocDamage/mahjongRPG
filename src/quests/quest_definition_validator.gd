extends RefCounted

const QuestEvent = preload("res://src/quests/quest_event.gd")
const FORBIDDEN_KEYS := ["callable", "command", "expression", "node_path", "script", "script_path"]
const OBJECTIVE_DEFINITION_KEYS := ["objective_schema", "id", "definition_version", "required_save_schema", "title", "title_key", "requirements", "stages", "rewards"]
const STAGE_KEYS := ["id", "legacy_stage", "completion_mode", "objectives", "dialogue_id"]
const OBJECTIVE_KEYS := ["id", "type", "label_key", "event_kind", "match"]
const OBJECTIVE_EVENT_KINDS := [&"interaction.completed", &"inventory.delivered"]
const MATCH_FIELDS := {
	&"interaction.completed": ["interaction_id"],
	&"inventory.delivered": ["delivery_id"],
	&"inventory.changed": ["item_id", "reason"],
}


static func validate(definition_value: Variant, source := "<memory>", context: Dictionary = {}) -> Array[Dictionary]:
	var diagnostics: Array[Dictionary] = []
	if not definition_value is Dictionary:
		_add(diagnostics, source, "$", "quest definition must be a dictionary")
		return diagnostics
	var definition: Dictionary = definition_value
	_check_forbidden(definition, source, "$", diagnostics)
	var quest_id := String(definition.get("id", ""))
	if not QuestEvent._valid_id(quest_id):
		_add(diagnostics, source, "$.id", "quest ID must be a stable ID")
	var requirements_value: Variant = definition.get("requirements", {})
	var stages_value: Variant = definition.get("stages", [])
	if not requirements_value is Dictionary:
		_add(diagnostics, source, "$.requirements", "requirements must be a dictionary")
	elif not _valid_requirements(requirements_value):
		_add(diagnostics, source, "$.requirements", "requirement IDs must be stable and quantities must be positive integers")
	if not stages_value is Array or stages_value.is_empty():
		_add(diagnostics, source, "$.stages", "quest must contain at least one stage")
		return diagnostics
	var objective_schema := int(definition.get("objective_schema", 0))
	var has_objectives := false
	for stage_value in stages_value:
		if stage_value is Dictionary and stage_value.has("objectives"):
			has_objectives = true
	if not has_objectives:
		_validate_legacy_stages(stages_value, source, diagnostics)
		return diagnostics
	_check_unknown(definition, OBJECTIVE_DEFINITION_KEYS, source, "$", diagnostics)
	if objective_schema != 1:
		_add(diagnostics, source, "$.objective_schema", "objective definitions require objective_schema 1")
	if int(definition.get("definition_version", 0)) < 1:
		_add(diagnostics, source, "$.definition_version", "objective definitions require a positive definition version")
	if definition.has("title_key"):
		var title_key := String(definition.get("title_key", ""))
		if not QuestEvent._valid_id(title_key) or not _reference_exists(title_key, context.get("localization_keys", [])):
			_add(diagnostics, source, "$.title_key", "quest title localization key does not exist")
	if definition.has("required_save_schema"):
		var required_save_value: Variant = definition["required_save_schema"]
		if not _is_integer_number(required_save_value) or int(required_save_value) <= 0:
			_add(diagnostics, source, "$.required_save_schema", "required save schema must be a positive integer")
		elif int(required_save_value) > int(context.get("save_schema", required_save_value)):
			_add(diagnostics, source, "$.required_save_schema", "quest requires save schema %d, newer than the current schema" % int(required_save_value))
	if requirements_value is Dictionary:
		for item_value in requirements_value:
			if String(item_value) != "any_fish" and not _reference_exists(String(item_value), context.get("item_ids", [])):
				_add(diagnostics, source, "$.requirements.%s" % item_value, "item target does not exist")
	_validate_objective_stages(stages_value, source, context, diagnostics)
	return diagnostics


static func _validate_legacy_stages(stages: Array, source: String, diagnostics: Array[Dictionary]) -> void:
	var ids: Dictionary = {}
	for index in stages.size():
		var stage_value: Variant = stages[index]
		var path := "$.stages[%d]" % index
		if not stage_value is Dictionary:
			_add(diagnostics, source, path, "stage must be a dictionary")
			continue
		var stage_id := String(stage_value.get("id", ""))
		if not QuestEvent._valid_id(stage_id):
			_add(diagnostics, source, path + ".id", "stage ID must be a stable ID")
		elif ids.has(stage_id):
			_add(diagnostics, source, path + ".id", "duplicate stage ID")
		ids[stage_id] = true


static func _validate_objective_stages(stages: Array, source: String, context: Dictionary, diagnostics: Array[Dictionary]) -> void:
	var stage_ids: Dictionary = {}
	var legacy_stages: Dictionary = {}
	var objective_ids: Dictionary = {}
	for index in stages.size():
		var stage_value: Variant = stages[index]
		var path := "$.stages[%d]" % index
		if not stage_value is Dictionary:
			_add(diagnostics, source, path, "stage must be a dictionary")
			continue
		var stage: Dictionary = stage_value
		_check_unknown(stage, STAGE_KEYS, source, path, diagnostics)
		var stage_id := String(stage.get("id", ""))
		if not QuestEvent._valid_id(stage_id):
			_add(diagnostics, source, path + ".id", "stage ID must be a stable ID")
		elif stage_ids.has(stage_id):
			_add(diagnostics, source, path + ".id", "duplicate stage ID")
		stage_ids[stage_id] = true
		if not _is_integer_number(stage.get("legacy_stage")) or int(stage.get("legacy_stage", -1)) != index:
			_add(diagnostics, source, path + ".legacy_stage", "legacy stage must uniquely match its numeric index")
		elif legacy_stages.has(index):
			_add(diagnostics, source, path + ".legacy_stage", "duplicate legacy stage")
		legacy_stages[index] = true
		if String(stage.get("completion_mode", "")) != "all":
			_add(diagnostics, source, path + ".completion_mode", "Q1 supports completion_mode 'all' only")
		var objectives_value: Variant = stage.get("objectives", [])
		if not objectives_value is Array or objectives_value.size() != 1:
			_add(diagnostics, source, path + ".objectives", "schema 21 requires exactly one irreversible objective per stage")
			continue
		_validate_objective(objectives_value[0], source, path + ".objectives[0]", context, objective_ids, diagnostics)


static func _validate_objective(value: Variant, source: String, path: String, context: Dictionary, ids: Dictionary, diagnostics: Array[Dictionary]) -> void:
	if not value is Dictionary:
		_add(diagnostics, source, path, "objective must be a dictionary")
		return
	var objective: Dictionary = value
	_check_unknown(objective, OBJECTIVE_KEYS, source, path, diagnostics)
	var objective_id := String(objective.get("id", ""))
	if not QuestEvent._valid_id(objective_id):
		_add(diagnostics, source, path + ".id", "objective ID must be a stable ID")
	elif ids.has(objective_id):
		_add(diagnostics, source, path + ".id", "duplicate objective ID")
	ids[objective_id] = true
	if StringName(objective.get("type", "")) != &"event_once":
		_add(diagnostics, source, path + ".type", "Q1 supports objective type 'event_once' only")
	var event_kind := StringName(objective.get("event_kind", ""))
	if not QuestEvent.ENABLED_KINDS.has(event_kind) or not OBJECTIVE_EVENT_KINDS.has(event_kind):
		_add(diagnostics, source, path + ".event_kind", "event kind is unknown, reserved, or observer-only")
	var label_key := String(objective.get("label_key", ""))
	if not QuestEvent._valid_id(label_key):
		_add(diagnostics, source, path + ".label_key", "label key must be a stable localization ID")
	elif not _reference_exists(label_key, context.get("localization_keys", [])):
		_add(diagnostics, source, path + ".label_key", "localization key does not exist")
	var match_value: Variant = objective.get("match", {})
	if not match_value is Dictionary or match_value.is_empty():
		_add(diagnostics, source, path + ".match", "event match must be a non-empty dictionary")
		return
	var allowed: Array = MATCH_FIELDS.get(event_kind, [])
	_check_unknown(match_value, allowed, source, path + ".match", diagnostics)
	if match_value.size() != 1:
		_add(diagnostics, source, path + ".match", "enabled event_once objectives require exactly one match field")
	for key_value in match_value:
		var target := String(match_value[key_value])
		if not QuestEvent._valid_id(target):
			_add(diagnostics, source, "%s.match.%s" % [path, key_value], "match target must be a stable ID")
		elif String(key_value) == "interaction_id" and not _reference_exists(target, context.get("interaction_ids", [])):
			_add(diagnostics, source, "%s.match.%s" % [path, key_value], "interaction target does not exist")


static func _valid_requirements(requirements: Dictionary) -> bool:
	for key_value in requirements:
		if not QuestEvent._valid_id(String(key_value)) or not _is_integer_number(requirements[key_value]) or int(requirements[key_value]) <= 0:
			return false
	return true


static func _is_integer_number(value: Variant) -> bool:
	return value is int or value is float and is_equal_approx(value, roundf(value))


static func _reference_exists(value: String, references: Variant) -> bool:
	if references is Array and not references.is_empty():
		return references.has(value) or references.has(StringName(value))
	if references is Dictionary and not references.is_empty():
		return references.has(value) or references.has(StringName(value))
	return true


static func _check_unknown(value: Dictionary, allowed: Array, source: String, path: String, diagnostics: Array[Dictionary]) -> void:
	for key_value in value:
		if not allowed.has(String(key_value)):
			_add(diagnostics, source, "%s.%s" % [path, key_value], "unknown definition field")


static func _check_forbidden(value: Variant, source: String, path: String, diagnostics: Array[Dictionary]) -> void:
	if value is Dictionary:
		for key_value in value:
			var child_path := "%s.%s" % [path, key_value]
			if FORBIDDEN_KEYS.has(String(key_value).to_lower()):
				_add(diagnostics, source, child_path, "runtime command data is prohibited")
			_check_forbidden(value[key_value], source, child_path, diagnostics)
	elif value is Array:
		for index in value.size():
			_check_forbidden(value[index], source, "%s[%d]" % [path, index], diagnostics)


static func _add(diagnostics: Array[Dictionary], source: String, path: String, message: String) -> void:
	diagnostics.append({"source": source, "path": path, "message": message})
