extends RefCounted

const DRAW_PHASE := 0
const DISCARD_PHASE := 1


static func snapshot_from_flow(flow) -> Dictionary:
	return {"seed": flow.seed, "ruleset": String(flow.ruleset), "hand_number": flow.hand_number, "phase": flow.phase, "turn_player": flow.turn_player, "dealer": flow.dealer, "renown": flow.renown.duplicate(), "hand_results": flow.hand_results.duplicate(true), "match_winner": flow.match_winner, "hands": [_tile_keys(flow.hands[0]), _tile_keys(flow.hands[1])], "open_groups": [_groups_snapshot(flow.open_groups[0]), _groups_snapshot(flow.open_groups[1])], "corrals": [_tile_keys(flow.corrals[0]), _tile_keys(flow.corrals[1])], "neutral_tiles": _tile_keys(flow.neutral_tiles), "wall": _tile_keys(flow.wall), "discard_river": _river_snapshot(flow.discard_river)}


static func rebuild_from_replay(replay_snapshot: Dictionary):
	var rebuilt = load("res://src/mahjong/domain/match_flow.gd").new(int(replay_snapshot.get("seed", 0)))
	rebuilt._suppress_replay = true
	var actions: Variant = replay_snapshot.get("actions", [])
	if not actions is Array: return null
	for action_value in actions:
		if not action_value is Dictionary or not _replay_action(rebuilt, action_value): return null
	rebuilt.replay.actions = actions.duplicate(true)
	rebuilt._suppress_replay = false
	return rebuilt


static func _replay_action(flow, action: Dictionary) -> bool:
	var kind := String(action.get("type", ""))
	var payload: Variant = action.get("payload", {})
	if not payload is Dictionary: return false
	if kind == "ruleset_configured": return flow.configure_ruleset(StringName(payload.get("ruleset", ""))) == OK
	if kind == "loadouts_configured": return flow.configure_loadouts(payload.get("player_0", []), payload.get("player_1", [])) == OK
	if kind == "upgrades_configured":
		if not payload.get("player_0", {}) is Dictionary or not payload.get("player_1", {}) is Dictionary: return false
		flow.configure_upgrades(payload["player_0"], payload["player_1"]); return true
	if kind == "hand_started": return flow.start_hand(int(payload.get("hand", -1))) == OK
	if kind == "draw": return flow.phase != DRAW_PHASE or flow.draw() == OK
	if kind == "discard": return bool(payload.get("automatic", false)) or (flow.phase == DISCARD_PHASE and flow._discard_key(String(payload.get("tile", ""))))
	if kind == "win": return String(payload.get("source", "")) == "high_noon_draw" or flow.declare_win() == OK
	if kind == "claim_win": return flow.claim_win_from_last_discard(int(payload.get("player", -1))) == OK
	if kind == "high_noon_declared": return flow.declare_high_noon() == OK
	if kind == "orange_activated": return _replay_orange(flow, String(payload.get("kept", ""))) == OK
	if kind == "blue_activated": return _replay_blue(flow, String(payload.get("reclaimed", ""))) == OK
	if kind == "green_activated": return _replay_hand_power(flow, String(payload.get("stored", "")), &"green") == OK
	if kind == "green_released": return flow.release_green() == OK
	if kind in ["pink_offered", "pink_exchanged"]: return _replay_hand_power(flow, String(payload.get("offered", payload.get("tile", ""))), &"pink") == OK
	if kind == "dark_activated": return flow.activate_dark() == OK
	if kind == "purple_activated": return flow.activate_purple(payload.get("order", [])) == OK
	if kind == "brand_claim": return _replay_brand_claim(flow, StringName(payload.get("kind", "")), _as_keys(payload.get("tiles", []))) == OK
	if kind == "match_completed": flow._finish_match()
	return true


static func _replay_orange(flow, kept_key: String) -> Error:
	var count := 3 if flow.upgrade_rank(flow.turn_player, &"orange") > 0 else 2
	if flow.wall.size() < count: return ERR_UNAVAILABLE
	for index in count:
		if flow.wall[flow.wall.size() - 1 - index].key() == kept_key: return flow.activate_orange(index)
	return ERR_INVALID_DATA


static func _replay_blue(flow, reclaimed_key: String) -> Error:
	var replay_index := 0
	for index in range(flow.discard_river.size() - 1, -1, -1):
		var entry: Dictionary = flow.discard_river[index]
		if int(entry.get("player", -1)) != flow.turn_player or bool(entry.get("claimed", false)): continue
		if entry["tile"].key() == reclaimed_key: return flow.activate_blue(replay_index)
		replay_index += 1
		if replay_index == (3 if flow.upgrade_rank(flow.turn_player, &"blue") > 0 else 2): break
	return ERR_INVALID_DATA


static func _replay_hand_power(flow, key: String, brand: StringName) -> Error:
	for index in flow.hands[flow.turn_player].size():
		if flow.hands[flow.turn_player][index].key() == key:
			return flow.activate_green(index) if brand == &"green" else flow.activate_pink(index)
	return ERR_INVALID_DATA


static func _replay_brand_claim(flow, kind: StringName, tile_keys: Array[String]) -> Error:
	if tile_keys.size() < 2 or tile_keys.size() > 4: return ERR_INVALID_DATA
	var indices: Array[int] = []
	for tile_key in tile_keys.slice(0, tile_keys.size() - 1):
		for index in flow.hands[flow.turn_player].size():
			if index not in indices and flow.hands[flow.turn_player][index].key() == tile_key: indices.append(index); break
	return flow.claim_brand_group_from_last_discard(flow.turn_player, kind, indices) if indices.size() == tile_keys.size() - 1 else ERR_INVALID_DATA


static func _tile_keys(tiles: Array) -> Array[String]:
	var keys: Array[String] = []
	for tile in tiles:
		if tile != null: keys.append(tile.key())
	return keys


static func _river_snapshot(entries: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in entries: result.append({"player": entry["player"], "tile": entry["tile"].key(), "claimed": entry["claimed"], "unclaimable": entry.get("unclaimable", false)})
	return result


static func _groups_snapshot(groups: Array) -> Array:
	var result: Array = []
	for group in groups: result.append(_tile_keys(group))
	return result


static func _as_keys(value) -> Array[String]:
	var keys: Array[String] = []
	if value is Array:
		for key in value: keys.append(String(key))
	return keys
