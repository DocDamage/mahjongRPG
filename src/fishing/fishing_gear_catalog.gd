extends RefCounted

const PATH := "res://data/fish/vertical_slice_fishing_gear.json"
const CATEGORIES := [&"rods", &"baits", &"lures", &"hooks", &"lines", &"bobbers"]


static func default_loadout() -> Dictionary:
	var value: Variant = _table().get("default_loadout", {})
	return value.duplicate(true) if value is Dictionary else {}


static func starter_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for value in default_loadout().values():
		result.append(StringName(value))
	return result


static func default_profile() -> Dictionary:
	return profile(default_loadout())


static func profile(loadout: Dictionary) -> Dictionary:
	var result := {"label": "Angler Kit", "reel_multiplier": 1.0, "bite_wait_multiplier": 1.0, "hook_window_multiplier": 1.0, "tension_multiplier": 1.0}
	for category in CATEGORIES:
		var entry := entry_for_category(category, StringName(loadout.get(String(category).trim_suffix("s"), "")))
		if entry.is_empty():
			return {}
		result["label"] = "%s • %s" % [result["label"], entry["name"]]
		for key in ["reel_multiplier", "bite_wait_multiplier", "hook_window_multiplier", "tension_multiplier"]:
			if entry.has(key):
				result[key] = float(result[key]) * float(entry[key])
	return result


static func entry(gear_id: StringName) -> Dictionary:
	for category in CATEGORIES:
		var result := entry_for_category(category, gear_id)
		if not result.is_empty():
			return result
	return {}


static func category_for(gear_id: StringName) -> StringName:
	for category in CATEGORIES:
		if not entry_for_category(category, gear_id).is_empty():
			return StringName(String(category).trim_suffix("s"))
	return &""


static func entry_for_category(category: StringName, gear_id: StringName) -> Dictionary:
	var entries_value: Variant = _table().get(String(category), [])
	if entries_value is Array:
		for value in entries_value:
			if value is Dictionary and StringName(value.get("id", "")) == gear_id and not String(value.get("name", "")).is_empty():
				return value.duplicate(true)
	return {}


static func _table() -> Dictionary:
	var file := FileAccess.open(PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	return parsed if parsed is Dictionary else {}
