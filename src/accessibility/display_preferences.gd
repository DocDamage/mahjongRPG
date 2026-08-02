extends Node

signal mode_changed(mode_id: StringName)

const CONFIG_PATH := "user://display_preferences.cfg"
const WINDOWED := &"windowed"
const BORDERLESS := &"borderless"
const FULLSCREEN := &"fullscreen"
const MODE_IDS := [WINDOWED, BORDERLESS, FULLSCREEN]

var mode_id: StringName = WINDOWED


func _ready() -> void:
	if not is_supported():
		return
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		set_mode(StringName(config.get_value("display", "mode", WINDOWED)), false)


func is_supported() -> bool:
	return DisplayServer.get_name() != "headless"


func set_mode(next_mode: StringName, persist := true) -> Error:
	if not MODE_IDS.has(next_mode):
		return ERR_INVALID_PARAMETER
	mode_id = next_mode
	if not is_supported():
		return ERR_UNAVAILABLE
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if next_mode == FULLSCREEN else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, next_mode == BORDERLESS)
	if persist:
		var config := ConfigFile.new()
		config.set_value("display", "mode", String(mode_id))
		config.save(CONFIG_PATH)
	mode_changed.emit(mode_id)
	return OK


func mode_label(next_mode: StringName) -> String:
	match next_mode:
		WINDOWED:
			return "Windowed"
		BORDERLESS:
			return "Borderless"
		FULLSCREEN:
			return "Fullscreen"
	return "Unknown"
