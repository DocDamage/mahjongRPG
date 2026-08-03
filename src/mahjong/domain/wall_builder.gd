extends RefCounted

const BrandId = preload("res://src/mahjong/domain/brand_id.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")
const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")

const TRAIL_COPIES_PER_IDENTITY := 3
const TRAIL_WALL_SIZE := 102
const FRONTIER_COPIES_PER_IDENTITY := 4
const FRONTIER_WALL_SIZE := 136


static func build_trail_wall(seed: int) -> Array:
	return _build_wall(seed, TRAIL_COPIES_PER_IDENTITY)


static func build_frontier_wall(seed: int) -> Array:
	return _build_wall(seed, FRONTIER_COPIES_PER_IDENTITY)


static func _build_wall(seed: int, copies_per_identity: int) -> Array:
	var wall: Array = []
	var identities: Array = TileIdentity.all_identities()
	for identity_index in identities.size():
		for copy_index in copies_per_identity:
			var brand_index := (identity_index * copies_per_identity + copy_index) % BrandId.ALL.size()
			wall.append(MahjongTile.new(identities[identity_index], BrandId.ALL[brand_index]))
	_shuffle(wall, seed)
	return wall


static func brand_counts(wall: Array) -> Dictionary:
	var counts: Dictionary = {}
	for brand in BrandId.ALL:
		counts[brand] = 0
	for tile in wall:
		counts[tile.brand] = int(counts[tile.brand]) + 1
	return counts


static func _shuffle(items: Array, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for index in range(items.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary = items[index]
		items[index] = items[swap_index]
		items[swap_index] = temporary
