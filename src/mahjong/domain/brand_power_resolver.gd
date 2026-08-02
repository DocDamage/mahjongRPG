extends RefCounted


static func activate_orange(flow, keep_draw_index: int) -> Error:
	if flow.phase != flow.Phase.DISCARD or flow.high_noon_state(flow.turn_player).active:
		return ERR_INVALID_DATA
	var charges: Variant = flow.brand_state(flow.turn_player)
	if not charges.equipped.has(&"orange") or not charges.consume_activation(&"orange") or flow.wall.size() < 2:
		return ERR_UNAVAILABLE
	if keep_draw_index < 0 or keep_draw_index > 1:
		return ERR_INVALID_PARAMETER
	var drawn_first: Variant = flow._draw_from_wall()
	var drawn_second: Variant = flow._draw_from_wall()
	var drawn := [drawn_first, drawn_second]
	var kept: Variant = drawn[keep_draw_index]
	var returned: Variant = drawn[1 - keep_draw_index]
	flow.hands[flow.turn_player].append(kept)
	flow.wall.push_front(returned)
	flow._log(&"orange_activated", {"player": flow.turn_player, "kept": kept.key(), "returned": returned.key()})
	return OK


static func activate_blue(flow, recent_discard_index: int) -> Error:
	if flow.phase != flow.Phase.DRAW or flow.high_noon_state(flow.turn_player).active:
		return ERR_INVALID_DATA
	var charges: Variant = flow.brand_state(flow.turn_player)
	if not charges.equipped.has(&"blue") or not charges.consume_activation(&"blue"):
		return ERR_UNAVAILABLE
	var eligible: Array[int] = []
	for river_index in range(flow.discard_river.size() - 1, -1, -1):
		var entry: Dictionary = flow.discard_river[river_index]
		if int(entry.get("player", -1)) == flow.turn_player and not bool(entry.get("claimed", false)):
			eligible.append(river_index)
			if eligible.size() == 2:
				break
	if recent_discard_index < 0 or recent_discard_index >= eligible.size():
		return ERR_INVALID_PARAMETER
	var selected_index: int = eligible[recent_discard_index]
	var selected: Dictionary = flow.discard_river[selected_index]
	flow.discard_river.remove_at(selected_index)
	flow.hands[flow.turn_player].append(selected["tile"])
	flow.phase = flow.Phase.DISCARD
	flow._log(&"blue_activated", {"player": flow.turn_player, "reclaimed": selected["tile"].key()})
	return OK
