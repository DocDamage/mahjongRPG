extends RefCounted

const TABLE_ID := &"dialogue"
const TABLE_PATH := "res://data/dialogue/vertical_slice_dialogue.json"


static func text(line_id: StringName, values: Dictionary = {}, locale := "") -> String:
	var table := _table()
	var selected_locale := locale if not locale.is_empty() else String(table.get("default_locale", "en"))
	var locales_value: Variant = table.get("locales", {})
	var localized: Variant = locales_value.get(selected_locale, {}) if locales_value is Dictionary else table
	var lines_value: Variant = localized.get("lines", {}) if localized is Dictionary else {}
	if not lines_value is Dictionary:
		return ""
	var result := String(lines_value.get(line_id, ""))
	for key_value in values:
		result = result.replace("{%s}" % key_value, str(values[key_value]))
	return result


static func has_text(line_id: StringName, locale := "") -> bool:
	return not text(line_id, {}, locale).is_empty()


static func release_required_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for key_value in _table().get("release_required_keys", []):
		keys.append(StringName(key_value))
	return keys


static func sequence(sequence_id: StringName) -> Dictionary:
	for value in _table().get("sequences", []):
		if value is Dictionary and StringName(value.get("id", "")) == sequence_id:
			return value.duplicate(true)
	return {}


static func sequences() -> Array:
	var values: Variant = _table().get("sequences", [])
	return values.duplicate(true) if values is Array else []


static func localization_keys() -> Array:
	var table := _table()
	var locales_value: Variant = table.get("locales", {})
	var locale: Variant = locales_value.get(table.get("default_locale", "en"), {}) if locales_value is Dictionary else {}
	var lines: Variant = locale.get("lines", {}) if locale is Dictionary else {}
	return lines.keys() if lines is Dictionary else []


static func _table() -> Dictionary:
	var scene_tree := Engine.get_main_loop() as SceneTree
	var registry = scene_tree.root.get_node_or_null("ContentRegistry") if scene_tree != null else null
	if registry != null:
		if not registry.has_table(TABLE_ID):
			registry.load_table(TABLE_ID, TABLE_PATH)
		return registry.table(TABLE_ID)
	var file := FileAccess.open(TABLE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	return parsed if parsed is Dictionary else {}
