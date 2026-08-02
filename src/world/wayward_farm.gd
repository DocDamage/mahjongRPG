extends Node2D

@onready var status_label: Label = $HUD/Status
@onready var message_label: Label = $HUD/Message


func _ready() -> void:
	queue_redraw()
	GameSession.time_advanced.connect(_update_status)
	GameSession.weather_changed.connect(_update_status)
	for plot in get_tree().get_nodes_in_group(&"farm_plot"):
		plot.feedback.connect(_show_message)
	$Bonfire.feedback.connect(_show_message)
	$FishingSpot.feedback.connect(_show_message)
	$Horse.feedback.connect(_show_message)
	$MahjongTable.feedback.connect(_show_message)
	$ShippingCrate.feedback.connect(_show_message)
	$DustwardRoad.feedback.connect(_show_message)
	$WaywardHitch.feedback.connect(_show_message)
	_update_status(GameSession.day, GameSession.minute_of_day)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("789c59"))
	draw_rect(Rect2(0, 0, 960, 86), Color("26321f"))
	draw_rect(Rect2(48, 138, 350, 306), Color("aa8150"))
	draw_rect(Rect2(62, 152, 322, 278), Color("6c4d32"), false, 4.0)
	draw_rect(Rect2(460, 126, 400, 154), Color("5a8cc4"))
	draw_rect(Rect2(460, 300, 400, 130), Color("d3ad6e"))
	draw_line(Vector2(398, 292), Vector2(460, 292), Color("d8c18b"), 18.0)


func _update_status(_day: int, _minute_of_day: int) -> void:
	var hour := GameSession.minute_of_day / 60
	var minute := GameSession.minute_of_day % 60
	status_label.text = "WAYWARD FARM  •  Day %d  •  %02d:%02d  •  %s  •  $%.2f\nMove: WASD / Left Stick  •  Run: Shift / L3  •  Fish: R/RT reel, F/LT release" % [GameSession.day, hour, minute, GameSession.weather_id.capitalize(), GameSession.inventory.money_cents / 100.0]


func _show_message(message: String) -> void:
	message_label.text = message


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"save_game"):
		var result := SaveService.save(SaveService.SLOT_AUTOSAVE, GameSession.snapshot())
		_show_message("Game saved." if result == OK else "Save failed.")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"load_game"):
		var document := SaveService.load_save(SaveService.SLOT_AUTOSAVE)
		if document.has("payload") and GameSession.restore(document["payload"]) == OK:
			_show_message("Game loaded.")
		else:
			_show_message("No valid autosave found.")
		get_viewport().set_input_as_handled()
