extends RefCounted

const BasicTrailAi = preload("res://src/mahjong/ai/basic_trail_ai.gd")


func choose_discard_index(hand: Array, visible_knowledge, personality_data: Dictionary = {}) -> Dictionary:
	var decision := BasicTrailAi.new().choose_discard_index(hand, visible_knowledge, personality_data)
	if decision.has("error"):
		return decision
	decision["reason"] = _explanation(hand, int(decision["index"]), visible_knowledge)
	decision["knowledge"] = visible_knowledge.snapshot()
	return decision


func _explanation(hand: Array, index: int, visible_knowledge) -> String:
	if index < 0 or index >= hand.size():
		return "No legal discard is available."
	var tile = hand[index]
	var seen: int = visible_knowledge.seen_identity_count(tile.identity_key())
	return "Frontier read: %s is least connected in the concealed hand; %d matching tile(s) are publicly visible." % [tile.key(), seen]
