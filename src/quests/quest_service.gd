extends RefCounted

signal quest_started(quest_id: StringName)
signal quest_progressed(quest_id: StringName, stage: int)
signal objective_progressed(quest_id: StringName, objective_id: StringName, current: int, target: int)
signal objective_completed(quest_id: StringName, objective_id: StringName)
signal quest_stage_changed(quest_id: StringName, stage_id: StringName)
signal quest_completed(quest_id: StringName)
signal projection_refreshed()

const QuestDefinitionValidator = preload("res://src/quests/quest_definition_validator.gd")
const QuestEvent = preload("res://src/quests/quest_event.gd")
const QuestObjectiveEvaluator = preload("res://src/quests/quest_objective_evaluator.gd")
const QuestProjection = preload("res://src/quests/quest_projection.gd")
const QuestStateValidator = preload("res://src/quests/quest_state_validator.gd")
const PROGRESSED := QuestEvent.SubmitResult.PROGRESSED
const STAGE_COMPLETED := QuestEvent.SubmitResult.STAGE_COMPLETED
const QUEST_COMPLETED := QuestEvent.SubmitResult.QUEST_COMPLETED
const ACCEPTED_NO_PROGRESS := QuestEvent.SubmitResult.ACCEPTED_NO_PROGRESS
const DUPLICATE := QuestEvent.SubmitResult.DUPLICATE
const REJECTED_INVALID := QuestEvent.SubmitResult.REJECTED_INVALID
const REJECTED_NOT_ACTIVE := QuestEvent.SubmitResult.REJECTED_NOT_ACTIVE
const REJECTED_OUT_OF_ORDER := QuestEvent.SubmitResult.REJECTED_OUT_OF_ORDER
const MAX_RUNTIME_DEDUPE_IDS := 128

var definitions: Dictionary = {}
var active: Dictionary = {}
var completed: Dictionary = {}
var progress: Dictionary = {}
var unlocked_helpers: Dictionary = {}
var hall_milestones: Dictionary = {}
var last_diagnostics: Array[Dictionary] = []
var _inventory_counts: Dictionary = {}
var _processed_event_ids: Dictionary = {}
var _authorized_delivery_ids: Dictionary = {}


func register_definition(data: Dictionary, source := "<memory>", context: Dictionary = {}) -> Error:
	last_diagnostics = QuestDefinitionValidator.validate(data, source, context)
	var quest_id := StringName(data.get("id", ""))
	if not last_diagnostics.is_empty() or definitions.has(quest_id):
		if definitions.has(quest_id):
			last_diagnostics.append({"source": source, "path": "$.id", "message": "duplicate quest ID"})
		return ERR_INVALID_DATA
	definitions[quest_id] = data.duplicate(true)
	return OK


func start(quest_id: StringName) -> Error:
	if not definitions.has(quest_id):
		return ERR_DOES_NOT_EXIST
	if completed.has(quest_id):
		return ERR_ALREADY_IN_USE
	active[quest_id] = true
	progress[quest_id] = 0
	quest_started.emit(quest_id)
	projection_refreshed.emit()
	return OK


func is_active(quest_id: StringName) -> bool:
	return active.has(quest_id)


func stage(quest_id: StringName) -> int:
	return int(progress.get(quest_id, 0))


func stage_id(quest_id: StringName) -> StringName:
	var stage_data := _stage_data(quest_id, stage(quest_id))
	return StringName(stage_data.get("id", ""))


func advance(quest_id: StringName) -> Error:
	if not active.has(quest_id):
		return ERR_INVALID_DATA
	if _stage_has_objectives(quest_id, stage(quest_id)):
		return ERR_UNAVAILABLE
	var next_stage := stage(quest_id) + 1
	if next_stage >= stage_count(quest_id):
		return ERR_UNAVAILABLE
	progress[quest_id] = next_stage
	quest_progressed.emit(quest_id, next_stage)
	projection_refreshed.emit()
	return OK


