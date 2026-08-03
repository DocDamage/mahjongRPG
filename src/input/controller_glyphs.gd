extends RefCounted

const GLYPHS := {
	&"xbox": {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y", JOY_BUTTON_START: "Menu", JOY_BUTTON_BACK: "View"},
	&"playstation": {JOY_BUTTON_A: "Cross", JOY_BUTTON_B: "Circle", JOY_BUTTON_X: "Square", JOY_BUTTON_Y: "Triangle", JOY_BUTTON_START: "Options", JOY_BUTTON_BACK: "Share"},
	&"auto": {JOY_BUTTON_A: "South", JOY_BUTTON_B: "East", JOY_BUTTON_X: "West", JOY_BUTTON_Y: "North", JOY_BUTTON_START: "Menu", JOY_BUTTON_BACK: "View"},
}


static func preferred_set(preferences) -> StringName:
	return StringName(preferences.controller_glyph_set) if preferences != null else &"xbox"


static func label(button: JoyButton, glyph_set: StringName) -> String:
	var family: Dictionary = GLYPHS.get(glyph_set, GLYPHS[&"auto"])
	return String(family.get(button, "Button %d" % button))


static func action_label(events: Array, glyph_set: StringName, preferences) -> String:
	var selected_set := preferred_set(preferences) if glyph_set == &"auto" else glyph_set
	for event in events:
		if event is InputEventJoypadButton:
			return label(event.button_index, selected_set)
		if event is InputEventJoypadMotion:
			return _axis_label(event.axis, event.axis_value)
	return "Unavailable"


static func _axis_label(axis: JoyAxis, value: float) -> String:
	var label_text := "Trigger" if axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT] else "Stick"
	if label_text == "Trigger":
		return "Left trigger" if axis == JOY_AXIS_TRIGGER_LEFT else "Right trigger"
	var direction := "right" if value > 0.0 else "left"
	if axis in [JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_Y]:
		direction = "down" if value > 0.0 else "up"
	return "%s %s" % [label_text, direction]
