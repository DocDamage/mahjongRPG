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
	status_label.text = "WAYWARD FARM  •  Day %d  •  %02d:%02d  •  %s\nMove: WASD / Left Stick  •  Run: Shift / L3" % [GameSession.day, hour, minute, GameSession.weather_id.capitalize()]


func _show_message(message: String) -> void:
	message_label.text = message
