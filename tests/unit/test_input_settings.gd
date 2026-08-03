extends RefCounted

const InputSettings = preload("res://src/ui/input_settings.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var tree := Engine.get_main_loop() as SceneTree
	var settings = InputSettings.new()
	tree.root.add_child(settings)
	if settings.is_open():
		failures.append("controls screen should begin closed")
	settings.open()
	if not settings.is_open() or not _focus_is_inside(settings):
		failures.append("opening controls should focus a reachable keyboard binding")
	var tabs := settings.find_child("ControlTabs", true, false) as TabContainer
	if tabs == null:
		failures.append("controls screen should expose keyboard and controller tabs")
	else:
		tabs.current_tab = 1
		if not _focus_is_inside(settings):
			failures.append("switching to controller controls should retain focus inside the screen")
	settings.close()
	if settings.is_open():
		failures.append("controls screen should close cleanly")
	tree.root.remove_child(settings)
	settings.free()
	return failures


func _focus_is_inside(settings: Control) -> bool:
	var owner := settings.get_viewport().gui_get_focus_owner()
	return owner != null and settings.is_ancestor_of(owner)
