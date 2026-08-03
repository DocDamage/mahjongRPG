extends RefCounted


static func matching_objective_ids(objectives: Array, event: Dictionary) -> Array[StringName]:
	var matches: Array[StringName] = []
	var kind := StringName(event.get("kind", ""))
	var payload_value: Variant = event.get("payload", {})
	if not payload_value is Dictionary:
		return matches
	for objective_value in objectives:
		if not objective_value is Dictionary:
			continue
		var objective: Dictionary = objective_value
		if StringName(objective.get("type", "")) != &"event_once" or StringName(objective.get("event_kind", "")) != kind:
			continue
		var expected_value: Variant = objective.get("match", {})
		if expected_value is Dictionary and _payload_matches(expected_value, payload_value):
			matches.append(StringName(objective.get("id", "")))
	return matches


static func event_matches_stage(stage: Dictionary, event: Dictionary) -> bool:
	var objectives_value: Variant = stage.get("objectives", [])
	return objectives_value is Array and not matching_objective_ids(objectives_value, event).is_empty()


static func _payload_matches(expected: Dictionary, actual: Dictionary) -> bool:
	for key_value in expected:
		if not actual.has(key_value) or actual[key_value] != expected[key_value]:
			return false
	return true
