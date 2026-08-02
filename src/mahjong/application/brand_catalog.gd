extends RefCounted

const CATALOG_PATH := "res://data/brands/six_brands.json"

var _definitions: Dictionary = {}


func _init() -> void:
	_load()


func definition(brand: StringName) -> Dictionary:
	return _definitions.get(brand, {}).duplicate(true)


func all() -> Array[StringName]:
	var result: Array[StringName] = []
	for brand_value in _definitions:
		result.append(StringName(brand_value))
	result.sort()
	return result


func description(brand: StringName) -> String:
	var item := definition(brand)
	return "%s Brand — %s" % [String(item.get("name", brand)).capitalize(), String(item.get("power", ""))]


func _load() -> void:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	var brands: Variant = parsed.get("brands", []) if parsed is Dictionary else []
	if not brands is Array:
		push_error("Invalid six-Brand catalog")
		return
	for entry in brands:
		if not entry is Dictionary:
			continue
		var brand := StringName(entry.get("id", ""))
		if not brand.is_empty():
			_definitions[brand] = entry.duplicate(true)
