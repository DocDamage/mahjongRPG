extends RefCounted

const FrontierHandValidator = preload("res://src/mahjong/domain/frontier_hand_validator.gd")
const MatchRuleset = preload("res://src/mahjong/domain/match_ruleset.gd")
const TrailHandValidator = preload("res://src/mahjong/domain/trail_hand_validator.gd")


static func is_winning_hand(tiles: Array, ruleset: StringName) -> bool:
	return FrontierHandValidator.is_winning_hand(tiles) if ruleset == MatchRuleset.FRONTIER else TrailHandValidator.is_winning_hand(tiles)


static func decompose_hand(tiles: Array, ruleset: StringName) -> Array[Dictionary]:
	return FrontierHandValidator.decompose_hand(tiles) if ruleset == MatchRuleset.FRONTIER else TrailHandValidator.decompose_hand(tiles)


static func winning_identity_keys(tiles: Array, ruleset: StringName) -> Array[String]:
	return FrontierHandValidator.winning_identity_keys(tiles) if ruleset == MatchRuleset.FRONTIER else TrailHandValidator.winning_identity_keys(tiles)
