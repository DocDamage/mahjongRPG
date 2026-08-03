extends RefCounted


static func register_definitions(farm) -> Error:
	var file := FileAccess.open("res://data/farm/vertical_slice_construction.json", FileAccess.READ)
	if file == null:
		return ERR_FILE_NOT_FOUND
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ERR_FILE_CORRUPT
	var definitions_value: Variant = parsed.get("constructions", [])
	if not definitions_value is Array:
		return ERR_INVALID_DATA
	for definition_value in definitions_value:
		if not definition_value is Dictionary or farm.register_construction_definition(definition_value) != OK:
			return ERR_INVALID_DATA
	return OK
