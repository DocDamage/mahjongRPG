extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

@export_file("*.tscn") var destination_scene: String
@export var required_hall_milestone: StringName

var _transition_requested := false


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-24, -32, 48, 64), Color("3c2b1b"))
	draw_rect(Rect2(-24, -32, 48, 64), Color("d9c18a"), false, 3.0)
	draw_line(Vector2(-12, 0), Vector2(12, 0), Color("d9c18a"), 3.0)


func _on_interacted(_actor: Node2D) -> void:
	if _transition_requested:
		return
	if not required_hall_milestone.is_empty() and not GameSession.quests.hall_milestones.has(required_hall_milestone):
		feedback.emit("Access is disputed until the Six Brands Hall restores %s." % required_hall_milestone.capitalize())
		return
	if destination_scene.is_empty():
		feedback.emit("That route is closed for now.")
		return
	_transition_requested = true
	if SceneRouter.change_scene(destination_scene) != OK:
		_transition_requested = false
		feedback.emit("That route is closed for now.")
