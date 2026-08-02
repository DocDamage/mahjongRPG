extends RefCounted

const TABLE_ID := &"runtime_assets"
const TABLE_PATH := "res://data/runtime_assets/vertical_slice_assets.json"


static func hero_texture_path(direction: StringName, action: StringName) -> String:
	if not _hero_value_is_valid(direction, action):
		return ""
	return "res://assets/generated/player/cowboy_%s_%s.png" % [direction, action]


static func horse_texture_path(color: StringName) -> String:
	var catalog := _catalog()
	var horses_value: Variant = catalog.get("horses", {})
	if not horses_value is Dictionary or not color in horses_value.get("colors", []):
		return ""
	return "res://assets/generated/horses/horse_%s.png" % color


static func hero_frame_size() -> Vector2i:
	var hero := _hero()
	var size_value: Variant = hero.get("frame_size", [])
	if not size_value is Array or size_value.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(size_value[0]), int(size_value[1]))


static func hero_frame_count(action: StringName) -> int:
	var counts_value: Variant = _hero().get("frame_counts", {})
	if not counts_value is Dictionary:
		return 0
	return int(counts_value.get(action, 0))


static func _hero_value_is_valid(direction: StringName, action: StringName) -> bool:
	var hero := _hero()
	return direction in hero.get("directions", []) and action in hero.get("actions", [])


static func _hero() -> Dictionary:
	var hero_value: Variant = _catalog().get("hero", {})
	return hero_value if hero_value is Dictionary else {}


static func _catalog() -> Dictionary:
	var scene_tree := Engine.get_main_loop() as SceneTree
	var registry = scene_tree.root.get_node_or_null("ContentRegistry") if scene_tree != null else null
	if registry != null:
		if not registry.has_table(TABLE_ID):
			registry.load_table(TABLE_ID, TABLE_PATH)
		return registry.table(TABLE_ID)
	var file := FileAccess.open(TABLE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	return parsed if parsed is Dictionary else {}
