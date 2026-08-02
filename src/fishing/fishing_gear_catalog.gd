extends RefCounted

const PATH := "res://data/fish/vertical_slice_fishing_gear.json"
const CATEGORIES := [&"rods", &"baits", &"lures", &"hooks", &"lines"]


static func default_profile() -> Dictionary:
	var file := FileAccess.open(PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	if not parsed is Dictionary:
		return {}
	var loadout_value: Variant = parsed.get("default_loadout", {})
	if not loadout_value is Dictionary:
		return {}
	var profile := {"label": "Riverbend Kit", "reel_multiplier": 1.0, "bite_wait_multiplier": 1.0, "hook_window_multiplier": 1.0, "tension_multiplier": 1.0}
	for category in CATEGORIES:
		var entries_value: Variant = parsed.get(String(category), [])
		var selected_id := StringName(loadout_value.get(String(category).trim_suffix("s"), ""))
		var entry := _find(entries_value, selected_id)
		if entry.is_empty():
			return {}
		profile["label"] = "%s • %s" % [profile["label"], entry["name"]]
		for key in ["reel_multiplier", "bite_wait_multiplier", "hook_window_multiplier", "tension_multiplier"]:
			if entry.has(key):
				profile[key] = float(profile[key]) * float(entry[key])
	return profile


static func _find(entries_value: Variant, selected_id: StringName) -> Dictionary:
	if not entries_value is Array or selected_id.is_empty():
		return {}
	for entry_value in entries_value:
		if entry_value is Dictionary and StringName(entry_value.get("id", "")) == selected_id and not String(entry_value.get("name", "")).is_empty():
			return entry_value
	return {}
