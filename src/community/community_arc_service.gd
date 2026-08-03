extends RefCounted

const DialogueCatalog = preload("res://src/dialogue/dialogue_catalog.gd")

signal arc_started(arc_id: StringName)
signal arc_progressed(arc_id: StringName, stage: int)
signal arc_completed(arc_id: StringName)
signal secret_discovered(secret_id: StringName)

var definitions: Dictionary = {}
var active: Dictionary = {}
var completed: Dictionary = {}
var progress: Dictionary = {}
var discovered_secrets: Dictionary = {}
var finale_support: Dictionary = {}


func register_definition(data: Dictionary) -> Error:

	var arc_id := StringName(data.get("id", ""))
	var stages_value: Variant = data.get("stages", [])
	var relationship_id := StringName(data.get("relationship_id", ""))
	var helper_id := StringName(data.get("helper_id", ""))
	if arc_id.is_empty() or relationship_id.is_empty() or helper_id.is_empty() or definitions.has(arc_id) or not stages_value is Array or stages_value.size() < 3:
		return ERR_INVALID_DATA
	for stage_value in stages_value:
		if not stage_value is Dictionary or StringName(stage_value.get("action", "")).is_empty():
			return ERR_INVALID_DATA
	definitions[arc_id] = data.duplicate(true)
	return OK


func begin(arc_id: StringName) -> Error:

	if not definitions.has(arc_id) or active.has(arc_id) or completed.has(arc_id):
		return ERR_UNAVAILABLE
	active[arc_id] = true
	progress[arc_id] = 0
	arc_started.emit(arc_id)
	return OK


func advance(arc_id: StringName, action_id: StringName, relationships, helpers) -> Dictionary:

	if not definitions.has(arc_id) or relationships == null or helpers == null:
		return {"error": ERR_INVALID_PARAMETER}
	if not active.has(arc_id) and begin(arc_id) != OK:
		return {"error": ERR_UNAVAILABLE}
	var definition: Dictionary = definitions[arc_id]
	var stage_index := int(progress.get(arc_id, 0))
	var stages: Array = definition["stages"]
	var stage_data: Dictionary = stages[stage_index]
	if StringName(stage_data.get("action", "")) != action_id:
		return {"error": ERR_UNAVAILABLE, "expected_action": StringName(stage_data.get("action", ""))}
	var choice_id := StringName("%s_%s" % [arc_id, action_id])
	var relationship_id := StringName(definition["relationship_id"])
	var relationship_result: int = relationships.record_choice(choice_id, relationship_id, int(stage_data.get("relationship_delta", 1)))
	if relationship_result != OK and relationship_result != ERR_ALREADY_IN_USE:
		return {"error": relationship_result}
	if stage_index + 1 < stages.size():
		progress[arc_id] = stage_index + 1
		arc_progressed.emit(arc_id, stage_index + 1)
		return {"arc_id": arc_id, "stage": stage_index + 1, "complete": false, "message": _stage_text(definition, action_id, stage_data)}
	active.erase(arc_id)
	progress.erase(arc_id)
	completed[arc_id] = true
	helpers.assign(StringName(definition["helper_id"]))
	arc_completed.emit(arc_id)
	_update_finale_support()
	return {"arc_id": arc_id, "stage": stages.size(), "complete": true, "helper_id": StringName(definition["helper_id"]), "message": _stage_text(definition, action_id, stage_data)}


func expected_action(arc_id: StringName) -> StringName:

	if not definitions.has(arc_id) or completed.has(arc_id):
		return &""
	var stages: Array = definitions[arc_id]["stages"]
	return StringName(stages[int(progress.get(arc_id, 0))].get("action", ""))


func expected_dialogue_sequence(arc_id: StringName) -> StringName:
	if not definitions.has(arc_id) or completed.has(arc_id):
		return &""
	var stages: Array = definitions[arc_id]["stages"]
	return StringName(stages[int(progress.get(arc_id, 0))].get("dialogue_sequence_id", ""))


func stage_label(arc_id: StringName) -> String:

	if completed.has(arc_id):
		return "resolved"
	if not definitions.has(arc_id):
		return "unavailable"
	var stage_data: Dictionary = definitions[arc_id]["stages"][int(progress.get(arc_id, 0))]
	return String(stage_data.get("label", stage_data.get("action", "continue")))


func is_completed(arc_id: StringName) -> bool:

	return completed.has(arc_id)


func discover_secret(arc_id: StringName) -> Error:

	if not definitions.has(arc_id) or not completed.has(arc_id):
		return ERR_UNAVAILABLE
	var secret_id := StringName(definitions[arc_id].get("secret_id", ""))
	if secret_id.is_empty() or discovered_secrets.has(secret_id):
		return ERR_ALREADY_IN_USE
	discovered_secrets[secret_id] = true
	secret_discovered.emit(secret_id)
	return OK


func home_scene(arc_id: StringName) -> String:

	return String(definitions.get(arc_id, {}).get("home_scene", ""))


func residents_for_region(region_id: StringName) -> Array[StringName]:

	var residents: Array[StringName] = []
	for arc_id_value in definitions:
		var arc_id := StringName(arc_id_value)
		if StringName(definitions[arc_id].get("region_id", "")) == region_id:
			residents.append(arc_id)
	residents.sort()
	return residents


func snapshot() -> Dictionary:

	return {"active": active.duplicate(true), "completed": completed.duplicate(true), "progress": progress.duplicate(true), "discovered_secrets": discovered_secrets.duplicate(true), "finale_support": finale_support.duplicate(true)}


func restore(data: Dictionary) -> Error:

	for key in ["active", "completed", "progress", "discovered_secrets", "finale_support"]:
		if not data.get(key, {}) is Dictionary:
			return ERR_INVALID_DATA
	for arc_id_value in data["active"]:
		var arc_id := StringName(arc_id_value)
		if not definitions.has(arc_id) or data["completed"].has(arc_id) or not data["progress"].has(arc_id):
			return ERR_INVALID_DATA
		var stage := int(data["progress"][arc_id_value])
		if stage < 0 or stage >= (definitions[arc_id]["stages"] as Array).size():
			return ERR_INVALID_DATA
	for arc_id_value in data["completed"]:
		if not definitions.has(StringName(arc_id_value)):
			return ERR_INVALID_DATA
	for secret_id_value in data["discovered_secrets"]:
		if not _known_secret(StringName(secret_id_value)):
			return ERR_INVALID_DATA
	active = data["active"].duplicate(true)
	completed = data["completed"].duplicate(true)
	progress = data["progress"].duplicate(true)
	discovered_secrets = data["discovered_secrets"].duplicate(true)
	finale_support = data["finale_support"].duplicate(true)
	_update_finale_support()
	return OK


func _known_secret(secret_id: StringName) -> bool:

	for definition_value in definitions.values():
		if StringName(definition_value.get("secret_id", "")) == secret_id:
			return true
	return false


func _stage_text(definition: Dictionary, action_id: StringName, stage_data: Dictionary) -> String:
	var arc_id := String(definition.get("id", ""))
	var localized := DialogueCatalog.text(StringName("community.%s.%s" % [arc_id, action_id])) if not arc_id.is_empty() else ""
	return localized if not localized.is_empty() else String(stage_data.get("text", "They appreciate your help."))


func _update_finale_support() -> void:

	if definitions.size() == 10 and completed.size() == definitions.size():
		finale_support[&"community_allies_ready"] = true
