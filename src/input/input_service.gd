extends Node

signal active_device_changed(using_controller: bool)
signal binding_changed(action: StringName)

const ACTIONS := {
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"interact": [KEY_E, KEY_SPACE],
	&"run": [KEY_SHIFT],
	&"save_game": [KEY_F5],
	&"load_game": [KEY_F9],
	&"fish_reel": [KEY_R],
	&"fish_release": [KEY_F],
	&"fish_rod_left": [],
	&"fish_rod_right": [],
	&"pause": [KEY_ESCAPE],
	&"place_field": [KEY_B],
}
const CONTROLLER_BUTTON_DEFAULTS := {
	&"interact": JOY_BUTTON_A,
	&"run": JOY_BUTTON_LEFT_STICK,
	&"pause": JOY_BUTTON_START,
	&"place_field": JOY_BUTTON_X,
}
const CONTROLLER_AXIS_DEFAULTS := {
	&"move_left": [JOY_AXIS_LEFT_X, -1.0],
	&"move_right": [JOY_AXIS_LEFT_X, 1.0],
	&"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	&"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	&"fish_reel": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	&"fish_release": [JOY_AXIS_TRIGGER_LEFT, 1.0],
	&"fish_rod_left": [JOY_AXIS_RIGHT_X, -1.0],
	&"fish_rod_right": [JOY_AXIS_RIGHT_X, 1.0],
}
const CONTROLLER_BUTTON_LABELS := {
	JOY_BUTTON_A: "A / Cross",
	JOY_BUTTON_B: "B / Circle",
	JOY_BUTTON_X: "X / Square",
	JOY_BUTTON_Y: "Y / Triangle",
	JOY_BUTTON_BACK: "View / Share",
	JOY_BUTTON_START: "Menu / Options",
	JOY_BUTTON_LEFT_STICK: "Left stick press",
	JOY_BUTTON_RIGHT_STICK: "Right stick press",
	JOY_BUTTON_LEFT_SHOULDER: "Left bumper",
	JOY_BUTTON_RIGHT_SHOULDER: "Right bumper",
	JOY_BUTTON_DPAD_UP: "D-pad up",
	JOY_BUTTON_DPAD_DOWN: "D-pad down",
	JOY_BUTTON_DPAD_LEFT: "D-pad left",
	JOY_BUTTON_DPAD_RIGHT: "D-pad right",
}
const CONTROLLER_AXIS_LABELS := {
	JOY_AXIS_LEFT_X: "Left stick",
	JOY_AXIS_LEFT_Y: "Left stick",
	JOY_AXIS_RIGHT_X: "Right stick",
	JOY_AXIS_RIGHT_Y: "Right stick",
	JOY_AXIS_TRIGGER_LEFT: "Left trigger",
	JOY_AXIS_TRIGGER_RIGHT: "Right trigger",
}

var using_controller := false
var active_controller_device := -1


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


func remap_key(action: StringName, keycode: Key) -> Error:
	if not ACTIONS.has(action) or keycode == KEY_NONE:
		return ERR_INVALID_PARAMETER
	if not is_key_available(keycode, action):
		return ERR_ALREADY_EXISTS
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	_add_key(action, keycode)
	binding_changed.emit(action)
	return OK


func remap_controller_button(action: StringName, button: JoyButton) -> Error:
	if not CONTROLLER_BUTTON_DEFAULTS.has(action):
		return ERR_INVALID_PARAMETER
	if not is_controller_button_available(button, action):
		return ERR_ALREADY_EXISTS
	_erase_controller_buttons(action)
	_add_button(action, button)
	binding_changed.emit(action)
	return OK


func remap_controller_axis(action: StringName, axis: JoyAxis, direction: float) -> Error:
	if not CONTROLLER_AXIS_DEFAULTS.has(action) or is_zero_approx(direction):
		return ERR_INVALID_PARAMETER
	var normalized_direction := -1.0 if direction < 0.0 else 1.0
	if not is_controller_axis_available(axis, normalized_direction, action):
		return ERR_ALREADY_EXISTS
	_erase_controller_axes(action)
	_add_axis(action, axis, normalized_direction)
	binding_changed.emit(action)
	return OK


