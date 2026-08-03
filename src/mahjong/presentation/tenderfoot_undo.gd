extends RefCounted

const MatchFlow = preload("res://src/mahjong/domain/match_flow.gd")

var _turn_replay: Dictionary = {}
var _available := false
var _used := false
var _turn_key := ""


func begin_turn(flow) -> void:
	var next_key := "%d:%d:%d" % [flow.hand_number, flow.discard_river.size(), flow.turn_player]
	if next_key == _turn_key:
		return
	_turn_key = next_key
	_turn_replay = flow.replay.snapshot()
	_available = false
	_used = false


func record_player_action() -> void:
	_available = not _used and not _turn_replay.is_empty()


func can_undo() -> bool:
	return _available


func restore() -> Variant:
	if not _available:
		return null
	_available = false
	_used = true
	return MatchFlow.rebuild_from_replay(_turn_replay)
