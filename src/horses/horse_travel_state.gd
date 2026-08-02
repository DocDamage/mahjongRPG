extends RefCounted

const COLORS := [&"black", &"brown", &"golden", &"gray", &"white"]

var selected_color: StringName = &"brown"
var mounted := false
var discovered_posts: Dictionary = {}


func select_color(color: StringName) -> Error:
	if not color in COLORS:
		return ERR_INVALID_PARAMETER
	selected_color = color
	return OK


func mount(allowed: bool) -> Error:
	if mounted or not allowed:
		return ERR_UNAVAILABLE
	mounted = true
	return OK


func dismount(safe_position: bool) -> Error:
	if not mounted or not safe_position:
		return ERR_UNAVAILABLE
	mounted = false
	return OK


func discover(post_id: StringName) -> void:
	discovered_posts[post_id] = true


func can_fast_travel(post_id: StringName) -> bool:
	return mounted and discovered_posts.has(post_id)


func snapshot() -> Dictionary:
	return {
		"selected_color": str(selected_color),
		"mounted": mounted,
		"discovered_posts": discovered_posts.duplicate(true),
	}


func restore(snapshot_data: Dictionary) -> Error:
	if select_color(StringName(snapshot_data.get("selected_color", ""))) != OK:
		return ERR_INVALID_DATA
	var posts_value = snapshot_data.get("discovered_posts", {})
	if not posts_value is Dictionary:
		return ERR_INVALID_DATA
	mounted = bool(snapshot_data.get("mounted", false))
	discovered_posts = posts_value.duplicate(true)
	return OK
