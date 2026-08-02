extends RefCounted

const TrailHandValidator = preload("res://src/mahjong/domain/trail_hand_validator.gd")
const HandRules = preload("res://src/mahjong/domain/hand_rules.gd")
const MatchRuleset = preload("res://src/mahjong/domain/match_ruleset.gd")

const DRAW_LIMIT := 3

var active := false
var draws_remaining := 0
var waiting_identity_keys: Array[String] = []


func declare(hand: Array, ruleset: StringName = MatchRuleset.TRAIL) -> bool:
	if active:
		return false
	var waits := HandRules.winning_identity_keys(hand, ruleset)
	if waits.is_empty():
		return false
	active = true
	draws_remaining = DRAW_LIMIT
	waiting_identity_keys = waits
	return true


func consume_draw() -> bool:
	if not active:
		return false
	draws_remaining -= 1
	if draws_remaining <= 0:
		clear()
		return true
	return false


func accepts(tile) -> bool:
	return active and tile != null and tile.identity_key() in waiting_identity_keys


func clear() -> void:
	active = false
	draws_remaining = 0
	waiting_identity_keys.clear()
