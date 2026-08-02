extends RefCounted

const MatchReplayLog = preload("res://src/mahjong/domain/match_replay_log.gd")
const TrailHandValidator = preload("res://src/mahjong/domain/trail_hand_validator.gd")
const WallBuilder = preload("res://src/mahjong/domain/wall_builder.gd")

enum Phase { DRAW, DISCARD, COMPLETE, EXHAUSTED }

var seed: int
var hand_number := 0
var dealer := 0
var turn_player := 0
var phase := Phase.DRAW
var wall: Array = []
var hands: Array = [[], []]
var discard_river: Array = []
var replay: MatchReplayLog


func _init(match_seed: int) -> void:
	seed = match_seed
	replay = MatchReplayLog.new(seed)


func start_hand(next_hand_number: int) -> void:
	if next_hand_number < 0 or next_hand_number >= 4:
		push_error("Trail Rules match supports exactly four standard hands")
		return
	hand_number = next_hand_number
	dealer = hand_number % 2
	turn_player = dealer
	phase = Phase.DRAW
	wall = WallBuilder.build_trail_wall(seed + hand_number)
	hands = [[], []]
	discard_river.clear()
	for player_index in 2:
		for ignored in 10:
			hands[player_index].append(_draw_from_wall())
	_draw_for_current_player()
	replay.append_action(&"hand_started", {"hand": hand_number, "dealer": dealer})


func current_hand() -> Array:
	return hands[turn_player].duplicate()


func draw() -> Error:
	if phase != Phase.DRAW:
		return ERR_INVALID_DATA
	if wall.is_empty():
		phase = Phase.EXHAUSTED
		replay.append_action(&"wall_exhausted", {})
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
	discard_river.append({"player": turn_player, "tile": tile})
	replay.append_action(&"discard", {"player": turn_player, "tile": tile.key()})
	turn_player = 1 - turn_player
	phase = Phase.DRAW
	return OK


func declare_win() -> Error:
	if phase != Phase.DISCARD or not TrailHandValidator.is_winning_hand(hands[turn_player]):
		return ERR_INVALID_DATA
	phase = Phase.COMPLETE
	replay.append_action(&"win", {"player": turn_player})
	return OK


func _draw_for_current_player() -> void:
	var tile: Variant = _draw_from_wall()
	if tile == null:
		phase = Phase.EXHAUSTED
		replay.append_action(&"wall_exhausted", {})
		return
	hands[turn_player].append(tile)
	phase = Phase.DISCARD
	replay.append_action(&"draw", {"player": turn_player, "tile": tile.key()})


func _draw_from_wall():
	if wall.is_empty():
		return null
	return wall.pop_back()
