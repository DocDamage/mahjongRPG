extends Node

signal active_device_changed(using_controller: bool)

const ACTIONS := {
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"interact": [KEY_E, KEY_SPACE],
	&"pause": [KEY_ESCAPE],
}

var using_controller := false


func _ready() -> void:
	install_default_actions()


func install_default_actions() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			for keycode in ACTIONS[action]:
				_add_key(action, keycode)
	_add_controller_actions()


func movement_vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func _input(event: InputEvent) -> void:
	var next_using_controller := event is InputEventJoypadButton or event is InputEventJoypadMotion
	if event is InputEventKey or event is InputEventMouse:
		next_using_controller = false
	if next_using_controller != using_controller:
		using_controller = next_using_controller
		active_device_changed.emit(using_controller)


func _add_key(action: StringName, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)


func _add_controller_actions() -> void:
	_add_axis(&"move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis(&"move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis(&"move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis(&"move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_button(&"interact", JOY_BUTTON_A)
	_add_button(&"pause", JOY_BUTTON_START)


func _add_axis(action: StringName, axis: JoyAxis, value: float) -> void:
	if _has_joypad_event(action, axis, value):
		return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)


func _add_button(action: StringName, button: JoyButton) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func _has_joypad_event(action: StringName, axis: JoyAxis, value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, value):
			return true
	return false
