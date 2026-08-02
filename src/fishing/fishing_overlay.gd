extends CanvasLayer

const FishingSession = preload("res://src/fishing/fishing_session.gd")

var _panel: PanelContainer
var _state_label: Label
var _tension: ProgressBar
var _progress: ProgressBar
var _direction_label: Label
var _help_label: Label


func _ready() -> void:
	_build()
	visible = false


func show_session(session) -> void:
	visible = session != null
	if session != null:
		refresh(session)


func refresh(session) -> void:
	if session == null:
		visible = false
		return
	visible = true
	_state_label.text = _state_text(session.state)
	_tension.value = session.tension * 100.0
	_progress.value = session.progress * 100.0
	var pull := "RIGHT" if session.target_direction > 0.0 else "LEFT"
	_direction_label.text = "Fish pull: %s  •  Counter with %s" % [pull, "RIGHT" if pull == "LEFT" else "LEFT"]
	_help_label.text = "%s\nCounter: Left Stick / Keys  •  Rod: Right Stick  •  Reel: R / RT  •  Release: F / LT" % String(session.gear_profile.get("label", "Basic Kit"))


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(620, 300)
	_panel.size = Vector2(310, 215)
	add_child(_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	_panel.add_child(content)
	_state_label = Label.new()
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.add_theme_font_size_override("font_size", 20)
	content.add_child(_state_label)
	_tension = _add_meter(content, "Tension")
	_progress = _add_meter(content, "Reel progress")
	_direction_label = Label.new()
	_direction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_direction_label)
	_help_label = Label.new()
	_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_help_label)


func _add_meter(content: VBoxContainer, label_text: String) -> ProgressBar:
	var row := HBoxContainer.new()
	content.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(96, 28)
	row.add_child(label)
	var meter := ProgressBar.new()
	meter.min_value = 0.0
	meter.max_value = 100.0
	meter.show_percentage = true
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(meter)
	return meter


func _state_text(state: int) -> String:
	match state:
		FishingSession.State.BITE:
			return "BITE — SET THE HOOK"
		FishingSession.State.STRUGGLE:
			return "STRUGGLE"
		FishingSession.State.CATCH:
			return "CATCH"
		FishingSession.State.ESCAPE:
			return "ESCAPED"
		FishingSession.State.PRESENTATION:
			return "CATCH CARD"
	return "CASTING"
