extends CanvasLayer

const CommunityPortrait = preload("res://src/dialogue/community_portrait.gd")
const DialogueSequenceValidator = preload("res://src/dialogue/dialogue_sequence_validator.gd")
const RuntimeAssetCatalog = preload("res://src/content/runtime_asset_catalog.gd")
const RESTRICTION_REASON := &"dialogue_sequence"
const BASE_CHARACTERS_PER_SECOND := 32.0

signal terminal_acknowledged(sequence_id: StringName)
signal cancelled(sequence_id: StringName)

var _sequence_id: StringName
var _nodes: Dictionary = {}
var _current_node_id: StringName
var _line_lookup := Callable()
var _speakers: Dictionary = {}
var _preferences
var _save_service
var _session_gate
var _restriction_held := false
var _open := false
var _input_locked := false
var _characters_per_second := BASE_CHARACTERS_PER_SECOND
var _visible_characters_float := 0.0
var _shade: ColorRect
var _panel: PanelContainer
var _portrait
var _speaker_label: Label
var _line_label: Label
var _continue_button: Button
var _cancel_button: Button


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func _exit_tree() -> void:
	_release_restrictions()


func _process(delta: float) -> void:
	if not _open or _line_label == null or _line_label.visible_characters < 0:
		return
	_visible_characters_float += delta * _characters_per_second
	_line_label.visible_characters = mini(_line_label.text.length(), int(_visible_characters_float))
	if _line_label.visible_characters >= _line_label.text.length():
		_line_label.visible_characters = -1
		set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if handle_navigation_event(event):
		get_viewport().set_input_as_handled()


func handle_navigation_event(event: InputEvent) -> bool:
	if not _open:
		return false
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact"):
		confirm()
		return true
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		cancel()
		return true
	return false


func open_sequence(sequence: Dictionary, line_lookup: Callable, speakers: Dictionary, preferences, save_service, session_gate) -> Error:
	if _open or not line_lookup.is_valid() or save_service == null or session_gate == null:
		return ERR_INVALID_PARAMETER
	var context := {"speaker_ids": speakers.keys(), "portrait_speaker_ids": RuntimeAssetCatalog.portrait_residents(), "portrait_expressions": RuntimeAssetCatalog.portrait_expressions()}
	if not DialogueSequenceValidator.validate(sequence, "<runtime>", context).is_empty():
		return ERR_INVALID_DATA
	_sequence_id = StringName(sequence.get("id", ""))
	_current_node_id = StringName(sequence.get("start_node", ""))
	_nodes.clear()
	for node_value in sequence.get("nodes", []):
		_nodes[StringName(node_value.get("id", ""))] = node_value.duplicate(true)
	_line_lookup = line_lookup
	_speakers = speakers.duplicate(true)
	_preferences = preferences
	_save_service = save_service
	_session_gate = session_gate
	_input_locked = false
	_open = true
	_hold_restrictions()
	_build_interface()
	_show_current_node()
	_continue_button.grab_focus()
	return OK


func current_node_id() -> StringName:
	return _current_node_id


func current_text() -> String:
	return _line_label.text if _line_label != null else ""


func continue_has_focus() -> bool:
	return _continue_button != null and get_viewport().gui_get_focus_owner() == _continue_button


func reveal_current_line() -> void:
	if _line_label == null:
		return
	_line_label.visible_characters = -1
	set_process(false)


func confirm() -> void:
	if not _open or _input_locked:
		return
	if _line_label.visible_characters >= 0:
		reveal_current_line()
		return
	var node: Dictionary = _nodes.get(_current_node_id, {})
	var next_id := StringName(node.get("next", ""))
	if not next_id.is_empty():
		_current_node_id = next_id
		_show_current_node()
		return
	_input_locked = true
	terminal_acknowledged.emit(_sequence_id)


func finish_commit() -> void:
	_close()


func cancel() -> void:
	if not _open or _input_locked:
		return
	_input_locked = true
	var sequence_id := _sequence_id
	_close()
	cancelled.emit(sequence_id)


func presentation_state() -> Dictionary:
	return {
		"text_scale": _preference("text_scale", 1.0),
		"ui_scale": _preference("ui_scale", 1.0),
		"characters_per_second": _characters_per_second,
		"line_fully_visible": _line_label != null and _line_label.visible_characters < 0,
		"high_contrast": bool(_preference("high_contrast", false)),
	}


func _build_interface() -> void:
	_shade = ColorRect.new()
	_shade.color = Color("050505e8") if bool(_preference("high_contrast", false)) else Color("140e0bcf")
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)
	_panel = PanelContainer.new()
	_panel.size = Vector2(640, 340)
	var ui_scale := float(_preference("ui_scale", 1.0))
	_panel.scale = Vector2.ONE * ui_scale
	var viewport_size := get_viewport().get_visible_rect().size
	_panel.position = (viewport_size - (_panel.size * ui_scale)) * 0.5
	_shade.add_child(_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	_panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	_portrait = CommunityPortrait.new()
	header.add_child(_portrait)
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", int(22.0 * float(_preference("text_scale", 1.0))))
	if bool(_preference("high_contrast", false)):
		_speaker_label.add_theme_color_override("font_color", Color.WHITE)
	_speaker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_speaker_label)
	_line_label = Label.new()
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.custom_minimum_size = Vector2(580, 100)
	_line_label.add_theme_font_size_override("font_size", int(18.0 * float(_preference("text_scale", 1.0))))
	if bool(_preference("high_contrast", false)):
		_line_label.add_theme_color_override("font_color", Color.WHITE)
	content.add_child(_line_label)
	var buttons := HBoxContainer.new()
	content.add_child(buttons)
	_continue_button = Button.new()
	_continue_button.text = "Continue"
	_continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_continue_button.pressed.connect(confirm)
	buttons.add_child(_continue_button)
	_cancel_button = Button.new()
	_cancel_button.text = "Cancel"
	_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cancel_button.pressed.connect(cancel)
	buttons.add_child(_cancel_button)
	_continue_button.focus_neighbor_right = _continue_button.get_path_to(_cancel_button)
	_cancel_button.focus_neighbor_left = _cancel_button.get_path_to(_continue_button)


func _show_current_node() -> void:
	var node: Dictionary = _nodes.get(_current_node_id, {})
	var speaker_id := StringName(node.get("speaker_id", ""))
	var speaker: Dictionary = _speakers.get(speaker_id, {})
	_speaker_label.text = String(speaker.get("display_name", speaker_id))
	_portrait.configure(speaker, String(node.get("portrait_expression", "steady")))
	_line_label.text = String(_line_lookup.call(StringName(node.get("text_key", ""))))
	_characters_per_second = BASE_CHARACTERS_PER_SECOND * float(_preference("dialogue_speed", 1.0))
	_visible_characters_float = 0.0
	if bool(_preference("reduced_motion", false)):
		_line_label.visible_characters = -1
		set_process(false)
	else:
		_line_label.visible_characters = 0
		set_process(true)


func _preference(property_name: StringName, fallback: Variant) -> Variant:
	return _preferences.get(property_name) if _preferences != null else fallback


func _hold_restrictions() -> void:
	_save_service.request_save_restriction(RESTRICTION_REASON)
	_session_gate.request(RESTRICTION_REASON)
	_restriction_held = true


func _release_restrictions() -> void:
	if not _restriction_held:
		return
	_save_service.release_save_restriction(RESTRICTION_REASON)
	_session_gate.release(RESTRICTION_REASON)
	_restriction_held = false


func _close() -> void:
	if not _open:
		return
	_open = false
	set_process(false)
	if _shade != null:
		_shade.visible = false
	_release_restrictions()
