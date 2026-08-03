extends PanelContainer

signal closed()

var _preferences
var _rows: Dictionary = {}


func configure(preferences) -> void:
	_preferences = preferences


func open() -> void:
	visible = true
	_refresh()
	get_node_or_null("Content/TextScale").grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func _ready() -> void:
	_build()


func _build() -> void:
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 8)
	add_child(content)
	var title := Label.new()
	title.text = "ACCESSIBILITY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	_add_row(content, "TextScale", "Text size", func(): _preferences.cycle_text_scale())
	_add_row(content, "UiScale", "UI scale", func(): _preferences.cycle_ui_scale())
	_add_row(content, "DialogueSpeed", "Dialogue speed", func(): _preferences.cycle_dialogue_speed())
	_add_row(content, "Interaction", "Interaction", func(): _preferences.toggle_interaction_mode())
	_add_row(content, "ReducedMotion", "Reduced motion", func(): _preferences.toggle_reduced_motion())
	_add_row(content, "Subtitles", "Subtitles", func(): _preferences.toggle_subtitles())
	_add_row(content, "Glyphs", "Controller glyphs", func(): _preferences.cycle_controller_glyph_set())
	_add_row(content, "MahjongAssistance", "Mahjong assistance", func(): _preferences.cycle_mahjong_assistance())
	_add_row(content, "TimingAssist", "Timing assist", func(): _preferences.cycle_timing_assist())
	_add_row(content, "HighContrast", "High contrast", func(): _preferences.toggle_high_contrast())
	_add_row(content, "Haptics", "Controller vibration", func(): _preferences.toggle_haptics())
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(close)
	content.add_child(back)
	visible = false


func _add_row(content: VBoxContainer, id: String, label: String, action: Callable) -> void:
	var button := Button.new()
	button.name = id
	button.pressed.connect(func() -> void: action.call(); _refresh())
	content.add_child(button)
	_rows[id] = {"button": button, "label": label}


func _refresh() -> void:
	if _preferences == null:
		return
	_set_row("TextScale", "%.0f%%" % (_preferences.text_scale * 100.0))
	_set_row("UiScale", "%.0f%%" % (_preferences.ui_scale * 100.0))
	_set_row("DialogueSpeed", "%.2fx" % _preferences.dialogue_speed)
	_set_row("Interaction", String(_preferences.interaction_mode).capitalize())
	_set_row("ReducedMotion", "On" if _preferences.reduced_motion else "Off")
	_set_row("Subtitles", "On" if _preferences.subtitles else "Off")
	_set_row("Glyphs", String(_preferences.controller_glyph_set).capitalize())
	_set_row("MahjongAssistance", String(_preferences.mahjong_assistance).capitalize())
	_set_row("TimingAssist", String(_preferences.timing_assist).capitalize())
	_set_row("HighContrast", "On" if _preferences.high_contrast else "Off")
	_set_row("Haptics", "On" if _preferences.haptics_enabled else "Off")


func _set_row(id: String, value: String) -> void:
	var row: Dictionary = _rows[id]
	row["button"].text = "%s: %s" % [row["label"], value]
