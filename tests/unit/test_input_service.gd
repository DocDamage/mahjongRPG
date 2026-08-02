extends RefCounted

const InputServiceScript = preload("res://src/input/input_service.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var service = InputServiceScript.new()
	service.install_default_actions()
	for action in [&"move_up", &"move_down", &"move_left", &"move_right", &"interact", &"run", &"save_game", &"load_game", &"fish_reel", &"fish_release", &"fish_rod_left", &"fish_rod_right", &"pause", &"place_field"]:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			failures.append("missing input action: %s" % action)
	if service.remap_key(&"interact", KEY_Q) != OK or service.is_key_available(KEY_Q):
		failures.append("keyboard bindings should be remappable and reserve their new key")
	if service.remap_key(&"run", KEY_Q) != ERR_ALREADY_EXISTS:
		failures.append("keyboard remapping should reject duplicate keys")
	if service.reset_key_bindings(&"interact") != OK or service.is_key_available(KEY_E):
		failures.append("keyboard binding resets should restore the default key")
	if service.remap_key(&"missing", KEY_Q) != ERR_INVALID_PARAMETER:
		failures.append("unknown remap actions should be rejected")
	if service.remap_controller_button(&"interact", JOY_BUTTON_B) != OK or service.is_controller_button_available(JOY_BUTTON_B):
		failures.append("controller buttons should be remappable and reserve their new button")
	if service.remap_controller_button(&"run", JOY_BUTTON_B) != ERR_ALREADY_EXISTS:
		failures.append("controller remapping should reject duplicate buttons")
	if service.reset_controller_bindings(&"interact") != OK or service.is_controller_button_available(JOY_BUTTON_A):
		failures.append("controller button resets should restore the default button")
	if service.remap_controller_axis(&"fish_rod_left", JOY_AXIS_RIGHT_Y, -1.0) != OK or service.is_controller_axis_available(JOY_AXIS_RIGHT_Y, -1.0):
		failures.append("controller axes should be remappable and reserve their direction")
	if service.reset_controller_bindings(&"fish_rod_left") != OK or service.is_controller_axis_available(JOY_AXIS_RIGHT_X, -1.0):
		failures.append("controller axis resets should restore the default axis")
	if service.remap_controller_button(&"move_left", JOY_BUTTON_B) != ERR_INVALID_PARAMETER:
		failures.append("movement axes should reject incompatible button remaps")
	if service.prompt_binding_text(&"interact", false) != "E" or service.prompt_binding_text(&"interact", true) != "A / Cross":
		failures.append("prompt labels should expose the active keyboard and controller bindings")
	if service.remap_controller_button(&"interact", JOY_BUTTON_B) != OK or service.prompt_binding_text(&"interact", true) != "B / Circle":
		failures.append("controller prompt labels should follow remapped bindings")
	service.free()
	return failures
