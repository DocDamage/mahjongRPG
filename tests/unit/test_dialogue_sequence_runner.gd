extends RefCounted

const DialogueSequenceRunner = preload("res://src/dialogue/dialogue_sequence_runner.gd")
const SaveServiceScript = preload("res://src/save/save_service.gd")
const SessionGate = preload("res://src/core/session_gate.gd")
const InputServiceScript = preload("res://src/input/input_service.gd")

class Preferences:
	extends RefCounted
	var text_scale := 1.0
	var ui_scale := 1.0
	var dialogue_speed := 1.0
	var reduced_motion := false
	var high_contrast := false


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_progression_focus_and_repeated_confirm(failures)
	_test_cancel_and_teardown_release_restrictions(failures)
	_test_accessibility_preferences(failures)
	_test_keyboard_controller_and_persistence_operations(failures)
	_test_keyboard_only_and_controller_only(failures)
	return failures


func _test_progression_focus_and_repeated_confirm(failures: Array[String]) -> void:
	var runner = _runner()
	var save_service := SaveServiceScript.new()
	var gate := SessionGate.new()
	var terminal_count := [0]
	runner.terminal_acknowledged.connect(func(_sequence_id): terminal_count[0] += 1)
	if runner.open_sequence(_sequence(), Callable(self, "_lookup"), _speakers(), Preferences.new(), save_service, gate) != OK:
		failures.append("a validated sequence should open")
	elif save_service.can_save() or gate.can_replace_session():
		failures.append("open dialogue must scope both save/load and session-replacement restrictions")
	elif runner.current_node_id() != &"opening" or runner.current_text() != "Opening line" or not runner.continue_has_focus():
		failures.append("dialogue must begin at its authored first node with keyboard/controller focus")
	runner.reveal_current_line()
	runner.confirm()
	if runner.current_node_id() != &"closing":
		failures.append("confirm after a revealed line must advance exactly one node")
	runner.reveal_current_line()
	runner.confirm()
	runner.confirm()
	if terminal_count[0] != 1:
		failures.append("rapid repeated terminal confirm must acknowledge exactly once")
	runner.finish_commit()
	if not save_service.can_save() or not gate.can_replace_session():
		failures.append("committed completion must release persistence restrictions")
	_free_runner(runner)
	save_service.free()


func _test_cancel_and_teardown_release_restrictions(failures: Array[String]) -> void:
	var save_service := SaveServiceScript.new()
	var gate := SessionGate.new()
	var runner = _runner()
	var cancelled := [0]
	runner.cancelled.connect(func(_sequence_id): cancelled[0] += 1)
	runner.open_sequence(_sequence(), Callable(self, "_lookup"), _speakers(), Preferences.new(), save_service, gate)
	runner.cancel()
	runner.cancel()
	if cancelled[0] != 1 or not save_service.can_save() or not gate.can_replace_session():
		failures.append("cancel must emit and release restrictions exactly once without committing")
	_free_runner(runner)
	var teardown_runner = _runner()
	teardown_runner.open_sequence(_sequence(), Callable(self, "_lookup"), _speakers(), Preferences.new(), save_service, gate)
	_free_runner(teardown_runner)
	if not save_service.can_save() or not gate.can_replace_session():
		failures.append("runner teardown must always release scoped restrictions")
	save_service.free()


func _test_accessibility_preferences(failures: Array[String]) -> void:
	var normal := Preferences.new()
	var runner = _runner()
	var normal_save := SaveServiceScript.new()
	runner.open_sequence(_sequence(), Callable(self, "_lookup"), _speakers(), normal, normal_save, SessionGate.new())
	var normal_state: Dictionary = runner.presentation_state()
	_free_runner(runner)
	normal_save.free()
	var accessible := Preferences.new()
	accessible.text_scale = 1.3
	accessible.ui_scale = 1.15
	accessible.dialogue_speed = 1.5
	accessible.reduced_motion = true
	accessible.high_contrast = true
	runner = _runner()
	var accessible_save := SaveServiceScript.new()
	runner.open_sequence(_sequence(), Callable(self, "_lookup"), _speakers(), accessible, accessible_save, SessionGate.new())
	var state: Dictionary = runner.presentation_state()
	if not state.get("line_fully_visible", false) or float(state.get("text_scale", 0.0)) != 1.3 or float(state.get("ui_scale", 0.0)) != 1.15:
		failures.append("reduced motion and text/UI scale must change dialogue presentation coherently")
	if not state.get("high_contrast", false) or float(state.get("characters_per_second", 0.0)) <= float(normal_state.get("characters_per_second", 0.0)):
		failures.append("high contrast and dialogue speed must be reflected by the runner")
	_free_runner(runner)
	accessible_save.free()


