extends RefCounted


static func activate_orange(flow, keep_draw_index: int) -> Error:
	if flow.phase != flow.Phase.DISCARD or flow.high_noon_state(flow.turn_player).active: return ERR_INVALID_DATA
	var count := 3 if flow.upgrade_rank(flow.turn_player, &"orange") > 0 else 2
	if not _can_activate(flow, &"orange") or flow.wall.size() < count or keep_draw_index < 0 or keep_draw_index >= count: return ERR_UNAVAILABLE
	_consume(flow, &"orange")
	var drawn: Array = []
	for ignored in count: drawn.append(flow._draw_from_wall())
	var kept = drawn[keep_draw_index]; flow.hands[flow.turn_player].append(kept)
	for index in range(drawn.size() - 1, -1, -1):
		if index != keep_draw_index: flow.wall.push_front(drawn[index])
	flow._log(&"orange_activated", {"player": flow.turn_player, "kept": kept.key(), "draw_count": count})
	return OK


static func activate_blue(flow, recent_discard_index: int) -> Error:
	if flow.phase != flow.Phase.DRAW or flow.high_noon_state(flow.turn_player).active: return ERR_INVALID_DATA
	var eligible := _own_discards(flow, 3 if flow.upgrade_rank(flow.turn_player, &"blue") > 0 else 2)
	if not _can_activate(flow, &"blue") or recent_discard_index < 0 or recent_discard_index >= eligible.size(): return ERR_INVALID_PARAMETER
	_consume(flow, &"blue")
	var selected_index: int = eligible[recent_discard_index]
	var selected: Dictionary = flow.discard_river[selected_index]
	flow.discard_river.remove_at(selected_index); flow.hands[flow.turn_player].append(selected["tile"]); flow.phase = flow.Phase.DISCARD
	flow._log(&"blue_activated", {"player": flow.turn_player, "reclaimed": selected["tile"].key()})
	return OK


static func activate_green(flow, hand_index: int) -> Error:
	if flow.phase != flow.Phase.DISCARD or hand_index < 0 or hand_index >= flow.hands[flow.turn_player].size(): return ERR_INVALID_DATA
	var corral: Array = flow.corrals[flow.turn_player]
	var capacity := 2 if flow.upgrade_rank(flow.turn_player, &"green") > 0 else 1
	if not _can_activate(flow, &"green") or corral.size() >= capacity or flow.wall.is_empty(): return ERR_UNAVAILABLE
	_consume(flow, &"green")
	corral.append(flow.hands[flow.turn_player][hand_index]); flow.hands[flow.turn_player].remove_at(hand_index); flow.hands[flow.turn_player].append(flow._draw_from_wall())
	flow._log(&"green_activated", {"player": flow.turn_player, "stored": corral.back().key()})
	return OK


static func release_green(flow) -> Error:
	if flow.phase != flow.Phase.DRAW or flow.corrals[flow.turn_player].is_empty(): return ERR_UNAVAILABLE
	flow.hands[flow.turn_player].append(flow.corrals[flow.turn_player].pop_front()); flow.phase = flow.Phase.DISCARD
	flow._log(&"green_released", {"player": flow.turn_player})
	return OK


static func activate_pink(flow, hand_index: int) -> Error:
	if flow.phase != flow.Phase.DISCARD or hand_index < 0 or hand_index >= flow.hands[flow.turn_player].size(): return ERR_INVALID_DATA
	var capacity := 2 if flow.upgrade_rank(flow.turn_player, &"pink") > 0 else 1
	if not _can_activate(flow, &"pink") or (flow.neutral_tiles.size() < capacity and flow.wall.is_empty()): return ERR_UNAVAILABLE
	_consume(flow, &"pink")
	var selected = flow.hands[flow.turn_player][hand_index]
	flow.hands[flow.turn_player].remove_at(hand_index)
	if flow.neutral_tiles.size() < capacity:
		flow.neutral_tiles.append(selected)
		if flow.wall.is_empty(): return ERR_UNAVAILABLE
		flow.hands[flow.turn_player].append(flow._draw_from_wall())
		flow._log(&"pink_offered", {"player": flow.turn_player, "tile": selected.key()})
		return OK
	var exchanged = flow.neutral_tiles.pop_front(); flow.neutral_tiles.append(selected); flow.hands[flow.turn_player].append(exchanged)
	flow._log(&"pink_exchanged", {"player": flow.turn_player, "offered": selected.key(), "received": exchanged.key()})
	return OK


static func activate_dark(flow) -> Error:
	if flow.phase != flow.Phase.DRAW: return ERR_INVALID_DATA
	var index: int = flow._last_claimable_discard_index()
	if not _can_activate(flow, &"dark") or index < 0: return ERR_UNAVAILABLE
	_consume(flow, &"dark")
	var discard: Dictionary = flow.discard_river[index]; discard["unclaimable"] = true; flow.discard_river[index] = discard
	if flow.upgrade_rank(flow.turn_player, &"dark") > 0 and not flow.wall.is_empty():
		flow.hands[flow.turn_player].append(flow._draw_from_wall())
		flow.phase = flow.Phase.DISCARD
	flow._log(&"dark_activated", {"player": flow.turn_player, "tile": discard["tile"].key()})
	return OK


static func activate_purple(flow, order: Array[int]) -> Error:
	if flow.phase != flow.Phase.DISCARD: return ERR_INVALID_DATA
	var count := 4 if flow.upgrade_rank(flow.turn_player, &"purple") > 0 else 3
	if not _can_activate(flow, &"purple") or flow.wall.size() < count or not _is_permutation(order, count): return ERR_INVALID_PARAMETER
	_consume(flow, &"purple")
	var next: Array = []
	for ignored in count: next.append(flow._draw_from_wall())
	for index in range(count - 1, -1, -1): flow.wall.append(next[order[index]])
	flow._log(&"purple_activated", {"player": flow.turn_player, "order": order.duplicate(), "revealed": _tile_keys(next)})
	return OK


static func _can_activate(flow, brand: StringName) -> bool:
	var charges = flow.brand_state(flow.turn_player)
	return not flow.high_noon_state(flow.turn_player).active and charges.equipped.has(brand) and charges.activations(brand) > 0


static func _consume(flow, brand: StringName) -> void:
	flow.brand_state(flow.turn_player).consume_activation(brand)


static func _own_discards(flow, limit: int) -> Array[int]:
	var eligible: Array[int] = []
	for index in range(flow.discard_river.size() - 1, -1, -1):
		var entry: Dictionary = flow.discard_river[index]
		if int(entry.get("player", -1)) == flow.turn_player and not bool(entry.get("claimed", false)):
			eligible.append(index)
			if eligible.size() == limit: break
	return eligible


static func _is_permutation(order: Array[int], count: int) -> bool:
	if order.size() != count: return false
	var sorted := order.duplicate(); sorted.sort()
	return sorted == range(count)


static func _tile_keys(tiles: Array) -> Array[String]:
	var keys: Array[String] = []
	for tile in tiles: keys.append(tile.key())
	return keys
