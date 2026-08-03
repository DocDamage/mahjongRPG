extends PanelContainer

signal crop_selected(crop_id: StringName)
signal cancelled()

var _farm
var _cell := Vector2i.ZERO


func configure(farm, cell: Vector2i) -> void:
	_farm = farm
	_cell = cell


func open() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	position = Vector2(-250, -250)
	size = Vector2(500, 500)
	_build()
	GameSession.request_pause(&"crop_picker")
	var first_button := find_child("Beans", true, false)
	if first_button != null:
		first_button.grab_focus()


func _exit_tree() -> void:
	GameSession.release_pause(&"crop_picker")


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	var title := Label.new()
	title.text = "CHOOSE A CROP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	var description := Label.new()
	description.text = "Choose an unlocked crop. Its maturity time and daily watering determine harvest quality."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)
	var crop_list := ScrollContainer.new()
	crop_list.custom_minimum_size = Vector2(0, 280)
	content.add_child(crop_list)
	var crop_buttons := VBoxContainer.new()
	crop_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crop_list.add_child(crop_buttons)
	for crop_id in _active_crop_ids():
		var button := Button.new()
		button.name = String(crop_id).capitalize()
		button.text = "%s — %d days • seed value $%.2f • water daily for silver/gold quality" % [String(crop_id).capitalize(), _maturity_days(crop_id), _seed_cost(crop_id) / 100.0]
		button.custom_minimum_size = Vector2(0, 36)
		button.pressed.connect(_select.bind(crop_id))
		crop_buttons.add_child(button)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_cancel)
	content.add_child(cancel)


func _maturity_days(crop_id: StringName) -> int:
	var definition = _farm.definition(crop_id) if _farm != null and _farm.has_method("definition") else null
	return int(definition.days_to_mature) if definition != null else 0


func _seed_cost(crop_id: StringName) -> int:
	var definition = _farm.definition(crop_id) if _farm != null and _farm.has_method("definition") else null
	return int(definition.seed_cost_cents) if definition != null else 0


func _active_crop_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	if _farm == null:
		return ids
	for crop_id_value in _farm._definitions:
		var crop_id := StringName(crop_id_value)
		var definition = _farm.definition(crop_id)
		if definition != null and definition.available_in_slice:
			ids.append(crop_id)
	ids.sort()
	return ids


func _select(crop_id: StringName) -> void:
	if _farm == null or _farm.plant(_cell, crop_id, GameSession.day) != OK:
		return
	crop_selected.emit(crop_id)
	queue_free()


func _cancel() -> void:
	cancelled.emit()
	queue_free()
