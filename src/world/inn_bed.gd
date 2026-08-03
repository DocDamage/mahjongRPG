extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-40, -18, 80, 36), Color("8c6550"))
	draw_rect(Rect2(-34, -14, 42, 18), Color("e7d9b5"))


func _on_interacted(_actor: Node2D) -> void:
	var advance := (24 * 60 - GameSession.minute_of_day) + 8 * 60
	GameSession.advance_minutes(advance)
	var save_result: Error = SaveService.autosave(&"resting")
	feedback.emit("You rest at the inn until morning.%s" % (" Autosaved." if save_result == OK else ""))
