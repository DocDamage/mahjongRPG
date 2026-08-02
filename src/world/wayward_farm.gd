extends Node2D

const FarmPlacementMenu = preload("res://src/farm/farm_placement_menu.gd")
const FarmPlot = preload("res://src/farm/farm_plot.gd")

@onready var status_label: Label = $HUD/Status
@onready var message_label: Label = $HUD/Message

var _placement_menu
var _mabel_button: Button


func _ready() -> void:
	queue_redraw()
	GameSession.time_advanced.connect(_update_status)
	GameSession.weather_changed.connect(_update_status)
	GameSession.weather_changed.connect(_redraw_for_weather)
	SaveService.save_status.connect(_show_message)
	for plot in get_tree().get_nodes_in_group(&"farm_plot"):
		plot.feedback.connect(_show_message)
	$Bonfire.feedback.connect(_show_message)
	$FishingSpot.feedback.connect(_show_message)
	$Horse.feedback.connect(_show_message)
	$AnimalPen.feedback.connect(_show_message)
	$MahjongTable.feedback.connect(_show_message)
	$ShippingCrate.feedback.connect(_show_message)
	$DustwardRoad.feedback.connect(_show_message)
	$WaywardHitch.feedback.connect(_show_message)
	$RiverbendPath.feedback.connect(_show_message)
	_create_placement_menu()
	_create_helper_action()
	_sync_field_plots()
	_update_status(GameSession.day, GameSession.minute_of_day)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("789c59"))
	draw_rect(Rect2(0, 0, 960, 86), Color("26321f"))
	draw_rect(Rect2(48, 138, 350, 306), Color("aa8150"))
	draw_rect(Rect2(62, 152, 322, 278), Color("6c4d32"), false, 4.0)
	draw_rect(Rect2(460, 126, 400, 154), Color("5a8cc4"))
	draw_rect(Rect2(460, 300, 400, 130), Color("d3ad6e"))
	draw_line(Vector2(398, 292), Vector2(460, 292), Color("d8c18b"), 18.0)
	for anchor in GameSession.farm.construction_anchors():
		var construction: Dictionary = GameSession.farm.construction_at(anchor)
		var definition: Dictionary = GameSession.farm.construction_definition(StringName(construction["id"]))
		var footprint: Vector2i = definition["footprint"]
		var color := Color(String(definition["color"]))
		draw_rect(Rect2(Vector2(112 + anchor.x * 100, 182 + anchor.y * 100), Vector2(36 + (footprint.x - 1) * 100, 36 + (footprint.y - 1) * 100)), color)
		draw_rect(Rect2(Vector2(112 + anchor.x * 100, 182 + anchor.y * 100), Vector2(36 + (footprint.x - 1) * 100, 36 + (footprint.y - 1) * 100)), Color("fff0bf"), false, 2.0)
	if GameSession.weather_id == &"rain":
		for index in 28:
			var x := float((index * 73) % 960)
			var y := float((index * 47) % 520)
			draw_line(Vector2(x, y), Vector2(x - 8, y + 18), Color(0.75, 0.88, 1.0, 0.65), 1.5)


func _update_status(_day: int, _minute_of_day: int) -> void:
	var hour := GameSession.minute_of_day / 60
	var minute := GameSession.minute_of_day % 60
	status_label.text = "WAYWARD FARM  •  Day %d  •  %02d:%02d  •  %s  •  $%.2f\nMove: WASD / Left Stick  •  Run: Shift / L3  •  Build: B / X  •  Fish: R/RT reel, F/LT release" % [GameSession.day, hour, minute, GameSession.weather_id.capitalize(), GameSession.inventory.money_cents / 100.0]


func _show_message(message: String) -> void:
	message_label.text = message


func _redraw_for_weather(_weather_id: StringName) -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"place_field"):
		if _placement_menu.is_open():
			_placement_menu.close()
		else:
			_placement_menu.open()
		get_viewport().set_input_as_handled()


func _create_placement_menu() -> void:
	_placement_menu = FarmPlacementMenu.new()
	_placement_menu.configure(GameSession.farm)
	_placement_menu.field_placed.connect(_ensure_field_plot)
	_placement_menu.construction_changed.connect(_sync_field_plots)
	_placement_menu.construction_changed.connect(queue_redraw)
	add_child(_placement_menu)


func _sync_field_plots() -> void:
	for plot in get_tree().get_nodes_in_group(&"farm_plot"):
		if not GameSession.farm.has_field(plot.grid_cell):
			plot.queue_free()
	for field_cell in GameSession.farm.field_cells():
		_ensure_field_plot(field_cell)


func _ensure_field_plot(cell: Vector2i) -> void:
	for plot in get_tree().get_nodes_in_group(&"farm_plot"):
		if plot.grid_cell == cell:
			return
	var plot := Area2D.new()
	plot.name = "FarmField_%d_%d" % [cell.x, cell.y]
	plot.position = Vector2(130 + cell.x * 100, 200 + cell.y * 100)
	plot.collision_layer = 2
	plot.collision_mask = 0
	plot.set_script(FarmPlot)
	plot.grid_cell = cell
	plot.add_to_group(&"farm_plot")
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 26.0
	collision.shape = shape
	plot.add_child(collision)
	plot.feedback.connect(_show_message)
	add_child(plot)
	queue_redraw()
	_show_message("Field placed. Plant a crop there when you are ready.")


func _create_helper_action() -> void:
	_mabel_button = Button.new()
	_mabel_button.position = Vector2(700, 100)
	_mabel_button.size = Vector2(228, 42)
	_mabel_button.pressed.connect(_ask_mabel_for_help)
	add_child(_mabel_button)
	_update_helper_action()
	GameSession.time_advanced.connect(func(_day: int, _minute: int) -> void: _update_helper_action())
	GameSession.quests.quest_completed.connect(func(_quest_id: StringName) -> void: _update_helper_action())


func _update_helper_action() -> void:
	if _mabel_button == null:
		return
	var assigned: bool = GameSession.helpers != null and GameSession.helpers.is_assigned(&"mabel")
	_mabel_button.visible = assigned
	_mabel_button.disabled = not assigned or int(GameSession.helpers.last_used_day.get(&"mabel", 0)) == GameSession.day
	_mabel_button.text = "Ask Mabel to water crops" if not _mabel_button.disabled else "Mabel helped today"


func _ask_mabel_for_help() -> void:
	var result: Dictionary = GameSession.helpers.activate(&"mabel", GameSession.farm, GameSession.day)
	if result.has("error"):
		_show_message("Mabel cannot help again until tomorrow.")
	else:
		_show_message("%s (%d crop%s watered.)" % [result.get("message", "Mabel helped."), int(result.get("watered", 0)), "" if int(result.get("watered", 0)) == 1 else "s"])
	_update_helper_action()
