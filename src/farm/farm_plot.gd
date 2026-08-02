extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

@export var grid_cell := Vector2i.ZERO
@export var starter_crop: StringName = &"beans"


func _ready() -> void:
	interacted.connect(_on_interacted)
	GameSession.time_advanced.connect(_on_time_advanced)
	queue_redraw()


func _draw() -> void:
	var color := Color("5f422b")
	var crop = GameSession.farm.crop_at(grid_cell)
	if crop != null:
		match crop.state:
			crop.State.WATERED, crop.State.GROWING:
				color = Color("4e7b3c")
			crop.State.READY:
				color = Color("d4b04d")
			crop.State.WILTED:
				color = Color("82653d")
			crop.State.DEAD:
				color = Color("3c3028")
	draw_rect(Rect2(-18, -18, 36, 36), color)
	draw_rect(Rect2(-18, -18, 36, 36), Color("d9c18a"), false, 2.0)


func _on_interacted(_actor: Node2D) -> void:
	var crop = GameSession.farm.crop_at(grid_cell)
	if crop == null:
		GameSession.farm.plant(grid_cell, starter_crop, GameSession.day)
		feedback.emit("Planted %s. Water it before resting." % starter_crop.capitalize())
	elif crop.state == crop.State.READY:
		var harvest: Dictionary = GameSession.farm.harvest(grid_cell)
		feedback.emit("Harvested %s." % harvest.get("crop_id", starter_crop))
	elif crop.state in [crop.State.DEAD, crop.State.HARVESTED]:
		feedback.emit("This plot needs a fresh seed.")
	else:
		GameSession.farm.water(grid_cell, GameSession.day)
		feedback.emit("Watered %s." % starter_crop.capitalize())
	queue_redraw()


func _on_time_advanced(_day: int, _minute: int) -> void:
	GameSession.farm.advance_to_day(GameSession.day)
	queue_redraw()
