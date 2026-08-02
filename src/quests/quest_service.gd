extends RefCounted

signal quest_started(quest_id: StringName)
signal quest_progressed(quest_id: StringName, stage: int)
signal quest_completed(quest_id: StringName)

var definitions: Dictionary = {}
var active: Dictionary = {}
var completed: Dictionary = {}
var progress: Dictionary = {}
var unlocked_helpers: Dictionary = {}
var hall_milestones: Dictionary = {}


func register_definition(data: Dictionary) -> Error:
	var quest_id := StringName(data.get("id", ""))
	var requirements_value: Variant = data.get("requirements", {})
	var stages_value: Variant = data.get("stages", [])
	if quest_id.is_empty() or not requirements_value is Dictionary or not stages_value is Array:
		return ERR_INVALID_DATA
	for stage_value in stages_value:
		if not stage_value is Dictionary:
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
	return OK


func is_active(quest_id: StringName) -> bool:
	return active.has(quest_id)


func stage(quest_id: StringName) -> int:
	return int(progress.get(quest_id, 0))


func advance(quest_id: StringName) -> Error:
	if not active.has(quest_id):
		return ERR_INVALID_DATA
	var next_stage := stage(quest_id) + 1
	if next_stage >= stage_count(quest_id):
		return ERR_UNAVAILABLE
	progress[quest_id] = next_stage
	quest_progressed.emit(quest_id, next_stage)
	return OK


func stage_count(quest_id: StringName) -> int:
	var definition: Dictionary = definitions.get(quest_id, {})
	var stages_value: Variant = definition.get("stages", [])
	return maxi(1, stages_value.size() if stages_value is Array else 1)


func complete(quest_id: StringName) -> Error:
	if not active.has(quest_id) or not definitions.has(quest_id) or stage(quest_id) < stage_count(quest_id) - 1:
		return ERR_INVALID_DATA
	active.erase(quest_id)
	progress.erase(quest_id)
	completed[quest_id] = true
	var rewards_value: Variant = definitions[quest_id].get("rewards", {})
	if rewards_value is Dictionary:
		var helper := StringName(rewards_value.get("helper", ""))
		var milestone := StringName(rewards_value.get("hall_milestone", ""))
		if not helper.is_empty():
			unlocked_helpers[helper] = true
		if not milestone.is_empty():
			hall_milestones[milestone] = true
	quest_completed.emit(quest_id)
	return OK


func requirement_count(quest_id: StringName, inventory, item_id: StringName) -> int:
	if inventory == null or not definitions.has(quest_id):
		return 0
	if item_id == &"any_fish":
		var count := 0
		for key_value in inventory.items.keys():
			var key := String(key_value)
			if key.begins_with("fish_"):
				count += int(inventory.items[key_value])
		return count
	return inventory.item_count(item_id)


func snapshot() -> Dictionary:
	return {"active": active.duplicate(true), "completed": completed.duplicate(true), "progress": progress.duplicate(true), "unlocked_helpers": unlocked_helpers.duplicate(true), "hall_milestones": hall_milestones.duplicate(true)}


func restore(data: Dictionary) -> Error:
	for key in ["active", "completed", "unlocked_helpers", "hall_milestones"]:
		if not data.get(key, {}) is Dictionary:
			return ERR_INVALID_DATA
	active = data["active"].duplicate(true)
	completed = data["completed"].duplicate(true)
	var progress_value: Variant = data.get("progress", {})
	if not progress_value is Dictionary:
		return ERR_INVALID_DATA
	progress = progress_value.duplicate(true)
	for quest_value in active.keys():
		var quest_id := StringName(quest_value)
		if not definitions.has(quest_id) or stage(quest_id) < 0 or stage(quest_id) >= stage_count(quest_id):
			return ERR_INVALID_DATA
		if not progress.has(quest_id):
			progress[quest_id] = 0
	unlocked_helpers = data["unlocked_helpers"].duplicate(true)
	hall_milestones = data["hall_milestones"].duplicate(true)
	return OK
