extends SceneTree

const REQUIRED_AUTOLOADS := [&"GameSession", &"SceneRouter", &"SaveService", &"AudioService", &"InputService", &"ContentRegistry", &"SaveMenu"]
const REQUIRED_INPUTS := [&"move_up", &"move_down", &"move_left", &"move_right", &"interact", &"run", &"save_game", &"load_game", &"fish_reel", &"fish_release", &"fish_rod_left", &"fish_rod_right", &"pause", &"place_field"]
const DATA_TABLES := {
	&"crops": "res://data/crops/vertical_slice_crops.json",
	&"audio": "res://data/audio/vertical_slice_audio.json",
	&"fish": "res://data/fish/vertical_slice_fish.json",
	&"horses": "res://data/horses/vertical_slice_horses.json",
	&"items": "res://data/items/vertical_slice_items.json",
	&"opponents": "res://data/opponents/vertical_slice_opponents.json",
	&"quests": "res://data/quests/vertical_slice_quests.json",
	&"animals": "res://data/animals/vertical_slice_animals.json",
	&"dialogue": "res://data/dialogue/vertical_slice_dialogue.json",
	&"runtime_assets": "res://data/runtime_assets/vertical_slice_assets.json",
	&"opponent_schedules": "res://data/schedules/vertical_slice_opponent_schedules.json",
}
const REQUIRED_ASSETS := [
	"res://assets/generated/player/cowboy_down_walk.png",
	"res://assets/generated/player/cowboy_up_walk.png",
	"res://assets/generated/player/cowboy_left_walk.png",
	"res://assets/generated/player/cowboy_right_walk.png",
	"res://assets/generated/player/cowboy_down_idle.png",
	"res://assets/generated/player/cowboy_right_draw.png",
	"res://assets/generated/player/cowboy_left_armed.png",
	"res://assets/generated/player/cowboy_up_shoot.png",
	"res://assets/generated/horses/horse_black.png",
	"res://assets/generated/horses/horse_brown.png",
	"res://assets/generated/horses/horse_golden.png",
	"res://assets/generated/horses/horse_gray.png",
	"res://assets/generated/horses/horse_white.png",
	"res://assets/generated/audio/footstep_grass.wav",
	"res://assets/generated/audio/footstep_gravel.wav",
	"res://assets/generated/audio/footstep_wood.wav",
	"res://assets/generated/audio/mahjong_tile_wood.wav",
]


func _init() -> void:
	call_deferred("_validate")


func _validate() -> void:
	var failures: Array[String] = []
	for autoload_name in REQUIRED_AUTOLOADS:
		if root.get_node_or_null(NodePath(autoload_name)) == null:
			failures.append("missing autoload: %s" % autoload_name)
	if not ResourceLoader.exists("res://src/bootstrap/bootstrap.tscn"):
		failures.append("missing configured main scene")
	elif load("res://src/bootstrap/bootstrap.tscn") == null:
		failures.append("main scene failed to load")
	for action in REQUIRED_INPUTS:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			failures.append("missing input action: %s" % action)
	var content_registry = root.get_node_or_null("ContentRegistry")
	for table_id in DATA_TABLES:
		var path: String = DATA_TABLES[table_id]
		if content_registry == null or content_registry.load_table(table_id, path) != OK:
			failures.append("invalid runtime data table: %s" % path)
	for asset_path in REQUIRED_ASSETS:
		if not ResourceLoader.exists(asset_path):
			failures.append("missing runtime asset: %s" % asset_path)
	if failures.is_empty():
		print("Runtime smoke test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
