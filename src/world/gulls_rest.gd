extends Node2D

@onready var status_label: Label = $HUD/Status
@onready var message_label: Label = $HUD/Message


func _ready() -> void:
	queue_redraw()
	for node in get_tree().get_nodes_in_group(&"coastal_landmark"):
		node.feedback.connect(_show_message)
	for node in get_tree().get_nodes_in_group(&"gulls_opponent"):
		node.feedback.connect(_show_message)
	for node in get_tree().get_nodes_in_group(&"gulls_exit"):
		node.feedback.connect(_show_message)
	_update_status()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("5b9aab"))
	draw_rect(Rect2(0, 0, 960, 86), Color("20333b"))
	draw_rect(Rect2(0, 355, 960, 185), Color("245b75"))
	draw_rect(Rect2(80, 145, 270, 170), Color("c49a69"))
	draw_rect(Rect2(450, 120, 330, 180), Color("7d5a45"))
	draw_line(Vector2(0, 336), Vector2(960, 336), Color("ead091"), 18.0)


func _update_status() -> void:
	var condition := "charted" if GameSession.angler.has_condition(&"high_tide") else "unknown"
	var entries := int(GameSession.angler.contests.get(&"gulls_rest_weekly", {}).get("entries", 0))
	status_label.text = "GULL'S REST  •  High tide: %s  •  Contest entries: %d  •  $%.2f" % [condition, entries, GameSession.inventory.money_cents / 100.0]


func _show_message(message: String) -> void:
	message_label.text = message
	_update_status()
