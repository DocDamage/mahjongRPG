extends CharacterBody2D

signal facing_changed(direction: StringName)
signal interaction_target_changed(target: Area2D)

const WALK_SPEED := 150.0
const RUN_SPEED := 230.0
const FOOTSTEP_DISTANCE := 42.0
const RuntimeAssetCatalog = preload("res://src/content/runtime_asset_catalog.gd")
const DIRECTIONS := [&"down", &"up", &"left", &"right"]

@export var running := false
@export var movement_bounds := Rect2()
@export var footstep_event: StringName = &"footstep_grass"
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

var facing: StringName = &"down"
var _interaction_targets: Array[Area2D] = []
var _prompt_label: Label
var _current_prompt_target: Area2D
var _using_controller := false
var _footstep_distance := 0.0
var _story_action: StringName


func _ready() -> void:
	_build_animations()
	_set_animation(false)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	interaction_target_changed.connect(_update_interaction_prompt)
	_create_interaction_prompt()
	var input_service = get_node_or_null("/root/InputService")
	if input_service != null:
		_using_controller = input_service.using_controller
		input_service.active_device_changed.connect(_on_active_device_changed)
	var session = _session()
	if session != null:
		session.session_restored.connect(_restore_session_position)
	call_deferred("_restore_or_record_session_position")


