extends RefCounted


func run() -> Array[String]:
	var failures: Array[String] = []
	var file := FileAccess.open("res://data/crops/vertical_slice_crops.json", FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	if not parsed is Dictionary:
		return ["crop catalog should be valid JSON"]
	var cataloged: Variant = parsed.get("cataloged_source_crops", [])
	var crops: Variant = parsed.get("crops", [])
	if not cataloged is Array or cataloged.size() != 20 or not crops is Array:
		failures.append("all twenty supplied crop candidates should be cataloged")
		return failures
	var entries: Dictionary = {}
	for crop_value in crops:
		if crop_value is Dictionary:
			entries[StringName(crop_value.get("id", ""))] = crop_value
	for crop_id_value in cataloged:
		if not entries.has(StringName(crop_id_value)):
			failures.append("cataloged crop definition is missing: %s" % crop_id_value)
	var active: Array[StringName] = []
	for crop_value in entries.values():
		if bool(crop_value.get("available_in_slice", false)):
			active.append(StringName(crop_value.get("id", "")))
	if active.size() != entries.size() or active.size() != 21 or not &"beans" in active or not &"pumpkin" in active:
		failures.append("P6 should activate the original Wayward crop plus every twenty cataloged ranch crop")
	return failures
