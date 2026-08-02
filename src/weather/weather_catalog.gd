extends RefCounted

const PATH := "res://data/weather/vertical_slice_weather.json"


static func active_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry in _entries():
		if bool(entry.get("available_in_slice", false)) and int(entry.get("roll_weight", 0)) > 0:
			ids.append(StringName(entry["id"]))
	return ids


static func roll_slice_weather(seed: int, day: int) -> StringName:
	var entries: Array[Dictionary] = []
	var total_weight := 0
	for entry in _entries():
		var weight := int(entry.get("roll_weight", 0))
		if bool(entry.get("available_in_slice", false)) and weight > 0:
			entries.append(entry)
			total_weight += weight
	if entries.is_empty() or total_weight <= 0:
		return &"clear"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + day
	var roll := rng.randi_range(1, total_weight)
	for entry in entries:
		roll -= int(entry["roll_weight"])
		if roll <= 0:
			return StringName(entry["id"])
	return StringName(entries.back()["id"])


static func _entries() -> Array[Dictionary]:
	var file := FileAccess.open(PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	var entries: Array[Dictionary] = []
	if parsed is Dictionary and parsed.get("weather", []) is Array:
		for entry_value in parsed["weather"]:
			if entry_value is Dictionary and not String(entry_value.get("id", "")).is_empty():
				entries.append(entry_value)
	return entries
