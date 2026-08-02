extends "res://src/interaction/world_interactable.gd"

const MOUNTED_SPEED := 300.0
const RuntimeAssetCatalog = preload("res://src/content/runtime_asset_catalog.gd")

signal feedback(message: String)

@export var travel_bounds := Rect2()

var _rider: Node2D
var _awaiting_interact_release := false


func _ready() -> void:
	interacted.connect(_on_interacted)
	var texture_path := RuntimeAssetCatalog.horse_texture_path(GameSession.horse.selected_color)
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("Missing generated horse texture: %s" % GameSession.horse.selected_color)
		return
	$Sprite2D.texture = texture
	$Sprite2D.region_enabled = true
	$Sprite2D.region_rect = Rect2(0, 0, 128, 128)
	queue_redraw()
	if GameSession.horse.mounted:
		if GameSession.horse.mounted_scene == get_tree().current_scene.scene_file_path:
			global_position = GameSession.horse.mounted_position
		else:
			GameSession.horse.mounted = false
		call_deferred("_restore_mounted_rider")


func _process(delta: float) -> void:
	if not GameSession.horse.mounted:
		return
	if _awaiting_interact_release:
		if not Input.is_action_pressed(&"interact"):
			_awaiting_interact_release = false
		return
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	global_position += direction * MOUNTED_SPEED * delta
	if travel_bounds.has_area():
		global_position = global_position.clamp(travel_bounds.position, travel_bounds.end)
	GameSession.horse.record_mounted_location(get_tree().current_scene.scene_file_path, global_position)
	GameSession.record_player_state(get_tree().current_scene.scene_file_path, global_position)
	if Input.is_action_just_pressed(&"interact"):
		_dismount()


func _on_interacted(actor: Node2D) -> void:
	if GameSession.horse.mounted:
		return
	if GameSession.horse.mount(true, get_tree().current_scene.scene_file_path, global_position) != OK:
		feedback.emit("The horse cannot be mounted here.")
		return
	_rider = actor
	_rider.visible = false
	_rider.set_physics_process(false)
	_awaiting_interact_release = true
	feedback.emit("Mounted %s horse. Ride faster; press E / A to dismount." % GameSession.horse.selected_color.capitalize())


func _dismount() -> void:
	if GameSession.horse.dismount(travel_bounds.has_point(global_position)) != OK:
		feedback.emit("No safe place to dismount.")
		return
	if _rider != null:
		_rider.global_position = global_position
		_rider.visible = true
		_rider.set_physics_process(true)
	_rider = null
	feedback.emit("Dismounted.")


func _restore_mounted_rider() -> void:
	var rider = get_parent().get_node_or_null("Doc")
	if rider == null:
		GameSession.horse.mounted = false
		return
	_rider = rider
	_rider.global_position = global_position
	_rider.visible = false
	_rider.set_physics_process(false)
	_awaiting_interact_release = true
