extends RefCounted

const TABLE_ID := &"dialogue"
const TABLE_PATH := "res://data/dialogue/vertical_slice_dialogue.json"


static func text(line_id: StringName, values: Dictionary = {}) -> String:
	var lines_value: Variant = _table().get("lines", {})
	if not lines_value is Dictionary:
		return ""
	var result := String(lines_value.get(line_id, ""))
	for key_value in values:
		result = result.replace("{%s}" % key_value, str(values[key_value]))
	return result


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
