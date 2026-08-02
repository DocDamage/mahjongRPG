extends RefCounted

const TrailHandValidator = preload("res://src/mahjong/domain/trail_hand_validator.gd")


static func resolve(discard, claims: Array) -> Dictionary:
	var winning_claims: Array[Dictionary] = []
	var brand_claims: Array[Dictionary] = []
	for claim_value in claims:
		if not claim_value is Dictionary:
			continue
		var claim: Dictionary = claim_value
		if _is_winning_claim(discard, claim):
			winning_claims.append(claim)
		elif _is_brand_claim(discard, claim):
			brand_claims.append(claim)
	if not winning_claims.is_empty():
		return _first_by_player(winning_claims)
	if not brand_claims.is_empty():
		return _first_by_player(brand_claims)
	return {}


static func _is_winning_claim(discard, claim: Dictionary) -> bool:
	if claim.get("kind", "") != "win" or discard == null:
		return false
	var hand_value = claim.get("hand", [])
	if not hand_value is Array:
		return false
	var candidate: Array = hand_value.duplicate()
	candidate.append(discard)
	return TrailHandValidator.is_winning_hand(candidate)


static func _is_brand_claim(discard, claim: Dictionary) -> bool:
	if discard == null:
		return false
	var kind := StringName(claim.get("kind", ""))
	var equipped_value = claim.get("equipped", [])
	var tiles_value = claim.get("tiles", [])
	if not equipped_value is Array or not tiles_value is Array:
		return false
	if kind == &"blue_run" and tiles_value.size() == 2:
		return &"blue" in equipped_value and _is_run([discard, tiles_value[0], tiles_value[1]])
	if kind == &"orange_group" and tiles_value.size() == 2:
		return &"orange" in equipped_value and (_is_run([discard, tiles_value[0], tiles_value[1]]) or _is_set([discard, tiles_value[0], tiles_value[1]]))
	if kind == &"green_set" and tiles_value.size() == 2:
		return &"green" in equipped_value and _is_set([discard, tiles_value[0], tiles_value[1]])
	if kind == &"pink_pair" and tiles_value.size() == 1:
		return &"pink" in equipped_value and _is_set([discard, tiles_value[0]])
	if kind == &"frontier_quad" and tiles_value.size() == 3:
		return _is_set([discard, tiles_value[0], tiles_value[1], tiles_value[2]])
	return false


static func _is_run(tiles: Array) -> bool:
	if tiles.any(func(tile) -> bool: return tile == null or not tile.identity.is_numbered()):
		return false
	var suit = tiles[0].identity.suit
	var ranks: Array[int] = []
	for tile in tiles:
		if tile.identity.suit != suit:
			return false
		ranks.append(tile.identity.rank)
	ranks.sort()
	return ranks == [ranks[0], ranks[0] + 1, ranks[0] + 2]


static func _is_set(tiles: Array) -> bool:
	return tiles.all(func(tile) -> bool: return tile != null and tile.identity.equals(tiles[0].identity))


static func _first_by_player(claims: Array[Dictionary]) -> Dictionary:
	claims.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return int(first.get("player", 99)) < int(second.get("player", 99))
	)
	return claims.front().duplicate(true)
