extends Control

var display_name := "Resident"
var face_color := Color("d7a36c")
var coat_color := Color("465a78")
var hat_color := Color("30231e")
var expression := "steady"


func configure(definition: Dictionary, next_expression := "steady") -> void:
	display_name = String(definition.get("display_name", "Resident"))
	var portrait: Dictionary = definition.get("portrait", {})
	var palette := _palette_for(StringName(definition.get("id", "")))
	face_color = Color(String(portrait.get("face_color", palette["face_color"])))
	coat_color = Color(String(portrait.get("coat_color", palette["coat_color"])))
	hat_color = Color(String(portrait.get("hat_color", palette["hat_color"])))
	expression = next_expression
	custom_minimum_size = Vector2(128, 128)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 128, 128), Color("211916"))
	draw_rect(Rect2(4, 4, 120, 120), coat_color)
	draw_rect(Rect2(24, 68, 80, 48), coat_color.lightened(0.12))
	draw_circle(Vector2(64, 56), 31, face_color)
	draw_rect(Rect2(25, 19, 78, 17), hat_color)
	draw_rect(Rect2(39, 7, 50, 20), hat_color)
	var eye_offset := 2.0 if expression == "warm" else 0.0
	draw_circle(Vector2(53, 53 + eye_offset), 3, Color("211916"))
	draw_circle(Vector2(75, 53 + eye_offset), 3, Color("211916"))
	if expression == "warm":
		draw_arc(Vector2(64, 68), 13, 0.15, PI - 0.15, 10, Color("211916"), 2.0)
	else:
		draw_line(Vector2(52, 70), Vector2(76, 70), Color("211916"), 2.0)
	draw_string(get_theme_default_font(), Vector2(8, 122), display_name, HORIZONTAL_ALIGNMENT_CENTER, 112, 12, Color("fff0bf"))


func _palette_for(resident_id: StringName) -> Dictionary:
	var palettes := {
		&"mayor_bell": {"face_color": "c98b5a", "coat_color": "526b7a", "hat_color": "30231e"},
		&"river_rose": {"face_color": "d69268", "coat_color": "476d77", "hat_color": "59322a"},
		&"dynamite_bill": {"face_color": "c88155", "coat_color": "9b563b", "hat_color": "39251c"},
		&"ada_rook": {"face_color": "e0ad7d", "coat_color": "5f7b3e", "hat_color": "71412d"},
		&"gideon_shaw": {"face_color": "8e593e", "coat_color": "694d36", "hat_color": "252b24"},
		&"registrar_elise": {"face_color": "ebbf91", "coat_color": "765477", "hat_color": "3e324f"},
		&"constable_mara": {"face_color": "a96a4b", "coat_color": "3d5d85", "hat_color": "1f2d47"},
		&"mariner_ves": {"face_color": "bd7654", "coat_color": "356f81", "hat_color": "233c52"},
		&"captain_coral": {"face_color": "d89566", "coat_color": "3c7182", "hat_color": "4a3032"},
		&"witness_ash": {"face_color": "a86a50", "coat_color": "60435c", "hat_color": "322333"},
	}
	return palettes.get(resident_id, {"face_color": "d7a36c", "coat_color": "465a78", "hat_color": "30231e"})
