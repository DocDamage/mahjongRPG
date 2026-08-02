extends CharacterBody2D

signal facing_changed(direction: StringName)
signal interaction_target_changed(target: Area2D)

const FRAME_SIZE := Vector2i(64, 64)
const FRAME_COUNT := 8
const WALK_SPEED := 150.0
const RUN_SPEED := 230.0
const WALK_TEXTURE_PATHS := {
	&"down": "res://assets/generated/player/cowboy_down_walk.png",
	&"up": "res://assets/generated/player/cowboy_up_walk.png",
	&"left": "res://assets/generated/player/cowboy_left_walk.png",
	&"right": "res://assets/generated/player/cowboy_right_walk.png",
}

@export var running := false
@export var movement_bounds := Rect2()
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

var facing: StringName = &"down"
var _interaction_targets: Array[Area2D] = []


func _ready() -> void:
	_build_animations()
	_set_animation(false)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)


func _physics_process(delta: float) -> void:
	if _is_game_paused():
		velocity = Vector2.ZERO
		_set_animation(false)
		return
	move_in_direction(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down"), delta)
	if Input.is_action_just_pressed(&"interact"):
		interact()


func move_in_direction(direction: Vector2, _delta: float) -> void:
	running = Input.is_action_pressed(&"run")
	velocity = velocity_from_direction(direction)
	if not velocity.is_zero_approx():
		_update_facing(velocity.normalized())
	move_and_slide()
	if movement_bounds.has_area():
		global_position = global_position.clamp(movement_bounds.position, movement_bounds.end)
	_set_animation(not velocity.is_zero_approx())


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
	for direction in WALK_TEXTURE_PATHS:
		frames.add_animation(direction)
		frames.set_animation_speed(direction, 8.0)
		frames.set_animation_loop(direction, true)
		var texture: Texture2D = load(String(WALK_TEXTURE_PATHS[direction])) as Texture2D
		if texture == null:
			push_error("Missing imported walk texture: %s" % WALK_TEXTURE_PATHS[direction])
			continue
		for frame_index in FRAME_COUNT:
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(Vector2(frame_index * FRAME_SIZE.x, 0), FRAME_SIZE)
			frames.add_frame(direction, frame)
	sprite.sprite_frames = frames


func _set_animation(moving: bool) -> void:
	if sprite.animation != facing:
		sprite.play(facing)
	if moving:
		sprite.speed_scale = 1.8 if running else 1.0
		sprite.play()
	else:
		sprite.pause()
		sprite.frame = 0


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


func _is_game_paused() -> bool:
	var session := get_node_or_null("/root/GameSession")
	return session != null and session.is_paused()
