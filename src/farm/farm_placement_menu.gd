extends CanvasLayer

signal field_placed(cell: Vector2i)

const PAUSE_REASON := &"farm_placement"

var farm
var _shade: ColorRect
var _message: Label
var _first_button: Button


func configure(next_farm) -> void:
	farm = next_farm


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _shade != null and _shade.visible


func open() -> void:
	if _shade == null:
		return
	var session = get_node_or_null("/root/GameSession")
	if session != null:
		session.request_pause(PAUSE_REASON)
	_refresh_buttons()
	_shade.visible = true
	if _first_button != null:
		_first_button.grab_focus()


func close() -> void:
	if _shade == null:
		return
	_shade.visible = false
	var session = get_node_or_null("/root/GameSession")
	if session != null:
		session.release_pause(PAUSE_REASON)


func _build() -> void:
	_shade = ColorRect.new()
	_shade.color = Color(0.05, 0.035, 0.02, 0.78)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(250, 96)
	panel.size = Vector2(460, 350)
	_shade.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	var title := Label.new()
	title.text = "PLACE A FARM FIELD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	_message = Label.new()
	_message.text = "Choose an open grid cell. Built, blocked, and path cells remain unavailable."
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_message)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(grid)
	for row in 3:
		for column in 3:
			_add_cell_button(grid, Vector2i(column, row))
	var close_button := Button.new()
	close_button.text = "Cancel"
	close_button.custom_minimum_size = Vector2(0, 36)
	close_button.pressed.connect(close)
	content.add_child(close_button)
	_shade.visible = false


func _add_cell_button(grid: GridContainer, cell: Vector2i) -> void:
	var button := Button.new()
	button.name = "Cell_%d_%d" % [cell.x, cell.y]
	button.custom_minimum_size = Vector2(118, 48)
	button.pressed.connect(_place_field.bind(cell))
	grid.add_child(button)
	if _first_button == null:
		_first_button = button


func _refresh_buttons() -> void:
	_first_button = null
	for child in _shade.find_child("GridContainer", true, false).get_children():
		var parts := String(child.name).trim_prefix("Cell_").split("_")
		var cell := Vector2i(int(parts[0]), int(parts[1]))
		var placement: Error = farm.can_place_field(cell)
		child.disabled = placement != OK
		child.text = "Place %d,%d" % [cell.x + 1, cell.y + 1] if placement == OK else "Unavailable"
		if placement == OK and _first_button == null:
			_first_button = child as Button


func _place_field(cell: Vector2i) -> void:
	var result: Error = farm.place_field(cell)
	if result != OK:
		_message.text = "That cell cannot hold a field. Choose another open cell."
		_refresh_buttons()
		return
	field_placed.emit(cell)
	close()
