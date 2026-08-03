extends RefCounted

const DisplayPreferences = preload("res://src/accessibility/display_preferences.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var preferences = DisplayPreferences.new()
	if preferences.mode_label(&"windowed") != "Windowed" or preferences.mode_label(&"borderless") != "Borderless" or preferences.mode_label(&"fullscreen") != "Fullscreen":
		failures.append("display preferences should expose the three required player-facing window modes")
	if preferences.set_mode(&"missing", false) != ERR_INVALID_PARAMETER:
		failures.append("invalid display modes should be rejected")
	preferences.free()
	return failures