func _physics_process(delta: float) -> void:
	if _is_game_paused():
		velocity = Vector2.ZERO
		_set_animation(false)
		_show_pause_prompt()
		return
	_update_interaction_prompt(nearest_interaction_target())
	move_in_direction(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down"), delta)
	if Input.is_action_just_pressed(&"interact"):
		interact()


func move_in_direction(direction: Vector2, _delta: float) -> void:
	running = Input.is_action_pressed(&"run")
	velocity = velocity_from_direction(direction)
	if not velocity.is_zero_approx():
		_update_facing(velocity.normalized())
	var previous_position := global_position
	move_and_slide()
	if movement_bounds.has_area():
		global_position = global_position.clamp(movement_bounds.position, movement_bounds.end)
	_record_session_position()
	_set_animation(not velocity.is_zero_approx())
	_record_footstep(previous_position)


func velocity_from_direction(direction: Vector2) -> Vector2:
	var normalized := direction.limit_length(1.0)
	return normalized * (RUN_SPEED if running else WALK_SPEED)


func interact() -> void:
	var target: Area2D = nearest_interaction_target()
	if target != null:
		target.call("interact", self)


func nearest_interaction_target() -> Area2D:
	_interaction_targets = _interaction_targets.filter(func(target: Area2D) -> bool: return is_instance_valid(target))
	if _interaction_targets.is_empty():
		return null
	_interaction_targets.sort_custom(func(first: Area2D, second: Area2D) -> bool:
		return global_position.distance_squared_to(first.global_position) < global_position.distance_squared_to(second.global_position)
	)
	return _interaction_targets.front()


func _build_animations() -> void:
	var frames := SpriteFrames.new()
	for action in [&"walk", &"idle", &"draw", &"armed", &"shoot"]:
		for direction in DIRECTIONS:
			var animation_name := _animation_name(action, direction)
			frames.add_animation(animation_name)
			frames.set_animation_speed(animation_name, 8.0)
			frames.set_animation_loop(animation_name, action in [&"walk", &"idle"])
			var texture: Texture2D = load(RuntimeAssetCatalog.hero_texture_path(direction, action)) as Texture2D
			if texture == null:
				push_error("Missing generated hero texture: %s/%s" % [direction, action])
				continue
			for frame_index in RuntimeAssetCatalog.hero_frame_count(action):
				var frame := AtlasTexture.new()
				frame.atlas = texture
				frame.region = Rect2(Vector2(frame_index * RuntimeAssetCatalog.hero_frame_size().x, 0), RuntimeAssetCatalog.hero_frame_size())
				frames.add_frame(animation_name, frame)
	sprite.sprite_frames = frames


func _set_animation(moving: bool) -> void:
	var action: StringName = _story_action if not _story_action.is_empty() else (&"walk" if moving else &"idle")
	var animation_name := _animation_name(action, facing)
	if sprite.animation != animation_name:
		sprite.play(animation_name)
	if moving:
		sprite.speed_scale = 1.8 if running else 1.0
		if _story_action.is_empty():
			sprite.play()
	else:
		if _story_action.is_empty():
			sprite.play()
			sprite.speed_scale = 1.0


func play_story_animation(action: StringName) -> Error:
	if not action in [&"draw", &"armed", &"shoot"]:
		return ERR_INVALID_PARAMETER
	_story_action = action
	_set_animation(false)
	return OK


func clear_story_animation() -> void:
	_story_action = &""
	_set_animation(false)


func _animation_name(action: StringName, direction: StringName) -> StringName:
	return StringName("%s_%s" % [action, direction])


func _update_facing(direction: Vector2) -> void:
	var next_facing: StringName
	if absf(direction.x) > absf(direction.y):
		next_facing = &"right" if direction.x > 0.0 else &"left"
	else:
		next_facing = &"down" if direction.y > 0.0 else &"up"
	if next_facing != facing:
		facing = next_facing
		facing_changed.emit(facing)


func _on_interaction_area_entered(area: Area2D) -> void:
	if area.has_method("interact"):
		_interaction_targets.append(area)
		interaction_target_changed.emit(nearest_interaction_target())


func _on_interaction_area_exited(area: Area2D) -> void:
	if area.has_method("interact"):
		_interaction_targets.erase(area)
		interaction_target_changed.emit(nearest_interaction_target())


func _create_interaction_prompt() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	_prompt_label = Label.new()
	_prompt_label.position = Vector2(28, 442)
	_prompt_label.size = Vector2(600, 28)
	_prompt_label.add_theme_font_size_override("font_size", 17)
	_prompt_label.add_theme_color_override("font_color", Color("fff0bf"))
	_prompt_label.visible = false
	layer.add_child(_prompt_label)


func _update_interaction_prompt(target: Area2D) -> void:
	_current_prompt_target = target
	if _prompt_label == null:
		return
	if target == null or not is_instance_valid(target):
		_prompt_label.visible = false
		return
	var prompt := String(target.get("prompt_text"))
	_prompt_label.text = "%s  •  %s" % [_binding_text(&"interact"), prompt]
	_prompt_label.visible = not prompt.is_empty()


func _on_active_device_changed(using_controller: bool) -> void:
	_using_controller = using_controller
	_update_interaction_prompt(_current_prompt_target)


func _show_pause_prompt() -> void:
	if _prompt_label == null:
		return
	_prompt_label.text = "PAUSED  •  %s to resume" % _binding_text(&"pause")
	_prompt_label.visible = true


func _binding_text(action: StringName) -> String:
	var input_service = get_node_or_null("/root/InputService")
	if input_service != null:
		return input_service.prompt_binding_text(action, _using_controller)
	return String(action).capitalize()


func _restore_or_record_session_position() -> void:
	var session = _session()
	if session == null:
		return
	var current_scene = get_tree().current_scene
	if current_scene != null and session.player_scene == current_scene.scene_file_path:
		_restore_session_position()
	else:
		_record_session_position()


func _restore_session_position() -> void:
	var session = _session()
	if session == null:
		return
	var current_scene = get_tree().current_scene
	if current_scene == null or session.player_scene != current_scene.scene_file_path:
		return
	global_position = session.player_position
	if movement_bounds.has_area():
		global_position = global_position.clamp(movement_bounds.position, movement_bounds.end)


func _record_session_position() -> void:
	var session = _session()
	if session == null:
		return
	var current_scene = get_tree().current_scene
	if current_scene != null:
		session.record_player_state(current_scene.scene_file_path, global_position)


func _session():
	return get_node_or_null("/root/GameSession")


func _record_footstep(previous_position: Vector2) -> void:
	_footstep_distance += previous_position.distance_to(global_position)
	if _footstep_distance < FOOTSTEP_DISTANCE:
		return
	_footstep_distance = fmod(_footstep_distance, FOOTSTEP_DISTANCE)
	var audio = get_node_or_null("/root/AudioService")
	if audio != null:
		audio.play_catalog_event(footstep_event)


func _is_game_paused() -> bool:
	var session := get_node_or_null("/root/GameSession")
	return session != null and session.is_paused()
