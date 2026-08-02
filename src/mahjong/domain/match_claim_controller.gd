extends RefCounted

const ClaimResolver = preload("res://src/mahjong/domain/claim_resolver.gd")
const TrailHandValidator = preload("res://src/mahjong/domain/trail_hand_validator.gd")


static func claim_win_from_last_discard(flow, player: int) -> Error:
	if flow.phase != flow.Phase.DRAW or player != flow.turn_player or player < 0 or player > 1:
		return ERR_INVALID_DATA
	var discard_index: int = flow._last_claimable_discard_index()
	if discard_index < 0:
		return ERR_UNAVAILABLE
	var discard: Dictionary = flow.discard_river[discard_index]
	var tile: Variant = discard.get("tile")
	var candidate: Array = flow.combined_hand(player)
	candidate.append(tile)
	if not TrailHandValidator.is_winning_hand(candidate):
		return ERR_INVALID_DATA
	discard["claimed"] = true
	flow.discard_river[discard_index] = discard
	flow.hands[player].append(tile)
	flow._complete_hand(player, &"discard_claim", false)
	flow._log(&"claim_win", {"player": player, "tile": tile.key()})
	return OK


static func claim_brand_group_from_last_discard(flow, player: int, kind: StringName, hand_indices: Array[int]) -> Error:
	if flow.phase != flow.Phase.DRAW or player != flow.turn_player or hand_indices.size() != 2:
		return ERR_INVALID_DATA
	var discard_index: int = flow._last_claimable_discard_index()
	if discard_index < 0:
		return ERR_UNAVAILABLE
	var hand: Array = flow.hands[player]
	var selected: Array = []
	var indices: Array[int] = hand_indices.duplicate()
	indices.sort()
	if indices[0] < 0 or indices[1] >= hand.size() or indices[0] == indices[1]:
		return ERR_INVALID_PARAMETER
	for index in indices:
		selected.append(hand[index])
	var discard: Dictionary = flow.discard_river[discard_index]
	var tile: Variant = discard["tile"]
	var winning_candidate: Array = flow.combined_hand(player)
	winning_candidate.append(tile)
	if TrailHandValidator.is_winning_hand(winning_candidate):
		return ERR_ALREADY_IN_USE
	var claim := {"player": player, "kind": String(kind), "equipped": flow.brand_state(player).equipped, "tiles": selected}
	var resolved := ClaimResolver.resolve(tile, [claim])
	if resolved.is_empty() or String(resolved.get("kind", "")) != String(kind):
		return ERR_INVALID_DATA
	for index_value in range(indices.size() - 1, -1, -1):
		hand.remove_at(indices[index_value])
	discard["claimed"] = true
	flow.discard_river[discard_index] = discard
	selected.append(tile)
	flow.open_groups[player].append(selected)
	if kind == &"orange_group":
		var opponent_state: Variant = flow.brand_state(1 - player)
		opponent_state.grant_charge(opponent_state.equipped[0])
	flow._log(&"brand_claim", {"player": player, "kind": String(kind), "tiles": _tile_keys(selected)})
	flow.phase = flow.Phase.DISCARD
	return OK


static func _tile_keys(tiles: Array) -> Array[String]:
	var keys: Array[String] = []
	for tile in tiles:
		if tile != null:
			keys.append(tile.key())
	return keys