func reset_key_bindings(action: StringName) -> Error:
	if not ACTIONS.has(action):
		return ERR_INVALID_PARAMETER
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	for keycode in ACTIONS[action]:
		_add_key(action, keycode)
	binding_changed.emit(action)
	return OK


func reset_controller_bindings(action: StringName) -> Error:
	if CONTROLLER_BUTTON_DEFAULTS.has(action):
		_erase_controller_buttons(action)
		_add_button(action, CONTROLLER_BUTTON_DEFAULTS[action])
	elif CONTROLLER_AXIS_DEFAULTS.has(action):
		_erase_controller_axes(action)
		var mapping: Array = CONTROLLER_AXIS_DEFAULTS[action]
		_add_axis(action, mapping[0], mapping[1])
	else:
		return ERR_INVALID_PARAMETER
	binding_changed.emit(action)
	return OK


func controller_action_supported(action: StringName) -> bool:
	return CONTROLLER_BUTTON_DEFAULTS.has(action) or CONTROLLER_AXIS_DEFAULTS.has(action)


func is_key_available(keycode: Key, ignored_action: StringName = &"") -> bool:
	for action in ACTIONS:
		if action == ignored_action:
			continue
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and event.physical_keycode == keycode:
				return false
	return true


func is_controller_button_available(button: JoyButton, ignored_action: StringName = &"") -> bool:
	for action in CONTROLLER_BUTTON_DEFAULTS:
		if action == ignored_action:
			continue
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton and event.button_index == button:
				return false
	return true


func is_controller_axis_available(axis: JoyAxis, direction: float, ignored_action: StringName = &"") -> bool:
	for action in CONTROLLER_AXIS_DEFAULTS:
		if action == ignored_action:
			continue
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(sign(event.axis_value), sign(direction)):
				return false
	return true


func binding_text(action: StringName) -> String:
	if not ACTIONS.has(action):
		return ""
	var labels: Array[String] = []
	for event in InputMap.action_get_events(action):
		labels.append(event.as_text())
	return ", ".join(labels)


func prompt_binding_text(action: StringName, prefer_controller: bool) -> String:
	if not ACTIONS.has(action):
		return ""
	for event in InputMap.action_get_events(action):
		if prefer_controller and event is InputEventJoypadButton:
			return String(CONTROLLER_BUTTON_LABELS.get(event.button_index, "Button %d" % event.button_index))
		if prefer_controller and event is InputEventJoypadMotion:
			return _axis_binding_label(event.axis, event.axis_value)
		if not prefer_controller and event is InputEventKey:
			var keycode: Key = event.physical_keycode
			if keycode == KEY_NONE:
				keycode = event.keycode
			return OS.get_keycode_string(keycode)
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var keycode: Key = event.physical_keycode
			if keycode == KEY_NONE:
				keycode = event.keycode
			return OS.get_keycode_string(keycode)
	return String(action).capitalize()


func pulse_active_controller(weak_magnitude: float, strong_magnitude: float, duration_seconds: float) -> bool:
	if active_controller_device < 0 or DisplayServer.get_name() == "headless":
		return false
	Input.start_joy_vibration(active_controller_device, clampf(weak_magnitude, 0.0, 1.0), clampf(strong_magnitude, 0.0, 1.0), maxf(0.0, duration_seconds))
	return true


func _input(event: InputEvent) -> void:
	var next_using_controller := event is InputEventJoypadButton or event is InputEventJoypadMotion
	if next_using_controller:
		active_controller_device = event.device
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
	for action in CONTROLLER_BUTTON_DEFAULTS:
		_add_button(action, CONTROLLER_BUTTON_DEFAULTS[action])
	for action in CONTROLLER_AXIS_DEFAULTS:
		var mapping: Array = CONTROLLER_AXIS_DEFAULTS[action]
		_add_axis(action, mapping[0], mapping[1])


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


func _axis_binding_label(axis: JoyAxis, value: float) -> String:
	var label := String(CONTROLLER_AXIS_LABELS.get(axis, "Axis %d" % axis))
	if axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
		return label
	var direction := "right" if value > 0.0 else "left"
	if axis in [JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_Y]:
		direction = "down" if value > 0.0 else "up"
	return "%s %s" % [label, direction]


func _erase_controller_buttons(action: StringName) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			InputMap.action_erase_event(action, event)


func _erase_controller_axes(action: StringName) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			InputMap.action_erase_event(action, event)
