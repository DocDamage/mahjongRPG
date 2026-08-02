extends RefCounted

const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")

const HAND_SIZE := 11


static func is_winning_hand(tiles: Array) -> bool:
	if tiles.size() != HAND_SIZE:
		return false
	var counts := _identity_counts(tiles)
	for pair_key_value in counts.keys():
		var pair_key: String = pair_key_value
		if counts[pair_key] < 2:
			continue
		counts[pair_key] -= 2
		if _can_form_groups(counts, 3):
			return true
		counts[pair_key] += 2
	return false


static func _identity_counts(tiles: Array) -> Dictionary:
	var counts: Dictionary = {}
	for tile in tiles:
		if tile == null or tile.identity == null or not tile.identity.is_valid():
			return {}
		var key: String = tile.identity_key()
		counts[key] = int(counts.get(key, 0)) + 1
	return counts


static func winning_identity_keys(tiles: Array) -> Array[String]:
	var waits: Array[String] = []
	if tiles.size() != HAND_SIZE - 1:
		return waits
	for identity in TileIdentity.all_identities():
		var candidate := tiles.duplicate()
		candidate.append(MahjongTile.new(identity, &"blue"))
		if is_winning_hand(candidate):
			waits.append(identity.key())
	return waits


static func _can_form_groups(counts: Dictionary, groups_remaining: int) -> bool:
	if groups_remaining == 0:
		return _remaining_tile_count(counts) == 0
	var first_key: String = _first_nonzero_key(counts)
	if first_key.is_empty():
		return false
	if counts[first_key] >= 3:
		counts[first_key] -= 3
		if _can_form_groups(counts, groups_remaining - 1):
			return true
		counts[first_key] += 3
	var identity: Dictionary = _identity_from_key(first_key)
	if identity["numbered"]:
		var next_one: String = "%s:%d" % [identity["suit"], identity["rank"] + 1]
		var next_two: String = "%s:%d" % [identity["suit"], identity["rank"] + 2]
		if identity["rank"] <= 7 and counts.get(next_one, 0) > 0 and counts.get(next_two, 0) > 0:
			counts[first_key] -= 1
			counts[next_one] -= 1
			counts[next_two] -= 1
			if _can_form_groups(counts, groups_remaining - 1):
				return true
			counts[first_key] += 1
			counts[next_one] += 1
			counts[next_two] += 1
	return false


static func _first_nonzero_key(counts: Dictionary) -> String:
	var keys: Array = counts.keys()
	keys.sort()
	for key_value in keys:
		var key: String = key_value
		if counts[key] > 0:
			return key
	return ""


static func _remaining_tile_count(counts: Dictionary) -> int:
	var total := 0
	for value in counts.values():
		total += value
	return total


static func _identity_from_key(key: String) -> Dictionary:
	var pieces := key.split(":")
	var suit := StringName(pieces[0])
	var rank := int(pieces[1])
	return {"suit": suit, "rank": rank, "numbered": suit in [&"bamboo", &"characters", &"dots"]}
