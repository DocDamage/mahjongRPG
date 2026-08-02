extends RefCounted

const InputServiceScript = preload("res://src/input/input_service.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var service = InputServiceScript.new()
	service.install_default_actions()
	for action in [&"move_up", &"move_down", &"move_left", &"move_right", &"interact", &"run", &"pause"]:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			failures.append("missing input action: %s" % action)
	service.free()
	return failures
