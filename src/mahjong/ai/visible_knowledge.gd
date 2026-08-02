extends RefCounted

var discards: Array[Dictionary] = []
var open_groups: Array[Dictionary] = []


func observe_discard(player: int, tile) -> void:
	if tile == null:
		return
	discards.append({"player": player, "tile": tile.key()})


func observe_open_group(player: int, tiles: Array) -> void:
	var keys: Array[String] = []
	for tile in tiles:
		if tile != null:
			keys.append(tile.key())
	open_groups.append({"player": player, "tiles": keys})


func seen_identity_count(identity_key: String) -> int:
	var count := 0
	for discard in discards:
		if String(discard["tile"]).begins_with("%s|" % identity_key):
			count += 1
	for group in open_groups:
		for tile_key in group["tiles"]:
			if String(tile_key).begins_with("%s|" % identity_key):
				count += 1
	return count


func snapshot() -> Dictionary:
	return {"discards": discards.duplicate(true), "open_groups": open_groups.duplicate(true)}
