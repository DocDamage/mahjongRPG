extends CanvasLayer

signal field_placed(cell: Vector2i)
signal construction_changed()

const PAUSE_REASON := &"farm_placement"

var farm
var _shade: ColorRect
var _message: Label
var _first_button: Button
var _mode_picker: OptionButton
var _type_picker: OptionButton
var _relocation_origin := Vector2i(-1, -1)


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
	_relocation_origin = Vector2i(-1, -1)
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
	panel.position = Vector2(70, 20)
	panel.size = Vector2(820, 500)
	_shade.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	var title := Label.new()
	title.text = "FARM CONSTRUCTION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	_message = Label.new()
	_message.text = "Build, relocate, or remove fields and structures. Routes and blocked ground stay protected."
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_message)
	_mode_picker = OptionButton.new()
	for mode in ["Build", "Relocate", "Remove"]:
		_mode_picker.add_item(mode)
	_mode_picker.item_selected.connect(_on_placement_changed)
	content.add_child(_mode_picker)
	_type_picker = OptionButton.new()
	_type_picker.add_item("Field")
	for construction_id in farm.construction_ids():
		var definition: Dictionary = farm.construction_definition(construction_id)
		_type_picker.add_item(String(definition["name"]))
		_type_picker.set_item_metadata(_type_picker.item_count - 1, construction_id)
	_type_picker.item_selected.connect(_on_placement_changed)
	content.add_child(_type_picker)
	var grid := GridContainer.new()
	grid.columns = farm.grid.bounds.size.x
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(grid)
	for row in farm.grid.bounds.size.y:
		for column in farm.grid.bounds.size.x:
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
	button.custom_minimum_size = Vector2(98, 42)
	button.pressed.connect(_select_cell.bind(cell))
	grid.add_child(button)
	if _first_button == null:
		_first_button = button


func _refresh_buttons() -> void:
	_first_button = null
	for child in _shade.find_child("GridContainer", true, false).get_children():
		var parts := String(child.name).trim_prefix("Cell_").split("_")
		var cell := Vector2i(int(parts[0]), int(parts[1]))
		var placement := _cell_result(cell)
		child.disabled = placement != OK
		child.text = _cell_label(cell, placement == OK)
		if not child.disabled and _first_button == null:
			_first_button = child as Button


func _select_cell(cell: Vector2i) -> void:
	var result: Error
	if _mode_picker.selected == 0:
		result = farm.place_field(cell) if _type_picker.selected == 0 else farm.place_construction(_selected_construction_id(), cell)
		if result == OK:
			if _type_picker.selected == 0:
				field_placed.emit(cell)
			else:
				construction_changed.emit()
			close()
			return
	elif _mode_picker.selected == 1:
		if _relocation_origin.x < 0:
			if farm.has_field(cell) or not farm.construction_at(cell).is_empty():
				_relocation_origin = cell
				_message.text = "Choose a safe destination. Cropped fields cannot be moved."
				_refresh_buttons()
				return
			result = ERR_DOES_NOT_EXIST
		else:
			var construction: Dictionary = farm.construction_at(_relocation_origin)
			result = farm.relocate_field(_relocation_origin, cell) if construction.is_empty() else farm.relocate_construction(Vector2i(construction["anchor"]), cell)
			if result == OK:
				field_placed.emit(cell)
				construction_changed.emit()
				close()
				return
	else:
		var construction: Dictionary = farm.construction_at(cell)
		result = farm.remove_field(cell) if construction.is_empty() else farm.remove_construction(Vector2i(construction["anchor"]))
		if result == OK:
			construction_changed.emit()
			_refresh_buttons()
			return
	_message.text = "That move would overlap a field, structure, blocked ground, or a protected route."
	_refresh_buttons()


func _cell_result(cell: Vector2i) -> Error:
	if _mode_picker.selected == 0:
		return farm.can_place_field(cell) if _type_picker.selected == 0 else farm.can_place_construction(_selected_construction_id(), cell)
	if _mode_picker.selected == 1:
		if _relocation_origin.x < 0:
			return OK if farm.has_field(cell) or not farm.construction_at(cell).is_empty() else ERR_DOES_NOT_EXIST
		var construction: Dictionary = farm.construction_at(_relocation_origin)
		return farm.can_place_field(cell) if construction.is_empty() else farm.can_relocate_construction(Vector2i(construction["anchor"]), cell)
	var construction: Dictionary = farm.construction_at(cell)
	return OK if farm.has_field(cell) or not construction.is_empty() else ERR_DOES_NOT_EXIST


func _cell_label(cell: Vector2i, available: bool) -> String:
	if not available:
		return "Unavailable"
	if _mode_picker.selected == 1 and _relocation_origin.x < 0:
		return "Select %d,%d" % [cell.x + 1, cell.y + 1]
	return "%s %d,%d" % ["Remove" if _mode_picker.selected == 2 else "Place", cell.x + 1, cell.y + 1]


func _selected_construction_id() -> StringName:
	return StringName(_type_picker.get_item_metadata(_type_picker.selected))


func _on_placement_changed(_index: int) -> void:
	_relocation_origin = Vector2i(-1, -1)
	_refresh_buttons()
