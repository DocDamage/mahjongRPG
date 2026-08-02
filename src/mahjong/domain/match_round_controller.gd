extends RefCounted

const HandRules = preload("res://src/mahjong/domain/hand_rules.gd")
const MatchRuleset = preload("res://src/mahjong/domain/match_ruleset.gd")
const RenownCalculator = preload("res://src/mahjong/domain/renown_calculator.gd")
const WallBuilder = preload("res://src/mahjong/domain/wall_builder.gd")


static func start_hand(flow, next_hand_number: int) -> Error:
	if next_hand_number < 0 or next_hand_number >= flow.HAND_NAMES.size():
		return ERR_INVALID_PARAMETER
	if next_hand_number == flow.SHOWDOWN_HAND and (flow.hand_results.size() < flow.STANDARD_HAND_COUNT or flow.renown[0] != flow.renown[1]):
		return ERR_INVALID_DATA
	flow.hand_number = next_hand_number
	flow.dealer = flow.hand_number % 2
	flow.turn_player = flow.dealer
	flow.phase = flow.Phase.DRAW
	flow.wall = WallBuilder.build_frontier_wall(flow.seed + flow.hand_number) if flow.ruleset == MatchRuleset.FRONTIER else WallBuilder.build_trail_wall(flow.seed + flow.hand_number)
	flow.hands = [[], []]; flow.open_groups = [[], []]; flow.corrals = [[], []]; flow.neutral_tiles.clear(); flow.discard_river.clear()
	flow.high_noon_declared[0] = false
	flow.high_noon_declared[1] = false
	for player in 2:
		flow.brand_state(player).reset_for_hand()
		flow.high_noon_state(player).clear()
	flow._log(&"hand_started", {"hand": flow.hand_number, "name": String(flow.hand_name()), "dealer": flow.dealer, "ruleset": String(flow.ruleset)})
	for player in 2:
		for ignored in MatchRuleset.concealed_hand_size(flow.ruleset):
			flow.hands[player].append(flow._draw_from_wall())
	draw_for_current_player(flow)
	return OK


static func draw_for_current_player(flow) -> void:
	var tile = flow._draw_from_wall()
	if tile == null:
		exhaust_hand(flow)
		return
	flow.hands[flow.turn_player].append(tile)
	flow._log(&"draw", {"player": flow.turn_player, "tile": tile.key()})
	var high_noon = flow.high_noon_state(flow.turn_player)
	if not high_noon.active:
		flow.phase = flow.Phase.DISCARD
		return
	var wins: bool = high_noon.accepts(tile)
	var expired: bool = high_noon.consume_draw()
	if wins:
		complete_hand(flow, flow.turn_player, &"high_noon_draw", true)
		flow._log(&"win", {"player": flow.turn_player, "source": "high_noon_draw"})
		return
	var automatic = flow.hands[flow.turn_player].pop_back()
	flow._record_discard(flow.turn_player, automatic, true)
	flow.turn_player = 1 - flow.turn_player
	flow.phase = flow.Phase.DRAW
	if expired:
		flow._log(&"high_noon_expired", {"player": 1 - flow.turn_player})


static func complete_hand(flow, winner: int, source: StringName, won_at_high_noon: bool) -> void:
	flow.phase = flow.Phase.COMPLETE
	var award := {"base": 0, "deeds": [], "total": 0}
	if winner >= 0:
		award = RenownCalculator.calculate(flow.combined_hand(winner), {"equipped_brands": flow.brand_state(winner).equipped, "opponent_brands": flow.brand_state(1 - winner).equipped, "won_at_high_noon": won_at_high_noon, "won_by_draw": source != &"discard_claim", "opponent_declared_high_noon": flow.high_noon_declared[1 - winner], "ruleset": flow.ruleset})
		flow.renown[winner] += int(award["total"])
	flow.hand_results.append({"hand": flow.hand_number, "name": String(flow.hand_name()), "winner": winner, "source": String(source), "award": award.duplicate(true)})
	flow._log(&"hand_completed", {"hand": flow.hand_number, "winner": winner, "source": String(source), "renown": award["total"]})


static func exhaust_hand(flow) -> void:
	if flow.phase in [flow.Phase.EXHAUSTED, flow.Phase.COMPLETE]:
		return
	flow.phase = flow.Phase.EXHAUSTED
	flow.hand_results.append({"hand": flow.hand_number, "name": String(flow.hand_name()), "winner": -1, "source": "wall_exhausted", "award": {"base": 0, "deeds": [], "total": 0}})
	flow._log(&"wall_exhausted", {"hand": flow.hand_number})


static func finish_match(flow) -> void:
	flow.phase = flow.Phase.MATCH_COMPLETE
	flow.match_winner = 0 if flow.renown[0] > flow.renown[1] else 1 if flow.renown[1] > flow.renown[0] else -1
	flow._log(&"match_completed", {"winner": flow.match_winner, "renown": flow.renown.duplicate()})
