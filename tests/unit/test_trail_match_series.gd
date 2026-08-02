extends RefCounted

const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")
const MatchFlow = preload("res://src/mahjong/domain/match_flow.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")
const TrailHandValidator = preload("res://src/mahjong/domain/trail_hand_validator.gd")
const WallBuilder = preload("res://src/mahjong/domain/wall_builder.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_showdown_series(failures)
	_test_replay_reconstruction(failures)
	_test_high_noon_and_brand_abilities(failures)
	_test_brand_claims_in_flow(failures)
	_test_generated_validation(failures)
	return failures


func _test_showdown_series(failures: Array[String]) -> void:
	var flow = MatchFlow.new(2026)
	if flow.start_match() != OK or flow.hand_name() != &"morning":
		failures.append("a match must start at the named Morning Hand")
	for hand_index in 4:
		if not _exhaust_current_hand(flow):
			failures.append("a Trail Rules hand should be able to exhaust legally")
			return
		if flow.advance_match() != OK:
			failures.append("each completed hand should advance the match")
			return
		if hand_index < 3 and flow.hand_name() != MatchFlow.HAND_NAMES[hand_index + 1]:
			failures.append("standard hands must advance in their named order")
	if flow.hand_name() != &"showdown" or flow.dealer != 0:
		failures.append("a tied four-hand match must enter a dealer-alternating Showdown")
	if not _exhaust_current_hand(flow) or flow.advance_match() != OK or flow.phase != MatchFlow.Phase.MATCH_COMPLETE:
		failures.append("a Showdown must resolve into a completed match")
	if flow.hand_results.size() != 5:
		failures.append("match history must retain all four hands and a tie Showdown")
	if flow.draw() != ERR_INVALID_DATA or flow.discard_at(-1) != ERR_INVALID_DATA:
		failures.append("match flow must reject actions outside the active turn phase")


func _test_replay_reconstruction(failures: Array[String]) -> void:
	var flow = MatchFlow.new(811)
	flow.start_match()
	flow.discard_at(0)
	flow.draw()
	flow.discard_at(0)
	var rebuilt = MatchFlow.rebuild_from_replay(flow.replay.snapshot())
	if rebuilt == null or rebuilt.snapshot() != flow.snapshot():
		failures.append("seed plus action history must reconstruct the exact match state")
	var turn_start = MatchFlow.new(812)
	turn_start.start_match()
	var legal_turn_snapshot := turn_start.snapshot()
	var undo_rebuilt = MatchFlow.rebuild_from_replay(turn_start.replay.snapshot())
	turn_start.discard_at(0)
	if undo_rebuilt == null or undo_rebuilt.snapshot() != legal_turn_snapshot:
		failures.append("a replay checkpoint should restore the legal state before a turn action")


func _test_high_noon_and_brand_abilities(failures: Array[String]) -> void:
	var high_noon_flow = MatchFlow.new(16)
	high_noon_flow.start_match()
	high_noon_flow.hands[0] = _waiting_hand()
	high_noon_flow.turn_player = 0
	high_noon_flow.phase = MatchFlow.Phase.DRAW
	high_noon_flow.wall = [_tile(&"red", 0, &"green")]
	if high_noon_flow.declare_high_noon() != OK or high_noon_flow.draw() != OK:
		failures.append("a waiting player must be able to declare and win at High Noon")
	else:
		var award: Dictionary = high_noon_flow.hand_results.back()["award"]
		if not _has_deed(award["deeds"], "quickdraw"):
			failures.append("a High Noon victory must receive the Quickdraw Renown deed")
	var orange_flow = MatchFlow.new(17)
	orange_flow.start_match()
	orange_flow.brand_state(0)._activations[&"orange"] = 1
	var orange_hand_size: int = orange_flow.hands[0].size()
	var orange_wall_size: int = orange_flow.wall.size()
	if orange_flow.activate_orange(0) != OK or orange_flow.hands[0].size() != orange_hand_size + 1 or orange_flow.wall.size() != orange_wall_size - 1:
		failures.append("Orange must draw two, retain one, and return one tile to the wall bottom")
	var blue_flow = MatchFlow.new(18)
	blue_flow.start_match()
	blue_flow.discard_at(0)
	blue_flow.draw()
	blue_flow.discard_at(0)
	blue_flow.brand_state(0)._activations[&"blue"] = 1
	if blue_flow.activate_blue(0) != OK or blue_flow.phase != MatchFlow.Phase.DISCARD or blue_flow.hands[0].size() != 11:
		failures.append("Blue must recover one of its two latest discards before a replacement discard")


func _test_brand_claims_in_flow(failures: Array[String]) -> void:
	var blue_flow = MatchFlow.new(19)
	blue_flow.configure_loadouts([&"orange", &"blue"], [&"dark", &"blue"])
	blue_flow.start_match()
	blue_flow.turn_player = 1
	blue_flow.phase = MatchFlow.Phase.DRAW
	blue_flow.hands[1] = _claim_hand()
	blue_flow.discard_river.append({"player": 0, "tile": _tile(&"dots", 3, &"orange"), "claimed": false})
	if blue_flow.claim_brand_group_from_last_discard(1, &"blue_run", [0, 1]) != OK:
		failures.append("Blue's non-winning Run claim must be legal in the live match flow")
	elif blue_flow.open_groups[1].size() != 1 or blue_flow.combined_hand(1).size() != 11:
		failures.append("a Brand claim must convert the selected tiles into a visible open group")
	var replay_flow: Variant = _find_blue_claim_flow()
	var rebuilt: Variant = MatchFlow.rebuild_from_replay(replay_flow.replay.snapshot()) if replay_flow != null else null
	if replay_flow == null or rebuilt == null or rebuilt.snapshot() != replay_flow.snapshot():
		failures.append("Brand claims must be preserved by deterministic replay reconstruction")
	var orange_flow = MatchFlow.new(20)
	orange_flow.configure_loadouts([&"orange", &"blue"], [&"orange", &"dark"])
	orange_flow.start_match()
	orange_flow.turn_player = 1
	orange_flow.phase = MatchFlow.Phase.DRAW
	orange_flow.hands[1] = _claim_hand()
	orange_flow.discard_river.append({"player": 0, "tile": _tile(&"dots", 3, &"blue"), "claimed": false})
	if orange_flow.claim_brand_group_from_last_discard(1, &"orange_group", [0, 1]) != OK or orange_flow.brand_state(0).charges(&"orange") != 1:
		failures.append("Orange's live claim must grant the opponent one charge")


func _test_generated_validation(failures: Array[String]) -> void:
	for seed in 512:
		var wall := WallBuilder.build_trail_wall(seed)
		TrailHandValidator.is_winning_hand(wall.slice(0, 11))
	if failures.size() > 0:
		return


func _exhaust_current_hand(flow) -> bool:
	var safety := 0
	while flow.phase == MatchFlow.Phase.DRAW or flow.phase == MatchFlow.Phase.DISCARD:
		safety += 1
		if safety > 220:
			return false
		if flow.phase == MatchFlow.Phase.DISCARD:
			if flow.discard_at(0) != OK:
				return false
		elif flow.draw() != OK and flow.phase != MatchFlow.Phase.EXHAUSTED:
			return false
	return flow.phase == MatchFlow.Phase.EXHAUSTED


func _has_deed(deeds: Array, deed_id: String) -> bool:
	for deed_value in deeds:
		if deed_value is Dictionary and String(deed_value.get("id", "")) == deed_id:
			return true
	return false


func _waiting_hand() -> Array:
	return [
		_tile(&"dots", 1, &"blue"), _tile(&"dots", 2, &"dark"), _tile(&"dots", 3, &"green"),
		_tile(&"bamboo", 4, &"orange"), _tile(&"bamboo", 5, &"pink"), _tile(&"bamboo", 6, &"purple"),
		_tile(&"east", 0, &"blue"), _tile(&"east", 0, &"dark"), _tile(&"east", 0, &"green"),
		_tile(&"red", 0, &"orange"),
	]


func _claim_hand() -> Array:
	return [
		_tile(&"dots", 1, &"blue"), _tile(&"dots", 2, &"dark"),
		_tile(&"bamboo", 1, &"green"), _tile(&"bamboo", 2, &"orange"),
		_tile(&"characters", 1, &"pink"), _tile(&"characters", 2, &"purple"),
		_tile(&"east", 0, &"blue"), _tile(&"south", 0, &"dark"),
		_tile(&"west", 0, &"green"), _tile(&"north", 0, &"orange"),
	]


func _find_blue_claim_flow():
	for seed in 256:
		var flow = MatchFlow.new(seed)
		flow.configure_loadouts([&"orange", &"blue"], [&"dark", &"blue"])
		flow.start_match()
		for discard_index in flow.hands[0].size():
			var discard: Variant = flow.hands[0][discard_index]
			if not discard.identity.is_numbered():
				continue
			for first_index in flow.hands[1].size():
				for second_index in range(first_index + 1, flow.hands[1].size()):
					if _forms_run(discard, flow.hands[1][first_index], flow.hands[1][second_index]):
						flow.discard_at(discard_index)
						if flow.claim_brand_group_from_last_discard(1, &"blue_run", [first_index, second_index]) == OK:
							return flow
	return null


func _forms_run(first, second, third) -> bool:
	if not first.identity.is_numbered() or not second.identity.is_numbered() or not third.identity.is_numbered():
		return false
	if first.identity.suit != second.identity.suit or first.identity.suit != third.identity.suit:
		return false
	var ranks: Array[int] = [first.identity.rank, second.identity.rank, third.identity.rank]
	ranks.sort()
	return ranks == [ranks[0], ranks[0] + 1, ranks[0] + 2]


func _tile(suit: StringName, rank: int, brand: StringName) -> RefCounted:
	return MahjongTile.new(TileIdentity.new(suit, rank), brand)
