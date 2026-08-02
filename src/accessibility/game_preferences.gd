extends Node

signal preferences_changed()

const CONFIG_PATH := "user://game_preferences.cfg"
const UI_SCALES := [0.85, 1.0, 1.15, 1.3]
const DIALOGUE_SPEEDS := [0.75, 1.0, 1.25, 1.5]

var text_scale := 1.0
var ui_scale := 1.0
var dialogue_speed := 1.0
var interaction_mode: StringName = &"toggle"
var reduced_motion := false
var subtitles := true
var controller_glyph_set: StringName = &"auto"


func _ready() -> void:
	load_preferences()


func load_preferences() -> Error:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return ERR_FILE_NOT_FOUND
	text_scale = clampf(float(config.get_value("accessibility", "text_scale", text_scale)), 0.85, 1.5)
	ui_scale = clampf(float(config.get_value("accessibility", "ui_scale", ui_scale)), 0.85, 1.3)
	dialogue_speed = clampf(float(config.get_value("accessibility", "dialogue_speed", dialogue_speed)), 0.75, 1.5)
	interaction_mode = StringName(config.get_value("accessibility", "interaction_mode", interaction_mode))
	reduced_motion = bool(config.get_value("accessibility", "reduced_motion", reduced_motion))
	subtitles = bool(config.get_value("accessibility", "subtitles", subtitles))
	controller_glyph_set = StringName(config.get_value("accessibility", "controller_glyph_set", controller_glyph_set))
	_apply()
	return OK


func save_preferences() -> Error:
	var config := ConfigFile.new()
	for entry in {"text_scale": text_scale, "ui_scale": ui_scale, "dialogue_speed": dialogue_speed, "interaction_mode": interaction_mode, "reduced_motion": reduced_motion, "subtitles": subtitles, "controller_glyph_set": controller_glyph_set}:
		config.set_value("accessibility", entry, get(entry))
	return config.save(CONFIG_PATH)


func cycle_ui_scale() -> void:
	ui_scale = _next_value(UI_SCALES, ui_scale)
	_commit()


func cycle_text_scale() -> void:
	text_scale = _next_value(UI_SCALES, text_scale)
	_commit()


func cycle_dialogue_speed() -> void:
	dialogue_speed = _next_value(DIALOGUE_SPEEDS, dialogue_speed)
	_commit()


func toggle_interaction_mode() -> void:
	interaction_mode = &"hold" if interaction_mode == &"toggle" else &"toggle"
	_commit()


func toggle_reduced_motion() -> void:
	reduced_motion = not reduced_motion
	_commit()


func toggle_subtitles() -> void:
	subtitles = not subtitles
	_commit()


func cycle_controller_glyph_set() -> void:
	controller_glyph_set = &"xbox" if controller_glyph_set == &"auto" else &"playstation" if controller_glyph_set == &"xbox" else &"auto"
	_commit()


func _next_value(values: Array, current: float) -> float:
	var index := values.find(current)
	return float(values[(index + 1) % values.size()])


func _commit() -> void:
	_apply()
	save_preferences()
	preferences_changed.emit()


func _apply() -> void:
	get_tree().root.content_scale_factor = ui_scale
