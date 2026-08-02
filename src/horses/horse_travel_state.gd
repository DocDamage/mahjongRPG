extends RefCounted

const COLORS := [&"black", &"brown", &"golden", &"gray", &"white"]

var selected_color: StringName = &"brown"
var mounted := false
var discovered_posts: Dictionary = {}
var mounted_scene := ""
var mounted_position := Vector2.ZERO


func select_color(color: StringName) -> Error:
	if not color in COLORS:
		return ERR_INVALID_PARAMETER
	selected_color = color
	return OK


func mount(allowed: bool, scene_path := "", position := Vector2.ZERO) -> Error:
	if mounted or not allowed:
		return ERR_UNAVAILABLE
	mounted = true
	mounted_scene = scene_path
	mounted_position = position
	return OK


func dismount(safe_position: bool) -> Error:
	if not mounted or not safe_position:
		return ERR_UNAVAILABLE
	mounted = false
	mounted_scene = ""
	return OK


func discover(post_id: StringName) -> void:
	discovered_posts[post_id] = true


func can_fast_travel(post_id: StringName) -> bool:
	return mounted and discovered_posts.has(post_id)


func record_mounted_location(scene_path: String, position: Vector2) -> void:
	if mounted and scene_path.begins_with("res://"):
		mounted_scene = scene_path
		mounted_position = position


func snapshot() -> Dictionary:
	return {
		"selected_color": str(selected_color),
		"mounted": mounted,
		"discovered_posts": discovered_posts.duplicate(true),
		"mounted_scene": mounted_scene,
		"mounted_position": [mounted_position.x, mounted_position.y],
	}


func restore(snapshot_data: Dictionary) -> Error:
	if select_color(StringName(snapshot_data.get("selected_color", ""))) != OK:
		return ERR_INVALID_DATA
	var posts_value = snapshot_data.get("discovered_posts", {})
	if not posts_value is Dictionary:
		return ERR_INVALID_DATA
	var position_value: Variant = snapshot_data.get("mounted_position", [])
	var scene_value := String(snapshot_data.get("mounted_scene", ""))
	if not position_value is Array or position_value.size() != 2:
		mounted = false
		mounted_scene = ""
		mounted_position = Vector2.ZERO
		discovered_posts = posts_value.duplicate(true)
		return OK
	mounted = bool(snapshot_data.get("mounted", false)) and scene_value.begins_with("res://")
	mounted_scene = scene_value if mounted else ""
	mounted_position = Vector2(float(position_value[0]), float(position_value[1])) if mounted else Vector2.ZERO
	discovered_posts = posts_value.duplicate(true)
	return OK
