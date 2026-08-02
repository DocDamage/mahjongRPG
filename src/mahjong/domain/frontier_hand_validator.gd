extends RefCounted

const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")

const HAND_SIZE := 14


static func is_winning_hand(tiles: Array) -> bool:
	return not decompose_hand(tiles).is_empty()


static func decompose_hand(tiles: Array) -> Array[Dictionary]:
	if tiles.size() < HAND_SIZE or tiles.size() > HAND_SIZE + 4:
		return []
	var counts := _identity_counts(tiles)
	if counts.is_empty():
		return []
	for pair_key_value in counts.keys():
		var pair_key := String(pair_key_value)
		if int(counts[pair_key]) < 2:
			continue
		counts[pair_key] -= 2
		var groups: Array = _find_groups(counts, 4)
		counts[pair_key] += 2
		if not groups.is_empty():
			return [{"pair": pair_key, "groups": groups}]
	return []


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


static func _identity_counts(tiles: Array) -> Dictionary:
	var counts := {}
	for tile in tiles:
		if tile == null or tile.identity == null or not tile.identity.is_valid():
			return {}
		var key: String = tile.identity_key()
		counts[key] = int(counts.get(key, 0)) + 1
	return counts


static func _find_groups(counts: Dictionary, remaining: int) -> Array[Dictionary]:
	if remaining == 0:
		return [{}] if _remaining_count(counts) == 0 else []
	var key: String = _first_key(counts)
	if key.is_empty():
		return []
	if int(counts[key]) >= 4:
		counts[key] -= 4
		var quad: Array = _find_groups(counts, remaining - 1)
		counts[key] += 4
		if not quad.is_empty():
			quad.push_front({"kind": "quad", "keys": [key, key, key, key]})
			return quad
	if int(counts[key]) >= 3:
		counts[key] -= 3
		var set_group: Array = _find_groups(counts, remaining - 1)
		counts[key] += 3
		if not set_group.is_empty():
			set_group.push_front({"kind": "set", "keys": [key, key, key]})
			return set_group
	var identity: Dictionary = _identity_from_key(key)
	var one := "%s:%d" % [identity.suit, identity.rank + 1]
	var two := "%s:%d" % [identity.suit, identity.rank + 2]
	if identity.numbered and identity.rank <= 7 and counts.get(one, 0) > 0 and counts.get(two, 0) > 0:
		counts[key] -= 1; counts[one] -= 1; counts[two] -= 1
		var run: Array = _find_groups(counts, remaining - 1)
		counts[key] += 1; counts[one] += 1; counts[two] += 1
		if not run.is_empty():
			run.push_front({"kind": "run", "keys": [key, one, two]})
			return run
	return []


static func _first_key(counts: Dictionary) -> String:
	var keys: Array = counts.keys(); keys.sort()
	for key in keys:
		if counts[key] > 0:
			return key
	return ""


static func _remaining_count(counts: Dictionary) -> int:
	var total := 0
	for value in counts.values(): total += value
	return total


static func _identity_from_key(key: String) -> Dictionary:
	var pieces := key.split(":")
	var suit := StringName(pieces[0])
	return {"suit": suit, "rank": int(pieces[1]), "numbered": suit in [&"dots", &"bamboo", &"characters"]}
