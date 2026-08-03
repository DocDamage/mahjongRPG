extends Node

signal preferences_changed()

const CONFIG_PATH := "user://game_preferences.cfg"
const SETTINGS_SCHEMA_VERSION := 2
const UI_SCALES := [0.85, 1.0, 1.15, 1.3]
const DIALOGUE_SPEEDS := [0.75, 1.0, 1.25, 1.5]

var text_scale := 1.0
var ui_scale := 1.0
var dialogue_speed := 1.0
var interaction_mode: StringName = &"toggle"
var reduced_motion := false
var subtitles := true
var controller_glyph_set: StringName = &"auto"
var mahjong_assistance: StringName = &"tenderfoot"
var high_contrast := false
var haptics_enabled := true
var timing_assist: StringName = &"standard"
var _contrast_layer: CanvasLayer


func _ready() -> void:
	load_preferences()


func _exit_tree() -> void:
	if _contrast_layer != null:
		_contrast_layer.queue_free()
		_contrast_layer = null


func load_preferences() -> Error:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return ERR_FILE_NOT_FOUND
	var schema_version := int(config.get_value("accessibility", "schema_version", 1))
	if schema_version < 1 or schema_version > SETTINGS_SCHEMA_VERSION:
		return ERR_FILE_UNRECOGNIZED
	text_scale = clampf(float(config.get_value("accessibility", "text_scale", text_scale)), 0.85, 1.5)
	ui_scale = clampf(float(config.get_value("accessibility", "ui_scale", ui_scale)), 0.85, 1.3)
	dialogue_speed = clampf(float(config.get_value("accessibility", "dialogue_speed", dialogue_speed)), 0.75, 1.5)
	interaction_mode = StringName(config.get_value("accessibility", "interaction_mode", interaction_mode))
	reduced_motion = bool(config.get_value("accessibility", "reduced_motion", reduced_motion))
	subtitles = bool(config.get_value("accessibility", "subtitles", subtitles))
	controller_glyph_set = StringName(config.get_value("accessibility", "controller_glyph_set", controller_glyph_set))
	mahjong_assistance = StringName(config.get_value("accessibility", "mahjong_assistance", mahjong_assistance))
	high_contrast = bool(config.get_value("accessibility", "high_contrast", high_contrast))
	haptics_enabled = bool(config.get_value("accessibility", "haptics_enabled", haptics_enabled))
	timing_assist = StringName(config.get_value("accessibility", "timing_assist", timing_assist))
	if not mahjong_assistance in [&"tenderfoot", &"trailhand", &"gunslinger"]:
		mahjong_assistance = &"tenderfoot"
	if not controller_glyph_set in [&"auto", &"xbox", &"playstation"]:
		controller_glyph_set = &"auto"
	if not timing_assist in [&"standard", &"relaxed"]:
		timing_assist = &"standard"
	_apply()
	return OK


func save_preferences() -> Error:
	var config := ConfigFile.new()
	config.set_value("accessibility", "schema_version", SETTINGS_SCHEMA_VERSION)
	for entry in {"text_scale": text_scale, "ui_scale": ui_scale, "dialogue_speed": dialogue_speed, "interaction_mode": interaction_mode, "reduced_motion": reduced_motion, "subtitles": subtitles, "controller_glyph_set": controller_glyph_set, "mahjong_assistance": mahjong_assistance, "high_contrast": high_contrast, "haptics_enabled": haptics_enabled, "timing_assist": timing_assist}:
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


func cycle_mahjong_assistance() -> void:
	mahjong_assistance = &"trailhand" if mahjong_assistance == &"tenderfoot" else &"gunslinger" if mahjong_assistance == &"trailhand" else &"tenderfoot"
	_commit()


func toggle_high_contrast() -> void:
	high_contrast = not high_contrast
	_commit()


func toggle_haptics() -> void:
	haptics_enabled = not haptics_enabled
	_commit()


func cycle_timing_assist() -> void:
	timing_assist = &"relaxed" if timing_assist == &"standard" else &"standard"
	_commit()


func timing_window_multiplier() -> float:
	return 1.75 if timing_assist == &"relaxed" else 1.0


func _next_value(values: Array, current: float) -> float:
	var index := values.find(current)
	return float(values[(index + 1) % values.size()])


func _commit() -> void:
	_apply()
	save_preferences()
	preferences_changed.emit()


func _apply() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree != null:
		tree.root.content_scale_factor = ui_scale
		_set_high_contrast_overlay(tree.root)


func _set_high_contrast_overlay(root: Window) -> void:
	if _contrast_layer == null and high_contrast:
		_contrast_layer = CanvasLayer.new()
		_contrast_layer.name = "AccessibilityHighContrast"
		_contrast_layer.layer = 120
		var overlay := ColorRect.new()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shader := Shader.new()
		shader.code = "shader_type canvas_item;\nuniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;\nvoid fragment() { vec4 source = texture(screen_texture, SCREEN_UV); vec3 contrast = clamp((source.rgb - vec3(0.5)) * 1.55 + vec3(0.5), 0.0, 1.0); COLOR = vec4(mix(contrast, vec3(dot(contrast, vec3(0.2126, 0.7152, 0.0722))), 0.15), source.a); }"
		var material := ShaderMaterial.new()
		material.shader = shader
		overlay.material = material
		_contrast_layer.add_child(overlay)
		root.add_child(_contrast_layer)
	if _contrast_layer != null:
		_contrast_layer.visible = high_contrast
