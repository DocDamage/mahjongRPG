extends RefCounted

const DRAW_PHASE := 0
const DISCARD_PHASE := 1


static func snapshot_from_flow(flow) -> Dictionary:
	return {
		"seed": flow.seed,
		"hand_number": flow.hand_number,
		"phase": flow.phase,
		"turn_player": flow.turn_player,
		"dealer": flow.dealer,
		"renown": flow.renown.duplicate(),
		"hand_results": flow.hand_results.duplicate(true),
		"match_winner": flow.match_winner,
		"hands": [_tile_keys(flow.hands[0]), _tile_keys(flow.hands[1])],
		"open_groups": [_groups_snapshot(flow.open_groups[0]), _groups_snapshot(flow.open_groups[1])],
		"wall": _tile_keys(flow.wall),
		"discard_river": _river_snapshot(flow.discard_river),
	}


static func rebuild_from_replay(replay_snapshot: Dictionary):
	var seed_value := int(replay_snapshot.get("seed", 0))
	var rebuilt: Variant = load("res://src/mahjong/domain/match_flow.gd").new(seed_value)
	rebuilt._suppress_replay = true
	var actions_value: Variant = replay_snapshot.get("actions", [])
	if not actions_value is Array:
		return null
	for action_value in actions_value:
		if not action_value is Dictionary:
			return null
		var action: Dictionary = action_value
		var action_type := String(action.get("type", ""))
		var payload_value: Variant = action.get("payload", {})
		if not payload_value is Dictionary:
			return null
		var payload: Dictionary = payload_value
		if action_type == "loadouts_configured":
			var first_value: Variant = payload.get("player_0", [])
			var second_value: Variant = payload.get("player_1", [])
			if not first_value is Array or not second_value is Array or rebuilt.configure_loadouts(first_value, second_value) != OK:
				return null
		elif action_type == "hand_started":
			if rebuilt.start_hand(int(payload.get("hand", -1))) != OK:
				return null
		elif action_type == "draw":
			if rebuilt.phase == DRAW_PHASE and rebuilt.draw() != OK:
				return null
		elif action_type == "discard":
			if bool(payload.get("automatic", false)):
				continue
			if rebuilt.phase != DISCARD_PHASE or not rebuilt._discard_key(String(payload.get("tile", ""))):
				return null
		elif action_type == "win":
			if String(payload.get("source", "")) != "high_noon_draw" and rebuilt.declare_win() != OK:
				return null
		elif action_type == "claim_win":
			if rebuilt.claim_win_from_last_discard(int(payload.get("player", -1))) != OK:
				return null
		elif action_type == "high_noon_declared":
			if rebuilt.declare_high_noon() != OK:
				return null
		elif action_type == "orange_activated":
			if _replay_orange(rebuilt, String(payload.get("kept", ""))) != OK:
				return null
		elif action_type == "blue_activated":
			if _replay_blue(rebuilt, String(payload.get("reclaimed", ""))) != OK:
				return null
		elif action_type == "brand_claim":
			if _replay_brand_claim(rebuilt, StringName(payload.get("kind", "")), _as_keys(payload.get("tiles", []))) != OK:
				return null
		elif action_type == "match_completed":
			rebuilt._finish_match()
	rebuilt._suppress_replay = false
	return rebuilt


static func _replay_orange(flow, kept_key: String) -> Error:
	if flow.wall.size() < 2:
		return ERR_UNAVAILABLE
	var first: Variant = flow.wall.back()
	var second: Variant = flow.wall[flow.wall.size() - 2]
	if first.key() == kept_key:
		return flow.activate_orange(0)
	if second.key() == kept_key:
		return flow.activate_orange(1)
	return ERR_INVALID_DATA


static func _replay_blue(flow, reclaimed_key: String) -> Error:
	var replay_index := 0
	for river_index in range(flow.discard_river.size() - 1, -1, -1):
		var entry: Dictionary = flow.discard_river[river_index]
		if int(entry.get("player", -1)) != flow.turn_player or bool(entry.get("claimed", false)):
			continue
		if entry["tile"].key() == reclaimed_key:
			return flow.activate_blue(replay_index)
		replay_index += 1
		if replay_index == 2:
			break
	return ERR_INVALID_DATA


static func _replay_brand_claim(flow, kind: StringName, tile_keys: Array[String]) -> Error:
	if tile_keys.size() != 3:
		return ERR_INVALID_DATA
	var indices: Array[int] = []
	for tile_key in tile_keys.slice(0, 2):
		for index in flow.hands[flow.turn_player].size():
			if index not in indices and flow.hands[flow.turn_player][index].key() == tile_key:
				indices.append(index)
				break
	if indices.size() != 2:
		return ERR_INVALID_DATA
	return flow.claim_brand_group_from_last_discard(flow.turn_player, kind, indices)


static func _tile_keys(tiles: Array) -> Array[String]:
	var keys: Array[String] = []
	for tile in tiles:
		if tile != null:
			keys.append(tile.key())
	return keys


static func _river_snapshot(entries: Array) -> Array[Dictionary]:
	var snapshot_entries: Array[Dictionary] = []
	for entry in entries:
		snapshot_entries.append({"player": entry["player"], "tile": entry["tile"].key(), "claimed": entry["claimed"]})
	return snapshot_entries


static func _groups_snapshot(groups: Array) -> Array:
	var result: Array = []
	for group in groups:
		result.append(_tile_keys(group))
	return result


static func _as_keys(value) -> Array[String]:
	var keys: Array[String] = []
	if value is Array:
		for key_value in value:
			keys.append(String(key_value))
	return keys
