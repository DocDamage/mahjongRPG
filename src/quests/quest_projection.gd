extends RefCounted


static func build(quest_id: StringName, definition: Dictionary, stage_data: Dictionary, objectives: Array, inventory_counts: Dictionary) -> Dictionary:
	var objective: Dictionary = objectives[0] if not objectives.is_empty() and objectives[0] is Dictionary else {}
	var live_counts: Dictionary = {}
	var requirements_value: Variant = definition.get("requirements", {})
	if requirements_value is Dictionary:
		for item_value in requirements_value:
			var item_id := StringName(item_value)
			live_counts[item_id] = _fish_count(inventory_counts) if item_id == &"any_fish" else int(inventory_counts.get(item_id, 0))
	return {
		"quest_id": quest_id,
		"title_key": StringName(definition.get("title_key", "")),
		"title": String(definition.get("title", quest_id)),
		"stage_id": StringName(stage_data.get("id", "")),
		"objective_id": StringName(objective.get("id", "")),
		"label_key": StringName(objective.get("label_key", stage_data.get("dialogue_id", ""))),
		"current": 0,
		"target": 1,
		"complete": false,
		"requirements": requirements_value.duplicate(true) if requirements_value is Dictionary else {},
		"live_counts": live_counts,
	}


static func _fish_count(inventory_counts: Dictionary) -> int:
	var total := 0
	for item_value in inventory_counts:
		if String(item_value).begins_with("fish_"):
			total += int(inventory_counts[item_value])
	return total
