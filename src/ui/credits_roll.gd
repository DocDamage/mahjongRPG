extends Control

signal credits_completed()


func _ready() -> void:
	AudioService.play_catalog_music(&"credits")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.035, 0.025, 0.05, 0.97)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-310, -190)
	panel.size = Vector2(620, 380)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 14)
	add_child(panel)
	var title := Label.new()
	title.text = "CREDITS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	panel.add_child(title)
	var ending: Dictionary = GameSession.finale.ending_summary()
	var ending_label := Label.new()
	ending_label.text = "%s\n%s" % [String(ending.get("title", "The earned ending")), String(ending.get("category", ""))]
	ending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(ending_label)
	for credit_line_value in GameSession.finale.definition.get("credits", []):
		var credit := Label.new()
		credit.text = String(credit_line_value)
		credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(credit)
	var continue_button := Button.new()
	continue_button.text = "Continue to postgame"
	continue_button.pressed.connect(_continue_to_postgame)
	panel.add_child(continue_button)
	continue_button.grab_focus()


func _continue_to_postgame() -> void:
	if GameSession.finale.acknowledge_credits() != OK:
		return
	GameSession.postgame.enter(GameSession.finale, GameSession.public_life)
	AudioService.play_catalog_event(&"postgame_open")
	SaveService.autosave(&"postgame_transition")
	credits_completed.emit()
	queue_free()
