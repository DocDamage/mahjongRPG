extends "res://src/interaction/world_interactable.gd"

const FishDefinition = preload("res://src/fishing/fish_definition.gd")
const FishCatalog = preload("res://src/fishing/fish_catalog.gd")
const FishingGearCatalog = preload("res://src/fishing/fishing_gear_catalog.gd")
const FishingOverlay = preload("res://src/fishing/fishing_overlay.gd")
const FishingSession = preload("res://src/fishing/fishing_session.gd")

signal feedback(message: String)

@export var shore_condition: StringName = &"river"
@export var rare_condition: StringName

var session
var _definitions: Array = []
var _gear_profile: Dictionary = {}
var _actor: Node2D
var _last_state := -1
var _last_tension_band := -1
var _catch_recorded := false
var _overlay


func _ready() -> void:
	interacted.connect(_on_interacted)
	_load_definitions()
	_gear_profile = GameSession.angler.gear_profile() if GameSession.angler != null else FishingGearCatalog.default_profile()
	_overlay = FishingOverlay.new()
	add_child(_overlay)
	queue_redraw()


func _exit_tree() -> void:
	if session != null:
		SaveService.release_save_restriction(&"fishing")


func _process(delta: float) -> void:
	if session == null:
		return
	if session.state == FishingSession.State.BITE and Input.is_action_just_pressed(&"interact"):
		session.hook_set()
	if session.state == FishingSession.State.STRUGGLE:
		var counter_direction := Input.get_axis(&"move_left", &"move_right")
		var rod_direction := Input.get_axis(&"fish_rod_left", &"fish_rod_right")
		var direction := rod_direction if absf(rod_direction) > 0.15 else counter_direction
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
	if session.configure_gear(_gear_profile) != OK:
		feedback.emit("Fishing gear data is invalid.")
		session = null
		return
	var condition := rare_condition if rare_condition.is_empty() or GameSession.angler.has_condition(rare_condition) else &""
	var result: int = session.cast(_definitions, hour, GameSession.weather_id, shore_condition, condition)
	if result != OK:
		session = null
		feedback.emit("Nothing is biting under these conditions.")
		return
	_actor = actor
	_actor.set_physics_process(false)
	SaveService.request_save_restriction(&"fishing")
	_last_state = -1
	_last_tension_band = -1
	_catch_recorded = false
	_update_feedback()


func _finish() -> void:
	if _actor != null:
		_actor.set_physics_process(true)
	_actor = null
	SaveService.release_save_restriction(&"fishing")
	session = null
	_overlay.show_session(null)
	_last_state = -1
	_last_tension_band = -1
	_catch_recorded = false
	feedback.emit("Fishing finished.")


func _update_feedback() -> void:
	if session == null:
		return
	_overlay.refresh(session)
	if session.state == FishingSession.State.STRUGGLE:
		var pull := "right" if session.target_direction > 0.0 else "left"
		_pulse_tension(session.tension)
		feedback.emit("Fish pulling %s • tension %d%% • counter left stick/keys, rod right stick • reel %s, release %s" % [pull, int(session.tension * 100.0), _binding(&"fish_reel"), _binding(&"fish_release")])
		return
	if _last_state == session.state:
		return
	_last_state = session.state
	match session.state:
		FishingSession.State.CAST, FishingSession.State.WAIT:
			feedback.emit("Cast out. Wait for a bite.")
		FishingSession.State.BITE:
			AudioService.play_catalog_event(&"fishing_bite")
			_pulse(0.3, 0.9, 0.25)
			feedback.emit("Bite! Press %s to set the hook." % _binding(&"interact"))
		FishingSession.State.CATCH:
			feedback.emit("Caught %s ($%.2f)! Press %s to view it." % [session.fish.id.capitalize(), session.fish.sell_value_cents / 100.0, _binding(&"interact")])
		FishingSession.State.ESCAPE:
			feedback.emit("The fish escaped. Press %s to continue." % _binding(&"interact"))
		FishingSession.State.PRESENTATION:
			feedback.emit("Catch presentation complete. Press %s to return." % _binding(&"interact"))


func _load_definitions() -> void:
	_definitions = FishCatalog.definitions()


func _record_catch_if_needed() -> void:
	if _catch_recorded or session == null or session.state != FishingSession.State.CATCH or session.fish == null:
		return
	if GameSession.angler.record_catch(session.fish.id, session.fish.sell_value_cents, GameSession.inventory) == OK:
		_catch_recorded = true


func _binding(action: StringName) -> String:
	var input_service = get_node_or_null("/root/InputService")
	return input_service.prompt_binding_text(action, input_service.using_controller) if input_service != null else String(action).capitalize()


func _pulse_tension(tension: float) -> void:
	var band := int(clampf(tension, 0.0, 0.999) * 4.0)
	if band == _last_tension_band:
		return
	_last_tension_band = band
	AudioService.play_catalog_event(&"fishing_tension")
	_pulse(0.15 + band * 0.1, 0.2 + band * 0.15, 0.12)


func _pulse(weak: float, strong: float, duration: float) -> void:
	var input_service = get_node_or_null("/root/InputService")
	if input_service != null:
		input_service.pulse_active_controller(weak, strong, duration)
