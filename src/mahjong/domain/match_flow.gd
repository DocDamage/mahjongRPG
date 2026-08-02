extends RefCounted

const BrandChargeState = preload("res://src/mahjong/domain/brand_charge_state.gd")
const BrandPowerResolver = preload("res://src/mahjong/domain/brand_power_resolver.gd")
const HighNoonState = preload("res://src/mahjong/domain/high_noon_state.gd")
const MatchClaimController = preload("res://src/mahjong/domain/match_claim_controller.gd")
const MatchReplayLog = preload("res://src/mahjong/domain/match_replay_log.gd")
const RenownCalculator = preload("res://src/mahjong/domain/renown_calculator.gd")
const TrailHandValidator = preload("res://src/mahjong/domain/trail_hand_validator.gd")
const WallBuilder = preload("res://src/mahjong/domain/wall_builder.gd")

enum Phase { DRAW, DISCARD, COMPLETE, EXHAUSTED, MATCH_COMPLETE }

const HAND_NAMES := [&"morning", &"high_noon", &"sundown", &"midnight", &"showdown"]
const STANDARD_HAND_COUNT := 4
const SHOWDOWN_HAND := 4
const DEFAULT_LOADOUTS := [[&"orange", &"blue"], [&"dark", &"green"]]

var seed: int
var hand_number := -1
var dealer := 0
var turn_player := 0
var phase := Phase.MATCH_COMPLETE
var wall: Array = []
var hands: Array = [[], []]
var open_groups: Array = [[], []]
var discard_river: Array[Dictionary] = []
var renown: Array[int] = [0, 0]
var hand_results: Array[Dictionary] = []
var match_winner := -1
var replay: MatchReplayLog
var brand_states: Array = []
var high_noon_states: Array = []
var high_noon_declared: Array[bool] = [false, false]
var _suppress_replay := false


func _init(match_seed: int) -> void:
	seed = match_seed
	replay = MatchReplayLog.new(seed)
	brand_states = [BrandChargeState.new(), BrandChargeState.new()]
	high_noon_states = [HighNoonState.new(), HighNoonState.new()]
	configure_loadouts(DEFAULT_LOADOUTS[0], DEFAULT_LOADOUTS[1])
func configure_loadouts(first: Array, second: Array) -> Error:
	if _brand_state(0).configure(_as_brand_loadout(first)) != OK:
		return ERR_INVALID_PARAMETER
	if _brand_state(1).configure(_as_brand_loadout(second)) != OK:
		return ERR_INVALID_PARAMETER
	_log(&"loadouts_configured", {"player_0": _brand_state(0).equipped.duplicate(), "player_1": _brand_state(1).equipped.duplicate()})
	return OK
func start_match() -> Error:
	renown = [0, 0]
	hand_results.clear()
	match_winner = -1
	return start_hand(0)
func start_hand(next_hand_number: int) -> Error:
	if next_hand_number < 0 or next_hand_number >= HAND_NAMES.size():
		return ERR_INVALID_PARAMETER
	if next_hand_number == SHOWDOWN_HAND and (hand_results.size() < STANDARD_HAND_COUNT or renown[0] != renown[1]):
		return ERR_INVALID_DATA
	hand_number = next_hand_number
	dealer = hand_number % 2
	turn_player = dealer
	phase = Phase.DRAW
	wall = WallBuilder.build_trail_wall(seed + hand_number)
	hands = [[], []]
	open_groups = [[], []]
	discard_river.clear()
	high_noon_declared = [false, false]
	for player_index in 2:
		_brand_state(player_index).reset_for_hand()
		_high_noon_state(player_index).clear()
	_log(&"hand_started", {"hand": hand_number, "name": String(HAND_NAMES[hand_number]), "dealer": dealer})
	for player_index in 2:
		for ignored in 10:
			hands[player_index].append(_draw_from_wall())
	_draw_for_current_player()
	return OK
func hand_name() -> StringName:
	if hand_number < 0 or hand_number >= HAND_NAMES.size():
		return &""
	return HAND_NAMES[hand_number]
func current_hand() -> Array:
	return hands[turn_player].duplicate()
func can_start_next_hand() -> bool:
	return phase == Phase.COMPLETE or phase == Phase.EXHAUSTED
func advance_match() -> Error:
	if not can_start_next_hand():
		return ERR_INVALID_DATA
	if hand_number < STANDARD_HAND_COUNT - 1:
		return start_hand(hand_number + 1)
	if hand_number == STANDARD_HAND_COUNT - 1 and renown[0] == renown[1]:
		return start_hand(SHOWDOWN_HAND)
	_finish_match()
	return OK
func draw() -> Error:
	if phase != Phase.DRAW:
		return ERR_INVALID_DATA
	if wall.is_empty():
		_exhaust_hand()
		return ERR_UNAVAILABLE
	_draw_for_current_player()
	return OK
func discard_at(index: int) -> Error:
	if phase != Phase.DISCARD:
		return ERR_INVALID_DATA
	var hand: Array = hands[turn_player]
	if index < 0 or index >= hand.size():
		return ERR_INVALID_PARAMETER
	var tile: Variant = hand[index]
	hand.remove_at(index)
	_record_discard(turn_player, tile, false)
	turn_player = 1 - turn_player
	phase = Phase.DRAW
	return OK
func declare_win() -> Error:
	if phase != Phase.DISCARD or not TrailHandValidator.is_winning_hand(combined_hand(turn_player)):
		return ERR_INVALID_DATA
	_complete_hand(turn_player, &"self_draw", _high_noon_state(turn_player).active)
	_log(&"win", {"player": turn_player, "source": "self_draw"})
	return OK


func claim_win_from_last_discard(player: int) -> Error:
	return MatchClaimController.claim_win_from_last_discard(self, player)


