extends RefCounted

const BasicTrailAi = preload("res://src/mahjong/ai/basic_trail_ai.gd")
const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")
const VisibleKnowledge = preload("res://src/mahjong/ai/visible_knowledge.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var hand := [_tile(&"dots", 1), _tile(&"dots", 2), _tile(&"dots", 3), _tile(&"east", 0)]
	var knowledge = VisibleKnowledge.new()
	knowledge.observe_discard(0, _tile(&"east", 0))
	var ai = BasicTrailAi.new()
	var first: Dictionary = ai.choose_discard_index(hand, knowledge)
	var second: Dictionary = ai.choose_discard_index(hand, knowledge)
	if first.get("index", -1) < 0 or first.get("index", -1) >= hand.size():
		failures.append("AI must select only a tile from its own hand")
	if first != second:
		failures.append("AI selection must be deterministic for visible state")
	if knowledge.snapshot()["discards"].size() != 1:
		failures.append("visible knowledge must contain only observed public actions")
	return failures


func _tile(suit: StringName, rank: int) -> RefCounted:
	return MahjongTile.new(TileIdentity.new(suit, rank), &"blue")
