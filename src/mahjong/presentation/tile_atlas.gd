extends RefCounted

const BrandId = preload("res://src/mahjong/domain/brand_id.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")
const TABLE_ID := &"mahjong_tile_atlas"
const TABLE_PATH := "res://data/mahjong/vertical_slice_tile_atlas.json"


static func texture_for(tile) -> AtlasTexture:
	var identity_index := _identity_index(tile.identity)
	var texture: Texture2D = load(_atlas_path()) as Texture2D
	var region_size := _cell_size()
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(Vector2(0, identity_index * region_size.y), region_size)
	return atlas


static func brand_color(brand: StringName) -> Color:
	var colors := [Color("4d86d7"), Color("51445f"), Color("5c9b62"), Color("d58a38"), Color("cf6e9b"), Color("8f65b8")]
	var index := BrandId.ALL.find(brand)
	return colors[index] if index >= 0 else Color.WHITE


static func _identity_index(identity) -> int:
	for index in TileIdentity.all_identities().size():
		var candidate = TileIdentity.all_identities()[index]
		if candidate.equals(identity):
			return index
	return 0


static func _atlas_path() -> String:
	return String(_table().get("atlas_path", ""))


static func _cell_size() -> Vector2i:
	var value: Variant = _table().get("cell_size", [])
	return Vector2i(int(value[0]), int(value[1])) if value is Array and value.size() == 2 else Vector2i.ZERO


static func _table() -> Dictionary:
	var scene_tree := Engine.get_main_loop() as SceneTree
	var registry = scene_tree.root.get_node_or_null("ContentRegistry") if scene_tree != null else null
	if registry != null:
		if not registry.has_table(TABLE_ID):
			registry.load_table(TABLE_ID, TABLE_PATH)
		return registry.table(TABLE_ID)
	var file := FileAccess.open(TABLE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	return parsed if parsed is Dictionary else {}
