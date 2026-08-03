extends RefCounted

const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")
const TrailHandValidator = preload("res://src/mahjong/domain/trail_hand_validator.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	if not TrailHandValidator.is_winning_hand(_valid_hand()):
		failures.append("runs, honor set, and honor pair should form a Trail Rules hand")
	if TrailHandValidator.is_winning_hand(_invalid_hand()):
		failures.append("a hand without three groups and a pair must be rejected")
	if not TrailHandValidator.is_winning_hand(_overlapping_run_hand()):
		failures.append("recursive validation must handle overlapping run decompositions")
	return failures


func _tile(suit: StringName, rank: int, brand: StringName) -> RefCounted:
	return MahjongTile.new(TileIdentity.new(suit, rank), brand)


func _valid_hand() -> Array:
	return [
		_tile(&"dots", 1, &"blue"), _tile(&"dots", 2, &"dark"), _tile(&"dots", 3, &"green"),
		_tile(&"bamboo", 4, &"orange"), _tile(&"bamboo", 5, &"pink"), _tile(&"bamboo", 6, &"purple"),
		_tile(&"east", 0, &"blue"), _tile(&"east", 0, &"dark"), _tile(&"east", 0, &"green"),
		_tile(&"red", 0, &"orange"), _tile(&"red", 0, &"pink"),
	]


func _invalid_hand() -> Array:
	var hand := _valid_hand()
	hand[10] = _tile(&"white", 0, &"pink")
	return hand


func _overlapping_run_hand() -> Array:
	return [
		_tile(&"characters", 1, &"blue"), _tile(&"characters", 2, &"dark"), _tile(&"characters", 3, &"green"),
		_tile(&"characters", 2, &"orange"), _tile(&"characters", 3, &"pink"), _tile(&"characters", 4, &"purple"),
		_tile(&"characters", 3, &"blue"), _tile(&"characters", 4, &"dark"), _tile(&"characters", 5, &"green"),
		_tile(&"characters", 6, &"orange"), _tile(&"characters", 6, &"pink"),
	]
