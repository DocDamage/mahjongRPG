extends RefCounted

const MatchFlow = preload("res://src/mahjong/domain/match_flow.gd")

var _turn_replay: Dictionary = {}
var _available := false


func begin_turn(flow) -> void:
	_turn_replay = flow.replay.snapshot()
	_available = false


func record_player_action() -> void:
	_available = not _turn_replay.is_empty()


func can_undo() -> bool:
	return _available


func restore() -> Variant:
	if not _available:
		return null
	_available = false
	return MatchFlow.rebuild_from_replay(_turn_replay)
