extends RefCounted

const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")

const HAND_SIZE := 11


static func is_winning_hand(tiles: Array) -> bool:
	return not decompose_hand(tiles).is_empty()


static func decompose_hand(tiles: Array) -> Array[Dictionary]:
	if tiles.size() != HAND_SIZE:
		return []
	var counts := _identity_counts(tiles)
	if counts.is_empty():
		return []
	var pair_keys: Array = counts.keys()
	pair_keys.sort()
	for pair_key_value in pair_keys:
		var pair_key: String = pair_key_value
		if int(counts[pair_key]) < 2:
			continue
		counts[pair_key] = int(counts[pair_key]) - 2
		var groups := _find_groups(counts, 3)
		counts[pair_key] = int(counts[pair_key]) + 2
		if not groups.is_empty():
			return [{"pair": pair_key, "groups": groups}]
	return []


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
	return not _find_groups(counts, groups_remaining).is_empty()


static func _find_groups(counts: Dictionary, groups_remaining: int) -> Array[Dictionary]:
	if groups_remaining == 0:
		var terminal: Array[Dictionary] = []
		if _remaining_tile_count(counts) == 0:
			terminal.append({})
		return terminal
	var first_key: String = _first_nonzero_key(counts)
	if first_key.is_empty():
		var no_groups: Array[Dictionary] = []
		return no_groups
	if counts[first_key] >= 3:
		counts[first_key] -= 3
		var set_groups := _find_groups(counts, groups_remaining - 1)
		counts[first_key] += 3
		if not set_groups.is_empty():
			set_groups.push_front({"kind": "set", "keys": [first_key, first_key, first_key]})
			return set_groups
	var identity: Dictionary = _identity_from_key(first_key)
	if identity["numbered"]:
		var next_one: String = "%s:%d" % [identity["suit"], identity["rank"] + 1]
		var next_two: String = "%s:%d" % [identity["suit"], identity["rank"] + 2]
		if identity["rank"] <= 7 and counts.get(next_one, 0) > 0 and counts.get(next_two, 0) > 0:
			counts[first_key] -= 1
			counts[next_one] -= 1
			counts[next_two] -= 1
			var run_groups := _find_groups(counts, groups_remaining - 1)
			counts[first_key] += 1
			counts[next_one] += 1
			counts[next_two] += 1
			if not run_groups.is_empty():
				run_groups.push_front({"kind": "run", "keys": [first_key, next_one, next_two]})
				return run_groups
	var no_solution: Array[Dictionary] = []
	return no_solution


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
