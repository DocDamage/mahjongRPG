extends RefCounted

const RuntimeAssetCatalog = preload("res://src/content/runtime_asset_catalog.gd")


static func add_art(parent: Control, art_id: StringName, position: Vector2, size: Vector2) -> TextureRect:
	var texture := load(RuntimeAssetCatalog.ui_texture_path(art_id)) as Texture2D
	if texture == null:
		return null
	var art := TextureRect.new()
	art.texture = texture
	art.position = position
	art.size = size
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	return art