func _test_keyboard_controller_and_persistence_operations(failures: Array[String]) -> void:
	var root: Window = Engine.get_main_loop().root
	var session = root.get_node("GameSession")
	var original_snapshot: Dictionary = session.snapshot()
	session.start_new_game(8801)
	var save_service = root.get_node("SaveService")
	var preferences := Preferences.new()
	preferences.reduced_motion = true
	var input_service := InputServiceScript.new()
	input_service.install_default_actions()
	var runner = _runner()
	var terminal_count := [0]
	runner.terminal_acknowledged.connect(func(_sequence_id): terminal_count[0] += 1)
	runner.open_sequence(_sequence(), Callable(self, "_lookup"), _speakers(), preferences, save_service, session.session_gate)
	if save_service.save_current_session(&"manual_5") != ERR_BUSY or save_service.load_current_session(&"manual_5") != ERR_BUSY:
		failures.append("save and load operations must reject while a sequence is open")
	var keyboard := InputEventKey.new()
	keyboard.keycode = KEY_ENTER
	keyboard.pressed = true
	if not runner.handle_navigation_event(keyboard) or runner.current_node_id() != &"closing":
		failures.append("keyboard accept must advance the focused dialogue action")
	var controller := InputEventJoypadButton.new()
	controller.button_index = JOY_BUTTON_A
	controller.pressed = true
	if not runner.handle_navigation_event(controller) or terminal_count[0] != 1:
		failures.append("controller accept must commit the same focused dialogue action")
	runner.finish_commit()
	if save_service.save_current_session(&"manual_5") != OK:
		failures.append("save operations must resume after committed dialogue completion")
	_free_runner(runner)
	session.restore(original_snapshot)
	input_service.free()


func _test_keyboard_only_and_controller_only(failures: Array[String]) -> void:
	var input_service := InputServiceScript.new()
	input_service.install_default_actions()
	var keyboard := InputEventKey.new()
	keyboard.keycode = KEY_ENTER
	keyboard.pressed = true
	_run_single_device_sequence(keyboard, "keyboard", failures)
	var controller := InputEventJoypadButton.new()
	controller.button_index = JOY_BUTTON_A
	controller.pressed = true
	_run_single_device_sequence(controller, "controller", failures)
	input_service.free()


func _run_single_device_sequence(event: InputEvent, device_name: String, failures: Array[String]) -> void:
	var runner = _runner()
	var save_service := SaveServiceScript.new()
	var preferences := Preferences.new()
	preferences.reduced_motion = true
	var terminal_count := [0]
	runner.terminal_acknowledged.connect(func(_sequence_id): terminal_count[0] += 1)
	if runner.open_sequence(_sequence(), Callable(self, "_lookup"), _speakers(), preferences, save_service, SessionGate.new()) != OK or not runner.continue_has_focus():
		failures.append("%s-only dialogue must open with Continue focused" % device_name)
	elif not runner.handle_navigation_event(event) or runner.current_node_id() != &"closing":
		failures.append("%s-only dialogue must advance to the second node" % device_name)
	elif not runner.handle_navigation_event(event) or terminal_count[0] != 1:
		failures.append("%s-only dialogue must reach one terminal acknowledgment" % device_name)
	runner.finish_commit()
	_free_runner(runner)
	save_service.free()


func _runner():
	var runner = DialogueSequenceRunner.new()
	Engine.get_main_loop().root.add_child(runner)
	return runner


func _free_runner(runner) -> void:
	if runner.is_inside_tree():
		runner.get_parent().remove_child(runner)
	runner.free()


func _lookup(key: StringName) -> String:
	return {&"bell.open": "Opening line", &"bell.close": "Closing line"}.get(key, "")


func _speakers() -> Dictionary:
	return {&"mayor_bell": {"id": "mayor_bell", "display_name": "Mayor Bell"}}


func _sequence() -> Dictionary:
	return {
		"schema_version": 1, "id": "mayor_bell.meet", "start_node": "opening",
		"nodes": [
			{"id": "opening", "speaker_id": "mayor_bell", "text_key": "bell.open", "portrait_expression": "steady", "next": "closing"},
			{"id": "closing", "speaker_id": "mayor_bell", "text_key": "bell.close", "portrait_expression": "warm", "next": ""},
		],
	}
