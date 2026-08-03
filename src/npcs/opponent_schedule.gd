extends RefCounted

const TABLE_ID := &"opponent_schedules"
const TABLE_PATH := "res://data/schedules/vertical_slice_opponent_schedules.json"


static func state(opponent_id: StringName, weather_id: StringName, hour: int) -> Dictionary:
	var opponents_value: Variant = _table().get("opponents", {})
	if not opponents_value is Dictionary:
		return {}
	var entry_value: Variant = opponents_value.get(String(opponent_id), {})
	if not entry_value is Dictionary:
		return {}
	var weather_value: Variant = entry_value.get(String(weather_id), entry_value.get("clear", {}))
	if not weather_value is Dictionary:
		return {}
	var hours_value: Variant = weather_value.get("hours", [])
	var position_value: Variant = weather_value.get("position", [])
	if not hours_value is Array or hours_value.size() != 2 or not position_value is Array or position_value.size() != 2:
		return {}
	return {
		"available": hour >= int(hours_value[0]) and hour < int(hours_value[1]),
		"position": Vector2(float(position_value[0]), float(position_value[1])),
		"activity": String(weather_value.get("activity", "away")),
	}


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
