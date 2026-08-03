extends RefCounted

var definitions: Dictionary = {}
var discovered: Dictionary = {}


func register_definition(data: Dictionary) -> Error:
	var evidence_id := StringName(data.get("id", ""))
	var text_key := StringName(data.get("text_key", ""))
	if evidence_id.is_empty() or text_key.is_empty():
		return ERR_INVALID_DATA
	definitions[evidence_id] = data.duplicate(true)
	return OK


func discover(evidence_id: StringName) -> Error:
	if not definitions.has(evidence_id):
		return ERR_DOES_NOT_EXIST
	discovered[evidence_id] = true
	return OK


func has(evidence_id: StringName) -> bool:
	return discovered.has(evidence_id)


func snapshot() -> Dictionary:
	return {"discovered": discovered.duplicate(true)}


func restore(data: Dictionary) -> Error:
	var discovered_value: Variant = data.get("discovered", {})
	if not discovered_value is Dictionary:
		return ERR_INVALID_DATA
	for evidence_value in discovered_value:
		if not definitions.has(StringName(evidence_value)):
			return ERR_DOES_NOT_EXIST
	discovered = discovered_value.duplicate(true)
	return OK
