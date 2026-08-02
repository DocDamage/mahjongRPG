extends RefCounted

const ClaimResolver = preload("res://src/mahjong/domain/claim_resolver.gd")
const MatchRuleset = preload("res://src/mahjong/domain/match_ruleset.gd")


static func claim_win_from_last_discard(flow, player: int) -> Error:
	if flow.phase != flow.Phase.DRAW or player != flow.turn_player or player < 0 or player > 1: return ERR_INVALID_DATA
	var discard_index: int = flow._last_claimable_discard_index()
	if discard_index < 0: return ERR_UNAVAILABLE
	var discard: Dictionary = flow.discard_river[discard_index]
	var tile = discard.get("tile")
	var candidate: Array = flow.combined_hand(player); candidate.append(tile)
	if not flow.is_winning_hand(candidate): return ERR_INVALID_DATA
	discard["claimed"] = true; flow.discard_river[discard_index] = discard; flow.hands[player].append(tile)
	flow._complete_hand(player, &"discard_claim", false); flow._log(&"claim_win", {"player": player, "tile": tile.key()})
	return OK


static func claim_brand_group_from_last_discard(flow, player: int, kind: StringName, hand_indices: Array[int]) -> Error:
	if flow.phase != flow.Phase.DRAW or player != flow.turn_player or not _expected_indices(kind, hand_indices.size()): return ERR_INVALID_DATA
	if kind == &"frontier_quad" and flow.ruleset != MatchRuleset.FRONTIER: return ERR_INVALID_DATA
	var discard_index: int = flow._last_claimable_discard_index()
	if discard_index < 0: return ERR_UNAVAILABLE
	var indices: Array[int] = hand_indices.duplicate(); indices.sort()
	if indices.is_empty() or indices[0] < 0 or indices.back() >= flow.hands[player].size() or _has_duplicates(indices): return ERR_INVALID_PARAMETER
	var discard: Dictionary = flow.discard_river[discard_index]
	var winning_candidate: Array = flow.combined_hand(player); winning_candidate.append(discard["tile"])
	if flow.is_winning_hand(winning_candidate): return ERR_ALREADY_IN_USE
	var selected: Array = []
	for index in indices: selected.append(flow.hands[player][index])
	var resolved := ClaimResolver.resolve(discard["tile"], [{"player": player, "kind": String(kind), "equipped": flow.brand_state(player).equipped, "tiles": selected}])
	if resolved.is_empty() or StringName(resolved.get("kind", "")) != kind: return ERR_INVALID_DATA
	for offset in range(indices.size() - 1, -1, -1): flow.hands[player].remove_at(indices[offset])
	discard["claimed"] = true; flow.discard_river[discard_index] = discard; selected.append(discard["tile"]); flow.open_groups[player].append(selected)
	if kind == &"orange_group": flow.brand_state(1 - player).grant_charge(flow.brand_state(1 - player).equipped[0])
	if kind == &"frontier_quad" and not flow.wall.is_empty():
		flow.hands[player].append(flow._draw_from_wall())
		flow._log(&"quad_replacement", {"player": player})
	flow._log(&"brand_claim", {"player": player, "kind": String(kind), "tiles": _tile_keys(selected)}); flow.phase = flow.Phase.DISCARD
	return OK


static func _expected_indices(kind: StringName, count: int) -> bool:
	return count == 1 if kind == &"pink_pair" else count == 3 if kind == &"frontier_quad" else count == 2


static func _has_duplicates(indices: Array[int]) -> bool:
	for index in range(1, indices.size()):
		if indices[index] == indices[index - 1]: return true
	return false


static func _tile_keys(tiles: Array) -> Array[String]:
	var keys: Array[String] = []
	for tile in tiles:
		if tile != null: keys.append(tile.key())
	return keys
