extends RefCounted

const BrandChargeState = preload("res://src/mahjong/domain/brand_charge_state.gd")
const ClaimResolver = preload("res://src/mahjong/domain/claim_resolver.gd")
const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var charges = BrandChargeState.new()
	if charges.configure([&"blue", &"orange"]) != OK:
		failures.append("a distinct two-Brand loadout should be valid")
	for ignored in 3:
		charges.record_discard(&"blue")
	if charges.activations(&"blue") != 1 or charges.charges(&"blue") != 0:
		failures.append("three matching discards should create one activation")
	for ignored in 6:
		charges.record_discard(&"blue")
	if charges.activations(&"blue") != 2:
		failures.append("stored activations must cap at two")
	charges.reset_for_hand()
	if charges.activations(&"blue") != 0:
		failures.append("Brand activations must reset for each hand")
	var discard = _tile(&"dots", 3, &"pink")
	var blue_claim := ClaimResolver.resolve(discard, [{
		"player": 1,
		"kind": "blue_run",
		"equipped": [&"blue", &"orange"],
		"tiles": [_tile(&"dots", 1, &"blue"), _tile(&"dots", 2, &"dark")],
	}])
	if blue_claim.get("kind", "") != "blue_run":
		failures.append("Blue should claim a discard only when it completes a Run")
	var winning_claim := ClaimResolver.resolve(discard, [_winning_claim(discard), blue_claim])
	if winning_claim.get("kind", "") != "win":
		failures.append("a legal winning claim must take precedence over Brand claims")
	return failures


func _tile(suit: StringName, rank: int, brand: StringName) -> RefCounted:
	return MahjongTile.new(TileIdentity.new(suit, rank), brand)


func _winning_claim(discard) -> Dictionary:
	return {
		"player": 0,
		"kind": "win",
		"hand": [
			_tile(&"dots", 1, &"blue"), _tile(&"dots", 2, &"dark"),
			_tile(&"bamboo", 4, &"green"), _tile(&"bamboo", 5, &"orange"), _tile(&"bamboo", 6, &"pink"),
			_tile(&"east", 0, &"purple"), _tile(&"east", 0, &"blue"), _tile(&"east", 0, &"dark"),
			_tile(&"red", 0, &"green"), _tile(&"red", 0, &"orange"),
		],
	}