func stage_count(quest_id: StringName) -> int:
	var stages_value: Variant = definitions.get(quest_id, {}).get("stages", [])
	return maxi(1, stages_value.size() if stages_value is Array else 1)


func complete(quest_id: StringName) -> Error:
	if not active.has(quest_id) or not definitions.has(quest_id) or stage(quest_id) < stage_count(quest_id) - 1:
		return ERR_INVALID_DATA
	return _complete(quest_id)


func requirement_count(quest_id: StringName, inventory, item_id: StringName) -> int:
	if inventory == null or not definitions.has(quest_id):
		return 0
	if item_id == &"any_fish":
		var count := 0
		for key_value in inventory.items.keys():
			if String(key_value).begins_with("fish_"):
				count += int(inventory.items[key_value])
		return count
	return inventory.item_count(item_id)


func expects_objective(quest_id: StringName, objective_id: StringName) -> bool:
	if not active.has(quest_id):
		return false
	for objective_value in _current_objectives(quest_id):
		if objective_value is Dictionary and StringName(objective_value.get("id", "")) == objective_id:
			return true
	return false


func submit_event(event_value: Variant) -> int:
	var normalized := QuestEvent.normalize(event_value)
	if not normalized.has("event"):
		last_diagnostics = [normalized.get("diagnostic", {})]
		return REJECTED_INVALID
	var event: Dictionary = normalized["event"]
	if StringName(event["kind"]) == &"inventory.changed":
		return _apply_inventory_report(event["payload"])
	var event_id := StringName(event["event_id"])
	if StringName(event["kind"]) == &"inventory.delivered":
		if not _authorized_delivery_ids.has(event_id):
			return REJECTED_INVALID
		_authorized_delivery_ids.erase(event_id)
	if _processed_event_ids.has(event_id):
		return DUPLICATE
	var captured: Array[Dictionary] = []
	var active_ids: Array = active.keys()
	active_ids.sort_custom(func(a, b): return String(a) < String(b))
	for quest_value in active_ids:
		var quest_id := StringName(quest_value)
		var stage_data := _stage_data(quest_id, stage(quest_id))
		if QuestObjectiveEvaluator.event_matches_stage(stage_data, event):
			captured.append({"quest_id": quest_id, "stage": stage(quest_id), "stage_data": stage_data})
	if captured.is_empty():
		return _rejection_for_unmatched_event(event)
	var result := PROGRESSED
	for captured_value in captured:
		result = maxi(result, _apply_captured_event(captured_value, event))
	_remember_event(event_id)
	return result


func authorize_delivery_receipt(transaction_id: StringName) -> Error:
	if transaction_id.is_empty():
		return ERR_INVALID_PARAMETER
	_authorized_delivery_ids[transaction_id] = true
	return OK


func projection(quest_id: StringName) -> Dictionary:
	if not active.has(quest_id) or not definitions.has(quest_id):
		return {}
	var definition: Dictionary = definitions[quest_id]
	var stage_data := _stage_data(quest_id, stage(quest_id))
	var objectives := _current_objectives(quest_id)
	return QuestProjection.build(quest_id, definition, stage_data, objectives, _inventory_counts)


func projections() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ids: Array = active.keys()
	ids.sort_custom(func(a, b): return String(a) < String(b))
	for quest_value in ids:
		result.append(projection(StringName(quest_value)))
	return result


func snapshot() -> Dictionary:
	return {"active": active.duplicate(true), "completed": completed.duplicate(true), "progress": progress.duplicate(true), "unlocked_helpers": unlocked_helpers.duplicate(true), "hall_milestones": hall_milestones.duplicate(true)}


