extends RefCounted

const BrandChargeState = preload("res://src/mahjong/domain/brand_charge_state.gd")
const BrandPowerResolver = preload("res://src/mahjong/domain/brand_power_resolver.gd")
const HandRules = preload("res://src/mahjong/domain/hand_rules.gd")
const HighNoonState = preload("res://src/mahjong/domain/high_noon_state.gd")
const MatchClaimController = preload("res://src/mahjong/domain/match_claim_controller.gd")
const MatchReplayLog = preload("res://src/mahjong/domain/match_replay_log.gd")
const MatchRoundController = preload("res://src/mahjong/domain/match_round_controller.gd")
const MatchRuleset = preload("res://src/mahjong/domain/match_ruleset.gd")

enum Phase { DRAW, DISCARD, COMPLETE, EXHAUSTED, MATCH_COMPLETE }

const HAND_NAMES := [&"morning", &"high_noon", &"sundown", &"midnight", &"showdown"]
const STANDARD_HAND_COUNT := 4
const SHOWDOWN_HAND := 4
const DEFAULT_LOADOUTS := [[&"orange", &"blue"], [&"dark", &"green"]]

var seed: int
var ruleset: StringName = MatchRuleset.TRAIL
var hand_number := -1
var dealer := 0
var turn_player := 0
var phase := Phase.MATCH_COMPLETE
var wall: Array = []
var hands: Array = [[], []]
var open_groups: Array = [[], []]
var corrals: Array = [[], []]
var neutral_tiles: Array = []
var discard_river: Array[Dictionary] = []
var renown: Array[int] = [0, 0]
var hand_results: Array[Dictionary] = []
var match_winner := -1
var replay: MatchReplayLog
var brand_states: Array = []
var brand_upgrades: Array = [{}, {}]
var high_noon_states: Array = []
var high_noon_declared: Array[bool] = [false, false]
var _suppress_replay := false


func _init(match_seed: int) -> void:
	seed = match_seed
	replay = MatchReplayLog.new(seed)
	brand_states = [BrandChargeState.new(), BrandChargeState.new()]
	high_noon_states = [HighNoonState.new(), HighNoonState.new()]
	configure_loadouts(DEFAULT_LOADOUTS[0], DEFAULT_LOADOUTS[1])


func configure_ruleset(next_ruleset: StringName) -> Error:
	if phase != Phase.MATCH_COMPLETE or not MatchRuleset.is_valid(next_ruleset):
		return ERR_INVALID_PARAMETER
	ruleset = next_ruleset
	_log(&"ruleset_configured", {"ruleset": String(ruleset)})
	return OK


func configure_loadouts(first: Array, second: Array) -> Error:
	if brand_state(0).configure(_as_brand_loadout(first)) != OK or brand_state(1).configure(_as_brand_loadout(second)) != OK:
		return ERR_INVALID_PARAMETER
	_log(&"loadouts_configured", {"player_0": brand_state(0).equipped.duplicate(), "player_1": brand_state(1).equipped.duplicate()})
	return OK


func configure_upgrades(first: Dictionary, second: Dictionary) -> void:
	brand_upgrades = [first.duplicate(true), second.duplicate(true)]
	_log(&"upgrades_configured", {"player_0": first.duplicate(true), "player_1": second.duplicate(true)})


func upgrade_rank(player: int, brand: StringName) -> int:
	return int(brand_upgrades[player].get(brand, 0)) if player >= 0 and player < 2 else 0


func start_match() -> Error:
	renown = [0, 0]; hand_results.clear(); match_winner = -1
	return start_hand(0)


func start_hand(next_hand_number: int) -> Error:
	return MatchRoundController.start_hand(self, next_hand_number)


func hand_name() -> StringName:
	return HAND_NAMES[hand_number] if hand_number >= 0 and hand_number < HAND_NAMES.size() else &""


func current_hand() -> Array:
	return hands[turn_player].duplicate()


func can_start_next_hand() -> bool:
	return phase == Phase.COMPLETE or phase == Phase.EXHAUSTED


func advance_match() -> Error:
	if not can_start_next_hand(): return ERR_INVALID_DATA
	if hand_number < STANDARD_HAND_COUNT - 1: return start_hand(hand_number + 1)
	if hand_number == STANDARD_HAND_COUNT - 1 and renown[0] == renown[1]: return start_hand(SHOWDOWN_HAND)
	_finish_match()
	return OK


func draw() -> Error:
	if phase != Phase.DRAW: return ERR_INVALID_DATA
	if wall.is_empty(): _exhaust_hand(); return ERR_UNAVAILABLE
	_draw_for_current_player()
	return OK


