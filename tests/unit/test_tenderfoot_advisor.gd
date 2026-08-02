extends RefCounted

const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")
const TenderfootAdvisor = preload("res://src/mahjong/presentation/tenderfoot_advisor.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var hand := [_tile(&"dots", 1), _tile(&"dots", 2), _tile(&"dots", 3), _tile(&"east", 0)]
	var public_river := [{"player": 1, "tile": _tile(&"east", 0)}]
	var advice := TenderfootAdvisor.recommend_discard(hand, public_river, [[], []])
	if int(advice.get("index", -1)) < 0 or advice.get("tile") not in hand:
		failures.append("Tenderfoot advice must recommend a tile from the player's own hand")
	if not String(advice.get("reason", "")).contains("visible information"):
		failures.append("Tenderfoot advice must explain its visible-information basis")
	var warning := TenderfootAdvisor.public_warning(_tile(&"east", 0), [[], [[_tile(&"east", 0)]]])
	if not warning.contains("public open group"):
		failures.append("Tenderfoot warnings should use only matching public open groups")
	if not TenderfootAdvisor.public_warning(_tile(&"east", 0), [[], []]).is_empty():
		failures.append("Tenderfoot warnings should not invent hidden opponent risk")
	if TenderfootAdvisor.recommend_discard([], public_river, [[], []]).get("error", OK) == OK:
		failures.append("Tenderfoot advice should reject an empty hand")
	return failures


func _tile(suit: StringName, rank: int) -> RefCounted:
	return MahjongTile.new(TileIdentity.new(suit, rank), &"blue")
