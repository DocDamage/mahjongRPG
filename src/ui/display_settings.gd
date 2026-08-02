extends PanelContainer

signal closed()

var _first_button: Button
var _status: Label


func _ready() -> void:
	_build()


func open() -> void:
	visible = true
	_refresh()
	if _first_button != null:
		_first_button.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func _build() -> void:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	var title := Label.new()
	title.text = "DISPLAY SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status)
	for mode_id in [&"windowed", &"borderless", &"fullscreen"]:
		var button := Button.new()
		button.name = "Mode_%s" % mode_id
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(_set_mode.bind(mode_id))
		content.add_child(button)
		if _first_button == null:
			_first_button = button
	var back_button := Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(0, 36)
	back_button.pressed.connect(close)
	content.add_child(back_button)
	visible = false


func _refresh() -> void:
	var service = _service()
	var supported: bool = service != null and bool(service.is_supported())
	_status.text = "Choose a display mode." if supported else "Display changes are unavailable in this runtime."
	for child in get_children()[0].get_children():
		if child is Button and String(child.name).begins_with("Mode_"):
			var mode_id := StringName(String(child.name).trim_prefix("Mode_"))
			child.text = service.mode_label(mode_id) if service != null else String(mode_id).capitalize()
			child.disabled = not supported


func _set_mode(mode_id: StringName) -> void:
	var service = _service()
	if service != null and service.set_mode(mode_id) == OK:
		_status.text = "%s mode enabled." % service.mode_label(mode_id)
	else:
		_status.text = "That display mode is unavailable."


func _service():
	return get_node_or_null("/root/DisplayPreferences")