func restore(data: Dictionary) -> Error:
	var candidate := QuestStateValidator.validated_restore(self, data)
	if candidate.is_empty():
		return ERR_INVALID_DATA
	active = candidate["active"]
	completed = candidate["completed"]
	progress = candidate["progress"]
	unlocked_helpers = candidate["unlocked_helpers"]
	hall_milestones = candidate["hall_milestones"]
	_processed_event_ids.clear()
	_authorized_delivery_ids.clear()
	projection_refreshed.emit()
	return OK


func _apply_inventory_report(payload: Dictionary) -> int:
	var item_id := StringName(payload["item_id"])
	var current_count := int(payload["current_count"])
	if int(_inventory_counts.get(item_id, 0)) == current_count:
		return ACCEPTED_NO_PROGRESS
	if current_count == 0:
		_inventory_counts.erase(item_id)
	else:
		_inventory_counts[item_id] = current_count
	projection_refreshed.emit()
	return ACCEPTED_NO_PROGRESS


func _apply_captured_event(captured: Dictionary, event: Dictionary) -> int:
	var quest_id: StringName = captured["quest_id"]
	if not active.has(quest_id) or stage(quest_id) != int(captured["stage"]):
		return REJECTED_OUT_OF_ORDER
	var objectives: Array = captured["stage_data"].get("objectives", [])
	var matches := QuestObjectiveEvaluator.matching_objective_ids(objectives, event)
	for objective_id in matches:
		objective_progressed.emit(quest_id, objective_id, 1, 1)
		objective_completed.emit(quest_id, objective_id)
	if matches.size() < objectives.size():
		projection_refreshed.emit()
		return PROGRESSED
	if stage(quest_id) + 1 < stage_count(quest_id):
		progress[quest_id] = stage(quest_id) + 1
		quest_progressed.emit(quest_id, stage(quest_id))
		quest_stage_changed.emit(quest_id, stage_id(quest_id))
		projection_refreshed.emit()
		return STAGE_COMPLETED
	_complete(quest_id)
	return QUEST_COMPLETED


func _rejection_for_unmatched_event(event: Dictionary) -> int:
	var matched_inactive := false
	for quest_value in definitions:
		var quest_id := StringName(quest_value)
		var stages: Array = definitions[quest_id].get("stages", [])
		for index in stages.size():
			if stages[index] is Dictionary and QuestObjectiveEvaluator.event_matches_stage(stages[index], event):
				if active.has(quest_id):
					return REJECTED_OUT_OF_ORDER
				matched_inactive = true
	return REJECTED_NOT_ACTIVE if matched_inactive else ACCEPTED_NO_PROGRESS


func _complete(quest_id: StringName) -> Error:
	active.erase(quest_id)
	progress.erase(quest_id)
	completed[quest_id] = true
	var rewards_value: Variant = definitions[quest_id].get("rewards", {})
	if rewards_value is Dictionary:
		var helper := StringName(rewards_value.get("helper", ""))
		var milestone := StringName(rewards_value.get("hall_milestone", ""))
		if not helper.is_empty(): unlocked_helpers[helper] = true
		if not milestone.is_empty(): hall_milestones[milestone] = true
	quest_completed.emit(quest_id)
	projection_refreshed.emit()
	return OK


func _stage_data(quest_id: StringName, index: int) -> Dictionary:
	var stages_value: Variant = definitions.get(quest_id, {}).get("stages", [])
	return stages_value[index] if stages_value is Array and index >= 0 and index < stages_value.size() and stages_value[index] is Dictionary else {}


func _current_objectives(quest_id: StringName) -> Array:
	var value: Variant = _stage_data(quest_id, stage(quest_id)).get("objectives", [])
	return value if value is Array else []


func _stage_has_objectives(quest_id: StringName, index: int) -> bool:
	return _stage_data(quest_id, index).has("objectives")


func _remember_event(event_id: StringName) -> void:
	_processed_event_ids[event_id] = true
	if _processed_event_ids.size() > MAX_RUNTIME_DEDUPE_IDS:
		_processed_event_ids.erase(_processed_event_ids.keys()[0])
