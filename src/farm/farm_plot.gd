extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

@export var grid_cell := Vector2i.ZERO
const CropPicker = preload("res://src/farm/crop_picker.gd")


func _ready() -> void:
	interacted.connect(_on_interacted)
	GameSession.farm.place_field(grid_cell)
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
		_open_crop_picker()
	elif crop.state == crop.State.READY:
		var harvest: Dictionary = GameSession.farm.harvest(grid_cell)
		var crop_id := StringName(harvest.get("crop_id", "beans"))
		if not harvest.has("error") and GameSession.inventory.add_item(StringName("crop_%s" % crop_id), int(harvest.get("quantity", 1))) == OK:
			feedback.emit("Harvested %s and added it to inventory." % crop_id.capitalize())
		else:
			feedback.emit("Harvest failed.")
	elif crop.state in [crop.State.DEAD, crop.State.HARVESTED]:
		feedback.emit("This plot needs a fresh seed.")
	else:
		GameSession.farm.water(grid_cell, GameSession.day)
		feedback.emit("Watered %s." % String(crop.definition.id).capitalize())
	queue_redraw()


func _on_time_advanced(_day: int, _minute: int) -> void:
	GameSession.farm.advance_to_day(GameSession.day)
	queue_redraw()


func _open_crop_picker() -> void:
	if get_tree().get_first_node_in_group(&"crop_picker") != null:
		return
	var picker := CropPicker.new()
	picker.configure(GameSession.farm, grid_cell)
	picker.add_to_group(&"crop_picker")
	picker.crop_selected.connect(_on_crop_selected)
	get_tree().root.add_child(picker)
	picker.open()


func _on_crop_selected(crop_id: StringName) -> void:
	feedback.emit("Planted %s. Water it before resting." % String(crop_id).capitalize())
	queue_redraw()
