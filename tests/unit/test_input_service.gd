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
	service.free()
	return failures
