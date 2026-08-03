extends PanelContainer

signal closed()

const ACTIONS := {
	&"move_up": "Move up", &"move_down": "Move down", &"move_left": "Move left", &"move_right": "Move right",
	&"interact": "Interact", &"run": "Run", &"pause": "Pause", &"place_field": "Place field",
	&"fish_reel": "Fish reel", &"fish_release": "Fish release", &"fish_rod_left": "Rod left", &"fish_rod_right": "Rod right",
}

var _message: Label
var _keyboard_rows: VBoxContainer
var _controller_rows: VBoxContainer
var _first_keyboard_button: Button
var _first_controller_button: Button
var _capture_action: StringName
var _capture_kind: StringName


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func open() -> void:
	visible = true
	_refresh_rows()
	_focus_tab(0)


func close() -> void:
	_capture_action = &""
	_capture_kind = &""
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if _capture_action.is_empty():
		if event.is_action_pressed(&"pause"):
			close()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		_finish_capture(ERR_BUSY)
	elif _capture_kind == &"controller" and event is InputEventJoypadButton and event.is_pressed() and event.button_index == JOY_BUTTON_START:
		_finish_capture(ERR_BUSY)
	elif _capture_kind == &"keyboard" and event is InputEventKey and event.is_pressed():
		_finish_capture(_service().remap_key(_capture_action, event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode))
	elif _capture_kind == &"controller" and event is InputEventJoypadButton and event.is_pressed():
		_finish_capture(_service().remap_controller_button(_capture_action, event.button_index))
	elif _capture_kind == &"controller" and event is InputEventJoypadMotion and absf(event.axis_value) >= 0.7:
		_finish_capture(_service().remap_controller_axis(_capture_action, event.axis, sign(event.axis_value)))
	get_viewport().set_input_as_handled()


func _build() -> void:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	add_child(content)
	var title := Label.new()
	title.text = "CONTROLS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	_message = Label.new()
	_message.text = "Select a binding, then press a key, button, stick direction, or trigger."
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_message)
	var tabs := TabContainer.new()
	tabs.name = "ControlTabs"
	tabs.custom_minimum_size = Vector2(0, 282)
	content.add_child(tabs)
	_keyboard_rows = _add_tab(tabs, "Keyboard")
	_controller_rows = _add_tab(tabs, "Controller")
	tabs.tab_changed.connect(_focus_tab)
	var reset_button := Button.new()
	reset_button.text = "Reset current tab bindings"
	reset_button.pressed.connect(_reset_current_bindings.bind(tabs))
	content.add_child(reset_button)
	var back_button := Button.new()
	back_button.text = "Back"
	back_button.pressed.connect(close)
	content.add_child(back_button)
	visible = false


func _add_tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	tabs.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	return rows


func _refresh_rows() -> void:
	_clear(_keyboard_rows)
	_clear(_controller_rows)
	_first_keyboard_button = null
	_first_controller_button = null
	for action in ACTIONS:
		_add_row(_keyboard_rows, action, &"keyboard")
		if _service().controller_action_supported(action):
			_add_row(_controller_rows, action, &"controller")


func _add_row(container: VBoxContainer, action: StringName, kind: StringName) -> void:
	var row := HBoxContainer.new()
	container.add_child(row)
	var label := Label.new()
	label.text = ACTIONS[action]
	label.custom_minimum_size = Vector2(118, 30)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var bind_button := Button.new()
	bind_button.text = _binding_text(action, kind)
	bind_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bind_button.pressed.connect(_begin_capture.bind(action, kind))
	row.add_child(bind_button)
	if kind == &"keyboard" and _first_keyboard_button == null:
		_first_keyboard_button = bind_button
	elif kind == &"controller" and _first_controller_button == null:
		_first_controller_button = bind_button


func _begin_capture(action: StringName, kind: StringName) -> void:
	_capture_action = action
	_capture_kind = kind
	_message.text = "Listening for %s %s. Press Esc / Start to cancel." % [kind, ACTIONS[action]]


func _finish_capture(result: Error) -> void:
	_capture_action = &""
	_capture_kind = &""
	_message.text = "%s." % ("Binding updated" if result == OK else "Binding cancelled or unchanged")
	_refresh_rows()


func _reset_current_bindings(tabs: TabContainer) -> void:
	for action in ACTIONS:
		if tabs.current_tab == 0:
			_service().reset_key_bindings(action)
		elif _service().controller_action_supported(action):
			_service().reset_controller_bindings(action)
	_message.text = "Bindings reset."
	_refresh_rows()


func _binding_text(action: StringName, kind: StringName) -> String:
	if kind == &"controller":
		return _service().prompt_binding_text(action, true)
	var labels: Array[String] = []
	for event in InputMap.action_get_events(action):
		if (kind == &"keyboard" and event is InputEventKey) or (kind == &"controller" and (event is InputEventJoypadButton or event is InputEventJoypadMotion)):
			labels.append(event.as_text())
	return ", ".join(labels) if not labels.is_empty() else "Unavailable"


func _service():
	return get_node_or_null("/root/InputService")


func _focus_tab(tab: int) -> void:
	var focus_target := _first_keyboard_button if tab == 0 else _first_controller_button
	if is_open() and focus_target != null:
		focus_target.grab_focus()


func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
