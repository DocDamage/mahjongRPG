extends RefCounted

const FrontierAi = preload("res://src/mahjong/ai/frontier_ai.gd")
const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")
const VisibleKnowledge = preload("res://src/mahjong/ai/visible_knowledge.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var hand := [_tile(&"dots", 1), _tile(&"dots", 2), _tile(&"dots", 3), _tile(&"east", 0)]
	var knowledge = VisibleKnowledge.new()
	knowledge.observe_discard(0, _tile(&"east", 0))
	var first := FrontierAi.new().choose_discard_index(hand, knowledge, {"set_weight": 1.3})
	var second := FrontierAi.new().choose_discard_index(hand, knowledge, {"set_weight": 1.3})
	if first.get("index", -1) != second.get("index", -2) or not String(first.get("reason", "")).begins_with("Frontier read:"):
		failures.append("advanced AI must be deterministic and expose a visible-information explanation")
	if first.get("knowledge", {}).get("discards", []).size() != 1 or first.get("knowledge", {}).has("wall"):
		failures.append("advanced AI explanations must not retain concealed-hand or wall-order knowledge")
	return failures


func _tile(suit: StringName, rank: int) -> RefCounted:
	return MahjongTile.new(TileIdentity.new(suit, rank), &"dark")
