extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 24.0, Color("513427"))
	draw_circle(Vector2(0, -4), 14.0, Color("dd6d2d"))
	draw_circle(Vector2(0, -8), 7.0, Color("ffd26d"))


func _on_interacted(_actor: Node2D) -> void:
	var target_minute := 8 * 60
	var advance := (24 * 60 - GameSession.minute_of_day) + target_minute
	GameSession.advance_minutes(advance)
	feedback.emit("Rested until morning. Crops progressed overnight.")