func claim_brand_group_from_last_discard(player: int, kind: StringName, hand_indices: Array[int]) -> Error:
	return MatchClaimController.claim_brand_group_from_last_discard(self, player, kind, hand_indices)


func declare_high_noon() -> Error:
	if phase != Phase.DRAW or not _high_noon_state(turn_player).declare(combined_hand(turn_player)):
		return ERR_INVALID_DATA
	high_noon_declared[turn_player] = true
	_log(&"high_noon_declared", {"player": turn_player, "waits": _high_noon_state(turn_player).waiting_identity_keys.duplicate()})
	return OK


func activate_orange(keep_draw_index: int) -> Error:
	return BrandPowerResolver.activate_orange(self, keep_draw_index)


func activate_blue(recent_discard_index: int) -> Error:
	return BrandPowerResolver.activate_blue(self, recent_discard_index)


func high_noon_state(player: int):
	return _high_noon_state(player)


func brand_state(player: int):
	return _brand_state(player)


func combined_hand(player: int) -> Array:
	var combined: Array = hands[player].duplicate()
	for group in open_groups[player]:
		combined.append_array(group)
	return combined


func snapshot() -> Dictionary:
	var replay_player: Variant = load("res://src/mahjong/domain/match_replay_player.gd")
	return replay_player.snapshot_from_flow(self)


static func rebuild_from_replay(replay_snapshot: Dictionary):
	var replay_player: Variant = load("res://src/mahjong/domain/match_replay_player.gd")
	return replay_player.rebuild_from_replay(replay_snapshot)


func _draw_for_current_player() -> void:
	var tile: Variant = _draw_from_wall()
	if tile == null:
		_exhaust_hand()
		return
	hands[turn_player].append(tile)
	_log(&"draw", {"player": turn_player, "tile": tile.key()})
	var high_noon: Variant = _high_noon_state(turn_player)
	if not high_noon.active:
		phase = Phase.DISCARD
		return
	var wins_at_high_noon: bool = high_noon.accepts(tile)
	var expired: bool = high_noon.consume_draw()
	if wins_at_high_noon:
		_complete_hand(turn_player, &"high_noon_draw", true)
		_log(&"win", {"player": turn_player, "source": "high_noon_draw"})
		return
	var automatic_tile: Variant = hands[turn_player].pop_back()
	_record_discard(turn_player, automatic_tile, true)
	turn_player = 1 - turn_player
	phase = Phase.DRAW
	if expired:
		_log(&"high_noon_expired", {"player": 1 - turn_player})


func _record_discard(player: int, tile, automatic: bool) -> void:
	discard_river.append({"player": player, "tile": tile, "claimed": false})
	_brand_state(player).record_discard(tile.brand)
	_log(&"discard", {"player": player, "tile": tile.key(), "automatic": automatic})


func _complete_hand(winner: int, source: StringName, won_at_high_noon: bool) -> void:
	phase = Phase.COMPLETE
	var award := {"base": 0, "deeds": [], "total": 0}
	if winner >= 0:
		award = RenownCalculator.calculate(combined_hand(winner), {
			"equipped_brands": _brand_state(winner).equipped,
			"opponent_brands": _brand_state(1 - winner).equipped,
			"won_at_high_noon": won_at_high_noon,
			"won_by_draw": source != &"discard_claim",
			"opponent_declared_high_noon": high_noon_declared[1 - winner],
		})
		renown[winner] += int(award["total"])
	hand_results.append({
		"hand": hand_number,
		"name": String(hand_name()),
		"winner": winner,
		"source": String(source),
		"award": award.duplicate(true),
	})
	_log(&"hand_completed", {"hand": hand_number, "winner": winner, "source": String(source), "renown": award["total"]})


func _exhaust_hand() -> void:
	if phase == Phase.EXHAUSTED or phase == Phase.COMPLETE:
		return
	phase = Phase.EXHAUSTED
	hand_results.append({"hand": hand_number, "name": String(hand_name()), "winner": -1, "source": "wall_exhausted", "award": {"base": 0, "deeds": [], "total": 0}})
	_log(&"wall_exhausted", {"hand": hand_number})


func _finish_match() -> void:
	phase = Phase.MATCH_COMPLETE
	if renown[0] > renown[1]:
		match_winner = 0
	elif renown[1] > renown[0]:
		match_winner = 1
	else:
		match_winner = -1
	_log(&"match_completed", {"winner": match_winner, "renown": renown.duplicate()})


func _draw_from_wall():
	if wall.is_empty():
		return null
	return wall.pop_back()


func _last_claimable_discard_index() -> int:
	if discard_river.is_empty():
		return -1
	var index := discard_river.size() - 1
	var discard: Dictionary = discard_river[index]
	if bool(discard.get("claimed", false)) or int(discard.get("player", -1)) == turn_player:
		return -1
	return index


func _discard_key(tile_key: String) -> bool:
	for index in hands[turn_player].size():
		var tile: Variant = hands[turn_player][index]
		if tile.key() == tile_key:
			return discard_at(index) == OK
	return false


func _brand_state(player: int):
	return brand_states[player]


func _high_noon_state(player: int):
	return high_noon_states[player]


func _as_brand_loadout(values: Array) -> Array[StringName]:
	var loadout: Array[StringName] = []
	for value in values:
		loadout.append(StringName(value))
	return loadout


func _tile_keys(tiles: Array) -> Array[String]:
	var keys: Array[String] = []
	for tile in tiles:
		if tile != null:
			keys.append(tile.key())
	return keys


func _log(action_type: StringName, payload: Dictionary) -> void:
	if not _suppress_replay:
		replay.append_action(action_type, payload)
