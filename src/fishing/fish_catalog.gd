extends RefCounted

const PATH := "res://data/fish/vertical_slice_fish.json"
const FishDefinition = preload("res://src/fishing/fish_definition.gd")


static func definitions() -> Array:
	var result: Array = []
	var parsed := _table()
	var values: Variant = parsed.get("fish", [])
	if values is Array:
		for value in values:
			if value is Dictionary:
				result.append(FishDefinition.new(value))
	return result


static func definition(fish_id: StringName) -> Dictionary:
	var values: Variant = _table().get("fish", [])
	if values is Array:
		for value in values:
			if value is Dictionary and StringName(value.get("id", "")) == fish_id:
				return value.duplicate(true)
	return {}


static func shore_conditions() -> Array[StringName]:
	var result: Array[StringName] = []
	var values: Variant = _table().get("shore_conditions", [])
	if values is Array:
		for value in values:
			if not String(value).is_empty():
				result.append(StringName(value))
	return result


static func rare_conditions() -> Array[StringName]:
	var result: Array[StringName] = []
	for fish in definitions():
		for condition in fish.rare_conditions:
			if not result.has(condition):
				result.append(condition)
	return result


static func _table() -> Dictionary:
	var file := FileAccess.open(PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	return parsed if parsed is Dictionary else {}
