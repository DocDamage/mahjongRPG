extends Label

const TileAtlas = preload("res://src/mahjong/presentation/tile_atlas.gd")


func configure(brand: StringName) -> void:
	text = TileAtlas.brand_pattern(brand)
	tooltip_text = "%s Brand • %s pattern" % [String(brand).capitalize(), TileAtlas.brand_pattern_label(brand)]
	position = Vector2(2, 48)
	size = Vector2(50, 24)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", 18)
	add_theme_color_override("font_color", Color("22170e"))
	add_theme_color_override("font_outline_color", Color("fff4d6"))
	add_theme_constant_override("outline_size", 2)
