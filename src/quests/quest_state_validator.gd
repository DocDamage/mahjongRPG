extends RefCounted


static func validated_restore(service, data: Dictionary) -> Dictionary:
	for key in ["active", "completed", "unlocked_helpers", "hall_milestones"]:
		if not data.get(key, {}) is Dictionary:
			return {}
	var next_active: Dictionary = data["active"].duplicate(true)
	var next_completed: Dictionary = data["completed"].duplicate(true)
	if not _valid_flags(next_active) or not _valid_flags(next_completed) or not _valid_flags(data["unlocked_helpers"]) or not _valid_flags(data["hall_milestones"]):
		return {}
	var progress_value: Variant = data.get("progress", {})
	if not progress_value is Dictionary:
		return {}
	var next_progress: Dictionary = progress_value.duplicate(true)
	for quest_value in next_active:
		var quest_id := StringName(quest_value)
		if not service.definitions.has(quest_id) or next_completed.has(quest_id):
			return {}
		if not next_progress.has(quest_value):
			next_progress[quest_value] = 0
		var next_stage_value: Variant = next_progress[quest_value]
		if not _is_integer_number(next_stage_value) or int(next_stage_value) < 0 or int(next_stage_value) >= service.stage_count(quest_id):
			return {}
	for quest_value in next_completed:
		if not service.definitions.has(StringName(quest_value)):
			return {}
	for quest_value in next_progress:
		if not next_active.has(quest_value):
			return {}
	return {
		"active": next_active,
		"completed": next_completed,
		"progress": next_progress,
		"unlocked_helpers": data["unlocked_helpers"].duplicate(true),
		"hall_milestones": data["hall_milestones"].duplicate(true),
	}


static func _is_integer_number(value: Variant) -> bool:
	return value is int or value is float and is_equal_approx(value, roundf(value))


static func _valid_flags(value: Dictionary) -> bool:
	for key_value in value:
		if StringName(key_value).is_empty() or value[key_value] != true:
			return false
	return true
