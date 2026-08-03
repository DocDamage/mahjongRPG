extends CanvasLayer

signal confirmed(fish_id: StringName)
signal canceled()

const PAUSE_REASON := &"first_lantern_delivery"
const SAVE_REASON := &"first_lantern_delivery"

var _selected_fish: StringName
var _confirm_button: Button
var _selection_label: Label
var _released := false


func _ready() -> void:
	layer = 90
	_build_ui()
	GameSession.request_pause(PAUSE_REASON)
	SaveService.request_save_restriction(SAVE_REASON)
	GameSession.session_replacing.connect(_cancel)
	tree_exiting.connect(_release_guards)


func configure(fish_ids: Array[StringName], bean_count: int) -> void:
	var list := get_node("Root/Center/Panel/Content/FishChoices") as VBoxContainer
	for fish_id in fish_ids:
		var button := Button.new()
		button.text = "%s — %d owned" % [String(fish_id).trim_prefix("fish_").replace("_", " ").capitalize(), GameSession.inventory.item_count(fish_id)]
		button.pressed.connect(_select_fish.bind(fish_id, button))
		list.add_child(button)
	_selection_label.text = "Bean crop: 1 required (%d owned). Choose one eligible fish, then confirm delivery." % bean_count
	if list.get_child_count() > 0:
		(list.get_child(0) as Control).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.02, 0.02, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(shade)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(520, 300)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	var title := Label.new()
	title.text = "Deliver provisions to Mabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	_selection_label = Label.new()
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_selection_label)
	var choices := VBoxContainer.new()
	choices.name = "FishChoices"
	content.add_child(choices)
	var actions := HBoxContainer.new()
	actions.name = "Actions"
	content.add_child(actions)
	_confirm_button = Button.new()
	_confirm_button.name = "Confirm"
	_confirm_button.text = "Confirm selected fish + 1 bean"
	_confirm_button.disabled = true
	_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_button.pressed.connect(_confirm)
	actions.add_child(_confirm_button)
	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_cancel)
	actions.add_child(cancel_button)


func _select_fish(fish_id: StringName, button: Button) -> void:
	_selected_fish = fish_id
	_confirm_button.disabled = false
	_selection_label.text = "Selected: %s. Delivery removes exactly this fish and one bean crop." % String(fish_id).trim_prefix("fish_").replace("_", " ").capitalize()
	_confirm_button.grab_focus()
	button.release_focus()


func _confirm() -> void:
	if _selected_fish.is_empty():
		return
	_release_guards()
	confirmed.emit(_selected_fish)
	queue_free()


func _cancel() -> void:
	_release_guards()
	canceled.emit()
	queue_free()


func _release_guards() -> void:
	if _released:
		return
	_released = true
	GameSession.release_pause(PAUSE_REASON)
	SaveService.release_save_restriction(SAVE_REASON)
	if GameSession.session_replacing.is_connected(_cancel):
		GameSession.session_replacing.disconnect(_cancel)
