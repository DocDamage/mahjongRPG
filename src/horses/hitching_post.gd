extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

@export var post_id: StringName
@export var destination_post_id: StringName
@export_file("*.tscn") var destination_scene: String


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-5, -30, 10, 60), Color("56351f"))
	draw_circle(Vector2(0, -28), 10.0, Color("8e673a"))
	draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 16, Color("ded2a4"), 2.0)


func _on_interacted(_actor: Node2D) -> void:
	if post_id.is_empty():
		feedback.emit("This hitching post has no route.")
		return
	GameSession.horse.discover(post_id)
	if not GameSession.horse.mounted:
		feedback.emit("Discovered %s hitching post. Mount your horse to fast travel." % post_id.capitalize())
		return
	if destination_post_id.is_empty() or destination_scene.is_empty() or not GameSession.horse.can_fast_travel(destination_post_id):
		feedback.emit("Ride to and discover the destination hitching post first.")
		return
	if SceneRouter.change_scene(destination_scene) != OK:
		feedback.emit("The trail is unavailable.")
