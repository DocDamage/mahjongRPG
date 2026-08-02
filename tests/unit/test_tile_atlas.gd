extends RefCounted

const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")
const TileAtlas = preload("res://src/mahjong/presentation/tile_atlas.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var tile = MahjongTile.new(TileIdentity.new(&"bamboo", 1), &"blue")
	var texture := TileAtlas.texture_for(tile)
	if texture.atlas == null or texture.region != Rect2(0, 0, 48, 64):
		failures.append("the first Trail Rules tile should resolve to the first atlas cell")
	var honor = MahjongTile.new(TileIdentity.new(&"white"), &"purple")
	var honor_texture := TileAtlas.texture_for(honor)
	if honor_texture.atlas == null or honor_texture.region.position != Vector2(0, 2112) or TileAtlas.brand_color(&"purple") == Color.WHITE:
		failures.append("honor tiles should resolve through the final identity cell with a visible Brand tint")
	return failures
