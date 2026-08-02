extends "res://src/interaction/world_interactable.gd"

const FishDefinition = preload("res://src/fishing/fish_definition.gd")
const FishingOverlay = preload("res://src/fishing/fishing_overlay.gd")
const FishingSession = preload("res://src/fishing/fishing_session.gd")

signal feedback(message: String)

var session
var _definitions: Array = []
var _actor: Node2D
var _last_state := -1
var _catch_recorded := false
var _overlay


func _ready() -> void:
	interacted.connect(_on_interacted)
	_load_definitions()
	_overlay = FishingOverlay.new()
	add_child(_overlay)
	queue_redraw()


func _process(delta: float) -> void:
	if session == null:
		return
	if session.state == FishingSession.State.BITE and Input.is_action_just_pressed(&"interact"):
		session.hook_set()
	if session.state == FishingSession.State.STRUGGLE:
		var direction := Input.get_axis(&"move_left", &"move_right")
		session.apply_struggle_input(direction, Input.is_action_pressed(&"fish_reel"), Input.is_action_pressed(&"fish_release"), delta)
	session.tick(delta)
	_record_catch_if_needed()
	if session.state in [FishingSession.State.CATCH, FishingSession.State.ESCAPE] and Input.is_action_just_pressed(&"interact"):
		session.present_result()
	elif session.state == FishingSession.State.PRESENTATION and Input.is_action_just_pressed(&"interact"):
		session.cleanup()
		_finish()
	_update_feedback()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 30.0, Color("234960"))
	draw_circle(Vector2.ZERO, 18.0, Color("67b8d1"), false, 2.0)
	draw_line(Vector2(-15, -15), Vector2(15, 15), Color("d8c18b"), 4.0)


func _on_interacted(actor: Node2D) -> void:
	if session == null:
		_begin(actor)
	elif session.state == FishingSession.State.BITE:
		session.hook_set()
	elif session.state in [FishingSession.State.CATCH, FishingSession.State.ESCAPE]:
		session.present_result()
	elif session.state == FishingSession.State.PRESENTATION:
		session.cleanup()
		_finish()
	_update_feedback()


func _begin(actor: Node2D) -> void:
	if _definitions.is_empty():
		feedback.emit("No fish data is available here.")
		return
	var hour := GameSession.minute_of_day / 60
	session = FishingSession.new(GameSession.seed + GameSession.day * 1000 + GameSession.minute_of_day)
	var result: int = session.cast(_definitions, hour, GameSession.weather_id)
	if result != OK:
		session = null
		feedback.emit("Nothing is biting under these conditions.")
		return
	_actor = actor
	_actor.set_physics_process(false)
	_last_state = -1
	_catch_recorded = false
	_update_feedback()


func _finish() -> void:
	if _actor != null:
		_actor.set_physics_process(true)
	_actor = null
	session = null
	_overlay.show_session(null)
	_last_state = -1
	_catch_recorded = false
	feedback.emit("Fishing finished.")


func _update_feedback() -> void:
	if session == null:
		return
	_overlay.refresh(session)
	if session.state == FishingSession.State.STRUGGLE:
		var pull := "right" if session.target_direction > 0.0 else "left"
		feedback.emit("Fish pulling %s • tension %d%% • reel R/RT, release F/LT" % [pull, int(session.tension * 100.0)])
		return
	if _last_state == session.state:
		return
	_last_state = session.state
	match session.state:
		FishingSession.State.CAST, FishingSession.State.WAIT:
			feedback.emit("Cast out. Wait for a bite.")
		FishingSession.State.BITE:
			feedback.emit("Bite! Press E / A to set the hook.")
		FishingSession.State.CATCH:
			feedback.emit("Caught %s ($%.2f)! Press E / A to view it." % [session.fish.id.capitalize(), session.fish.sell_value_cents / 100.0])
		FishingSession.State.ESCAPE:
			feedback.emit("The fish escaped. Press E / A to continue.")
		FishingSession.State.PRESENTATION:
			feedback.emit("Catch presentation complete. Press E / A to return.")


func _load_definitions() -> void:
	var file := FileAccess.open("res://data/fish/vertical_slice_fish.json", FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var fish_value: Variant = parsed.get("fish", [])
	if fish_value is Array:
		for fish_data_value in fish_value:
			if fish_data_value is Dictionary:
				_definitions.append(FishDefinition.new(fish_data_value))


func _record_catch_if_needed() -> void:
	if _catch_recorded or session == null or session.state != FishingSession.State.CATCH or session.fish == null:
		return
	if GameSession.inventory.record_fish(session.fish.id, session.fish.sell_value_cents) == OK:
		_catch_recorded = true
