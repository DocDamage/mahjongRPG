extends RefCounted

const BrandId = preload("res://src/mahjong/domain/brand_id.gd")
const WallBuilder = preload("res://src/mahjong/domain/wall_builder.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var first_wall: Array = WallBuilder.build_trail_wall(124)
	var second_wall: Array = WallBuilder.build_trail_wall(124)
	if first_wall.size() != WallBuilder.TRAIL_WALL_SIZE:
		failures.append("Trail Rules wall must contain 102 tiles")
	for brand in BrandId.ALL:
		if WallBuilder.brand_counts(first_wall)[brand] != 17:
			failures.append("each Brand must appear exactly 17 times")
			break
	for index in first_wall.size():
		if first_wall[index].key() != second_wall[index].key():
			failures.append("wall construction must be deterministic for a seed")
			break
	return failures
