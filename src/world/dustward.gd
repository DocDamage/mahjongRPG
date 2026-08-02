extends Node2D

@onready var status_label: Label = $HUD/Status
@onready var message_label: Label = $HUD/Message


func _ready() -> void:
	queue_redraw()
	$FarmRoad.feedback.connect(_show_message)
	$Horse.feedback.connect(_show_message)
	$DustwardHitch.feedback.connect(_show_message)
	$Mabel.feedback.connect(_show_message)
	GameSession.weather_changed.connect(_on_weather_changed)
	for opponent in get_tree().get_nodes_in_group(&"dustward_opponent"):
		opponent.feedback.connect(_show_message)
	_update_status()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("b98450"))
	draw_rect(Rect2(0, 0, 960, 90), Color("32261f"))
	draw_rect(Rect2(70, 145, 245, 220), Color("79503a"))
	draw_rect(Rect2(360, 130, 220, 250), Color("4f3b33"))
	draw_rect(Rect2(625, 155, 245, 205), Color("79503a"))
	draw_line(Vector2(0, 420), Vector2(960, 420), Color("dfbb79"), 22.0)
	if GameSession.weather_id == &"rain":
		for index in 28:
			var x := float((index * 83) % 960)
			var y := float((index * 41) % 520)
			draw_line(Vector2(x, y), Vector2(x - 8, y + 18), Color(0.75, 0.88, 1.0, 0.65), 1.5)


func _update_status() -> void:
	var quest_status := "First Lantern restored" if GameSession.quests.completed.has(&"first_lantern") else "Speak with Mabel at Six Brands Hall"
	status_label.text = "DUSTWARD  •  Three Trail Rules opponents await  •  $%.2f\n%s" % [GameSession.inventory.money_cents / 100.0, quest_status]


func _show_message(message: String) -> void:
	message_label.text = message


func _on_weather_changed(_weather_id: StringName) -> void:
	_update_status()
	queue_redraw()
