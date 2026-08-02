extends Node2D

@onready var status_label: Label = $HUD/Status
@onready var message_label: Label = $HUD/Message


func _ready() -> void:
	queue_redraw()
	$FarmRoad.feedback.connect(_show_message)
	$FishingSpot.feedback.connect(_show_message)
	GameSession.weather_changed.connect(_on_weather_changed)
	_update_status()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("6d9356"))
	draw_rect(Rect2(0, 0, 960, 95), Color("26321f"))
	draw_rect(Rect2(0, 260, 960, 220), Color("2e75a2"))
	draw_line(Vector2(0, 260), Vector2(960, 260), Color("b8d8e6"), 4.0)
	draw_rect(Rect2(65, 145, 330, 95), Color("bd915a"))
	if GameSession.weather_id == &"rain":
		for index in 28:
			var x := float((index * 89) % 960)
			var y := float((index * 43) % 520)
			draw_line(Vector2(x, y), Vector2(x - 8, y + 18), Color(0.75, 0.88, 1.0, 0.65), 1.5)


func _update_status() -> void:
	status_label.text = "RIVERBEND  •  %s  •  Fish use the time and weather conditions shown here." % GameSession.weather_id.capitalize()


func _show_message(message: String) -> void:
	message_label.text = message


func _on_weather_changed(_weather_id: StringName) -> void:
	_update_status()
	queue_redraw()
