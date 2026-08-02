extends Node2D

@export var location_name := "INTERIOR"
@export var floor_color := Color("6b4a35")

@onready var status_label: Label = $HUD/Status
@onready var message_label: Label = $HUD/Message


func _ready() -> void:
	queue_redraw()
	$Exit.feedback.connect(_show_message)
	var bed = get_node_or_null("Bed")
	if bed != null:
		bed.feedback.connect(_show_message)
	var mabel = get_node_or_null("Mabel")
	if mabel != null:
		mabel.feedback.connect(_show_message)
	var frontier_table = get_node_or_null("FrontierTable")
	if frontier_table != null:
		frontier_table.feedback.connect(_show_message)
	var clerk = get_node_or_null("StoreClerk")
	if clerk != null:
		clerk.feedback.connect(_show_message)
	SaveService.save_status.connect(_show_message)
	status_label.text = "%s  •  E / A interacts  •  $%.2f" % [location_name, GameSession.inventory.money_cents / 100.0]


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), floor_color)
	draw_rect(Rect2(0, 0, 960, 72), Color("2f211b"))
	draw_rect(Rect2(36, 105, 888, 320), Color("2f211b"), false, 8.0)


func _show_message(message: String) -> void:
	message_label.text = message
