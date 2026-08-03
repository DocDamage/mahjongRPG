extends CanvasLayer

const AudioSettings = preload("res://src/ui/audio_settings.gd")
const DisplaySettings = preload("res://src/ui/display_settings.gd")
const InputSettings = preload("res://src/ui/input_settings.gd")
const ReleaseUiArt = preload("res://src/ui/release_ui_art.gd")

const MENU_PAUSE_REASON := &"save_menu"

var _shade: ColorRect
var _panel: PanelContainer
var _message: Label
var _first_button: Button
var _audio_settings
var _display_settings
var _input_settings


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if _audio_settings != null and _audio_settings.is_open():
			_audio_settings.close()
		elif _display_settings != null and _display_settings.is_open():
			_display_settings.close()
		elif _input_settings != null and _input_settings.is_open():
			_input_settings.close()
		elif is_open():
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _shade != null and _shade.visible


func open() -> void:
	if _shade == null:
		return
	var session = get_node_or_null("/root/GameSession")
	if session != null:
		session.request_pause(MENU_PAUSE_REASON)
	_shade.visible = true
	_message.text = "Choose a slot to save or load. Esc / Start closes this menu."
	_focus_first_button()


func close() -> void:
	if _shade == null:
		return
	_shade.visible = false
	var session = get_node_or_null("/root/GameSession")
	if session != null:
		session.release_pause(MENU_PAUSE_REASON)


func _build_menu() -> void:
	_shade = ColorRect.new()
	_shade.color = Color(0.05, 0.035, 0.02, 0.76)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)
	ReleaseUiArt.add_art(_shade, &"inventory_slot", Vector2(28, 28), Vector2(88, 88))
	_panel = PanelContainer.new()
	_panel.position = Vector2(230, 20)
	_panel.size = Vector2(500, 500)
	_shade.add_child(_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	_panel.add_child(content)
	var title := Label.new()
	title.text = "PAUSE  •  SAVE & LOAD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.custom_minimum_size = Vector2(440, 42)
	content.add_child(_message)
	for slot_number in range(1, 7):
		_add_slot_row(content, StringName("manual_%d" % slot_number), slot_number)
	var close_button := Button.new()
	close_button.text = "Audio settings"
	close_button.custom_minimum_size = Vector2(0, 28)
	close_button.pressed.connect(_open_audio_settings)
	content.add_child(close_button)
	var controls_button := Button.new()
	controls_button.text = "Controls"
	controls_button.custom_minimum_size = Vector2(0, 28)
	controls_button.pressed.connect(_open_input_settings)
	content.add_child(controls_button)
	var display_button := Button.new()
	display_button.text = "Display settings"
	display_button.custom_minimum_size = Vector2(0, 28)
	display_button.pressed.connect(_open_display_settings)
	content.add_child(display_button)
	var resume_button := Button.new()
	resume_button.text = "Resume"
	resume_button.custom_minimum_size = Vector2(0, 28)
	resume_button.pressed.connect(close)
	content.add_child(resume_button)
	_audio_settings = AudioSettings.new()
	_audio_settings.position = Vector2(280, 84)
	_audio_settings.size = Vector2(400, 372)
	_audio_settings.closed.connect(_restore_save_menu)
	_shade.add_child(_audio_settings)
	_display_settings = DisplaySettings.new()
	_display_settings.position = Vector2(280, 128)
	_display_settings.size = Vector2(400, 300)
	_display_settings.closed.connect(_restore_save_menu)
	_shade.add_child(_display_settings)
	_input_settings = InputSettings.new()
	_input_settings.position = Vector2(200, 42)
	_input_settings.size = Vector2(560, 454)
	_input_settings.closed.connect(_restore_save_menu)
	_shade.add_child(_input_settings)
	_shade.visible = false


func _add_slot_row(content: VBoxContainer, slot_id: StringName, slot_number: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	content.add_child(row)
	var label := Label.new()
	label.text = "Slot %d" % slot_number
	label.custom_minimum_size = Vector2(96, 34)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var save_button := Button.new()
	save_button.text = "Save"
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(_save_slot.bind(slot_id, slot_number))
	row.add_child(save_button)
	if _first_button == null:
		_first_button = save_button
	var load_button := Button.new()
	load_button.text = "Load"
	load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_button.pressed.connect(_load_slot.bind(slot_id, slot_number))
	row.add_child(load_button)


func _save_slot(slot_id: StringName, slot_number: int) -> void:
	var service = get_node_or_null("/root/SaveService")
	var result: Error = ERR_UNAVAILABLE
	if service != null:
		result = service.save_current_session(slot_id)
	_message.text = "Saved to Slot %d." % slot_number if result == OK else "Could not save to Slot %d." % slot_number


func _load_slot(slot_id: StringName, slot_number: int) -> void:
	var service = get_node_or_null("/root/SaveService")
	var result: Error = ERR_UNAVAILABLE
	if service != null:
		result = service.load_current_session(slot_id)
	if result == OK:
		_message.text = "Loaded Slot %d." % slot_number
		close()
	else:
		_message.text = "Slot %d has no valid save." % slot_number


func _focus_first_button() -> void:
	if _first_button != null:
		_first_button.grab_focus()


func _open_audio_settings() -> void:
	_panel.visible = false
	_audio_settings.open()


func _open_input_settings() -> void:
	_panel.visible = false
	_input_settings.open()


func _open_display_settings() -> void:
	_panel.visible = false
	_display_settings.open()


func _restore_save_menu() -> void:
	_panel.visible = true
	_focus_first_button()
