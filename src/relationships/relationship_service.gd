extends RefCounted

signal relationship_changed(relationship_id: StringName, value: int)
signal dialogue_choice_recorded(choice_id: StringName)

var definitions: Dictionary = {}
var values: Dictionary = {}
var choices: Dictionary = {}


func register_definition(data: Dictionary) -> Error:
	var relationship_id := StringName(data.get("id", ""))
	if relationship_id.is_empty() or definitions.has(relationship_id):
		return ERR_INVALID_DATA
	definitions[relationship_id] = data.duplicate(true)
	return OK


func adjust(relationship_id: StringName, amount: int) -> Error:
	if not definitions.has(relationship_id):
		return ERR_DOES_NOT_EXIST
	values[relationship_id] = clampi(int(values.get(relationship_id, 0)) + amount, -3, 3)
	relationship_changed.emit(relationship_id, int(values[relationship_id]))
	return OK


func value(relationship_id: StringName) -> int:
	return int(values.get(relationship_id, 0))


func record_choice(choice_id: StringName, relationship_id: StringName, amount: int) -> Error:
	if choice_id.is_empty() or choices.has(choice_id):
		return ERR_ALREADY_IN_USE
	if adjust(relationship_id, amount) != OK:
		return ERR_DOES_NOT_EXIST
	choices[choice_id] = true
	dialogue_choice_recorded.emit(choice_id)
	return OK


func dialogue_line(relationship_id: StringName) -> String:
	var definition: Dictionary = definitions.get(relationship_id, {})
	var lines: Dictionary = definition.get("lines", {})
	if lines.is_empty():
		return "They have nothing more to say right now."
	var key := "warm" if value(relationship_id) > 0 else "cool" if value(relationship_id) < 0 else "neutral"
	return String(lines.get(key, lines.get("neutral", "They listen in silence.")))


func snapshot() -> Dictionary:
	return {"values": values.duplicate(true), "choices": choices.duplicate(true)}


func restore(data: Dictionary) -> Error:
	var next_values: Variant = data.get("values", {})
	var next_choices: Variant = data.get("choices", {})
	if not next_values is Dictionary or not next_choices is Dictionary:
		return ERR_INVALID_DATA
	for relationship_id_value in next_values:
		if not definitions.has(StringName(relationship_id_value)) or abs(int(next_values[relationship_id_value])) > 3:
			return ERR_INVALID_DATA
	values = next_values.duplicate(true)
	choices = next_choices.duplicate(true)
	return OK
