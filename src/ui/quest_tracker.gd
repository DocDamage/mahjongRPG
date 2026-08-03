extends CanvasLayer

const DialogueCatalog = preload("res://src/dialogue/dialogue_catalog.gd")

var _panel: PanelContainer
var _label: Label


func _ready() -> void:
	layer = 25
	_build_ui()
	GameSession.quest_journal.changed.connect(_on_projection_changed)
	GamePreferences.preferences_changed.connect(_apply_preferences)
	InputService.active_device_changed.connect(_on_device_changed)
	_apply_preferences()
	_on_projection_changed(GameSession.quest_journal.projections())


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_panel.position = Vector2(-350, 18)
	_panel.custom_minimum_size = Vector2(330, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = Label.new()
	_label.name = "Objective"
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)


func _on_projection_changed(projections: Array[Dictionary]) -> void:
	if projections.is_empty():
		_panel.visible = false
		_label.text = ""
		return
	_panel.visible = true
	var projection: Dictionary = projections[0]
	var title := _localized_or_fallback(StringName(projection.get("title_key", "")), String(projection.get("title", "Active quest")))
	var objective := _localized_or_fallback(StringName(projection.get("label_key", "")), String(projection.get("stage_id", "Next step")).replace("_", " ").capitalize())
	var lines: Array[String] = ["QUEST — %s" % title, "[ ] %s" % objective]
	var requirements: Dictionary = projection.get("requirements", {})
	var counts: Dictionary = projection.get("live_counts", {})
	if not requirements.is_empty() and StringName(projection.get("stage_id", "")) == &"gather_provisions":
		for item_value in requirements:
			var item_id := StringName(item_value)
			var label := "Fish" if item_id == &"any_fish" else String(item_id).trim_prefix("crop_").replace("_", " ").capitalize()
			var current := int(counts.get(item_id, 0))
			var target := int(requirements[item_value])
			lines.append("%s %s: %d/%d" % ["[READY]" if current >= target else "[NEEDED]", label, current, target])
	_label.text = "\n".join(lines)


func _localized_or_fallback(key: StringName, fallback: String) -> String:
	var localized := DialogueCatalog.text(key) if not key.is_empty() else ""
	return localized if not localized.is_empty() else fallback


func _apply_preferences() -> void:
	_label.add_theme_font_size_override("font_size", maxi(14, int(16.0 * GamePreferences.text_scale)))


func _on_device_changed(_using_controller: bool) -> void:
	_on_projection_changed(GameSession.quest_journal.projections())
