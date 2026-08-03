extends Node2D

const CommunityArcPanel = preload("res://src/world/community_arc_panel.gd")

@onready var status_label: Label = $HUD/Status
@onready var message_label: Label = $HUD/Message


func _ready() -> void:
	queue_redraw()
	for landmark in get_tree().get_nodes_in_group(&"civic_landmark"):
		landmark.feedback.connect(_show_message)
	for landmark in get_tree().get_nodes_in_group(&"saints_trade"):
		landmark.feedback.connect(_show_message)
	for opponent in get_tree().get_nodes_in_group(&"saints_opponent"):
		opponent.feedback.connect(_show_message)
	for exit_node in get_tree().get_nodes_in_group(&"saints_exit"):
		exit_node.feedback.connect(_show_message)
	_add_community_panel()
	_update_status()


func _add_community_panel() -> void:
	var panel := CommunityArcPanel.new()
	panel.configure(&"saints_landing")
	add_child(panel)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("66879a"))
	draw_rect(Rect2(0, 0, 960, 86), Color("26313a"))
	draw_rect(Rect2(80, 140, 265, 205), Color("8a6654"))
	draw_rect(Rect2(420, 130, 360, 125), Color("c4aa80"))
	draw_rect(Rect2(520, 300, 300, 125), Color("795d4b"))
	draw_line(Vector2(0, 435), Vector2(960, 435), Color("d9d0b2"), 22.0)


func _update_status() -> void:
	var dispute := "settled" if GameSession.properties.is_resolved(&"saints_landing_depot") else "open"
	status_label.text = "SAINT'S LANDING  •  Depot dispute: %s  •  Hall practice: %d/5  •  $%.2f" % [dispute, GameSession.brands.hall_stage, GameSession.inventory.money_cents / 100.0]


func _show_message(message: String) -> void:
	message_label.text = message
	_update_status()