func discard_at(index: int) -> Error:
	if phase != Phase.DISCARD: return ERR_INVALID_DATA
	if index < 0 or index >= hands[turn_player].size(): return ERR_INVALID_PARAMETER
	var tile = hands[turn_player][index]
	hands[turn_player].remove_at(index)
	_record_discard(turn_player, tile, false)
	turn_player = 1 - turn_player; phase = Phase.DRAW
	return OK


func declare_win() -> Error:
	if phase != Phase.DISCARD or not is_winning_hand(combined_hand(turn_player)): return ERR_INVALID_DATA
	_complete_hand(turn_player, &"self_draw", high_noon_state(turn_player).active)
	_log(&"win", {"player": turn_player, "source": "self_draw"})
	return OK


func claim_win_from_last_discard(player: int) -> Error:
	return MatchClaimController.claim_win_from_last_discard(self, player)


func claim_brand_group_from_last_discard(player: int, kind: StringName, hand_indices: Array[int]) -> Error:
	return MatchClaimController.claim_brand_group_from_last_discard(self, player, kind, hand_indices)


func declare_high_noon() -> Error:
	if phase != Phase.DRAW or not high_noon_state(turn_player).declare(combined_hand(turn_player), ruleset): return ERR_INVALID_DATA
	high_noon_declared[turn_player] = true
	_log(&"high_noon_declared", {"player": turn_player, "waits": high_noon_state(turn_player).waiting_identity_keys.duplicate()})
	return OK


func activate_orange(keep_draw_index: int) -> Error: return BrandPowerResolver.activate_orange(self, keep_draw_index)
func activate_blue(recent_discard_index: int) -> Error: return BrandPowerResolver.activate_blue(self, recent_discard_index)
func activate_green(hand_index: int) -> Error: return BrandPowerResolver.activate_green(self, hand_index)
func release_green() -> Error: return BrandPowerResolver.release_green(self)
func activate_pink(hand_index: int) -> Error: return BrandPowerResolver.activate_pink(self, hand_index)
func activate_dark() -> Error: return BrandPowerResolver.activate_dark(self)
func activate_purple(order: Array[int]) -> Error: return BrandPowerResolver.activate_purple(self, order)
func high_noon_state(player: int): return high_noon_states[player]
func brand_state(player: int): return brand_states[player]
func is_winning_hand(tiles: Array) -> bool: return HandRules.is_winning_hand(tiles, ruleset)
func combined_hand(player: int) -> Array:
	var combined: Array = hands[player].duplicate()
	for group in open_groups[player]: combined.append_array(group)
	return combined


func snapshot() -> Dictionary:
	var replay_player = load("res://src/mahjong/domain/match_replay_player.gd")
	return replay_player.snapshot_from_flow(self)


static func rebuild_from_replay(replay_snapshot: Dictionary):
	var replay_player = load("res://src/mahjong/domain/match_replay_player.gd")
	return replay_player.rebuild_from_replay(replay_snapshot)


func _draw_for_current_player() -> void: MatchRoundController.draw_for_current_player(self)
func _complete_hand(winner: int, source: StringName, high_noon: bool) -> void: MatchRoundController.complete_hand(self, winner, source, high_noon)
func _exhaust_hand() -> void: MatchRoundController.exhaust_hand(self)
func _finish_match() -> void: MatchRoundController.finish_match(self)
func _draw_from_wall(): return null if wall.is_empty() else wall.pop_back()
func _record_discard(player: int, tile, automatic: bool) -> void:
	discard_river.append({"player": player, "tile": tile, "claimed": false, "unclaimable": false})
	brand_state(player).record_discard(tile.brand)
	_log(&"discard", {"player": player, "tile": tile.key(), "automatic": automatic})
func _last_claimable_discard_index() -> int:
	if discard_river.is_empty(): return -1
	var index := discard_river.size() - 1
	var discard: Dictionary = discard_river[index]
	return -1 if bool(discard.get("claimed", false)) or bool(discard.get("unclaimable", false)) or int(discard.get("player", -1)) == turn_player else index
func _discard_key(tile_key: String) -> bool:
	for index in hands[turn_player].size():
		if hands[turn_player][index].key() == tile_key: return discard_at(index) == OK
	return false
func _as_brand_loadout(values: Array) -> Array[StringName]:
	var loadout: Array[StringName] = []
	for value in values: loadout.append(StringName(value))
	return loadout
func _log(action_type: StringName, payload: Dictionary) -> void:
	if not _suppress_replay: replay.append_action(action_type, payload)
