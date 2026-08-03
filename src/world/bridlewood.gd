extends Node2D

const CommunityArcPanel = preload("res://src/world/community_arc_panel.gd")

@onready var status_label: Label = $HUD/Status
@onready var message_label: Label = $HUD/Message
var _ranch_help_button: Button


func _ready() -> void:
	queue_redraw()
	for landmark in get_tree().get_nodes_in_group(&"ranch_landmark"):
		landmark.feedback.connect(_show_message)
	for opponent in get_tree().get_nodes_in_group(&"bridlewood_opponent"):
		opponent.feedback.connect(_show_message)
	$ReturnRoad.feedback.connect(_show_message)
	$BridlewoodHitch.feedback.connect(_show_message)
	$SaintsRoad.feedback.connect(_show_message)
	SaveService.save_status.connect(_show_message)
	_create_ranch_helper_action()
	_add_community_panel()
	_update_status()


func _add_community_panel() -> void:
	var panel := CommunityArcPanel.new()
	panel.configure(&"bridlewood")
	add_child(panel)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("63834c"))
	draw_rect(Rect2(0, 0, 960, 86), Color("26321f"))
	draw_rect(Rect2(85, 142, 280, 185), Color("91603f"))
	draw_rect(Rect2(470, 132, 370, 110), Color("b48955"))
	draw_rect(Rect2(470, 300, 380, 125), Color("794a34"))
	draw_line(Vector2(0, 438), Vector2(960, 438), Color("d8c18b"), 20.0)


func _update_status() -> void:
	var order_state := "fulfilled" if GameSession.regions.fulfilled_orders.has(&"bridlewood_first_harvest") else "open"
	var shortcut_state := "unlocked" if GameSession.regions.has_shortcut(&"bridlewood_wayward_hitch") else "repair the bridge"
	status_label.text = "BRIDLEWOOD RANCH  •  Crop order: %s  •  Shortcut: %s  •  $%.2f" % [order_state, shortcut_state, GameSession.inventory.money_cents / 100.0]


func _show_message(message: String) -> void:
	message_label.text = message
	_update_status()


func _create_ranch_helper_action() -> void:
	_ranch_help_button = Button.new()
	_ranch_help_button.position = Vector2(710, 94)
	_ranch_help_button.size = Vector2(220, 36)
	_ranch_help_button.pressed.connect(_ask_ranch_hand_for_help)
	add_child(_ranch_help_button)
	_update_ranch_helper_action()


func _ask_ranch_hand_for_help() -> void:
	var result: Dictionary = GameSession.helpers.activate(&"bridlewood_hand", GameSession.farm, GameSession.day, GameSession.animals)
	_show_message(String(result.get("message", "The ranch hand cannot help again until tomorrow.")))
	_update_ranch_helper_action()


func _update_ranch_helper_action() -> void:
	var assigned: bool = GameSession.helpers.is_assigned(&"bridlewood_hand")
	_ranch_help_button.visible = assigned
	_ranch_help_button.disabled = not assigned or int(GameSession.helpers.last_used_day.get(&"bridlewood_hand", 0)) == GameSession.day
	_ranch_help_button.text = "Ask ranch hand to feed animals" if not _ranch_help_button.disabled else "Ranch hand helped today"
