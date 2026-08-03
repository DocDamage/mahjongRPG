extends Node2D

const CommunityArcPanel = preload("res://src/world/community_arc_panel.gd")

@onready var status_label: Label = $HUD/Status
@onready var message_label: Label = $HUD/Message


func _ready() -> void:
	queue_redraw()
	for node in get_tree().get_nodes_in_group(&"desert_landmark"):
		node.feedback.connect(_show_message)
	for node in get_tree().get_nodes_in_group(&"red_opponent"):
		node.feedback.connect(_show_message)
	for node in get_tree().get_nodes_in_group(&"red_exit"):
		node.feedback.connect(_show_message)
	$RedBonfire.feedback.connect(_show_message)
	$RedHitch.feedback.connect(_show_message)
	_add_community_panel()
	_update_status()


func _add_community_panel() -> void:
	var panel := CommunityArcPanel.new()
	panel.configure(&"red_testament")
	add_child(panel)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("bd7542"))
	draw_rect(Rect2(0, 0, 960, 86), Color("3b2421"))
	draw_rect(Rect2(80, 130, 270, 180), Color("7e402d"))
	draw_rect(Rect2(480, 125, 320, 190), Color("9d5836"))
	draw_line(Vector2(0, 360), Vector2(960, 360), Color("d9ac66"), 22.0)


func _update_status() -> void:
	var pass_state := "charted" if GameSession.desert.route_survived(&"red_testament_windward_pass") else "weather-gated"
	var rule := "recovered" if GameSession.evidence.has(&"texas_king_counter_deed") else "unrecovered"
	status_label.text = "RED TESTAMENT  •  Windward Pass: %s  •  Counter-rule clue: %s  •  Weather: %s" % [pass_state, rule, String(GameSession.weather_id).replace("_", " ")]


func _show_message(message: String) -> void:
	message_label.text = message
	_update_status()
