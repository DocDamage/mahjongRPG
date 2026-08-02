extends RefCounted

const BasicTrailAi = preload("res://src/mahjong/ai/basic_trail_ai.gd")
const VisibleKnowledge = preload("res://src/mahjong/ai/visible_knowledge.gd")


static func recommend_discard(hand: Array, discard_river: Array, open_groups: Array) -> Dictionary:
	var knowledge := VisibleKnowledge.new()
	for entry_value in discard_river:
		if entry_value is Dictionary:
			var entry: Dictionary = entry_value
			knowledge.observe_discard(int(entry.get("player", -1)), entry.get("tile"))
	for player_index in open_groups.size():
		for group in open_groups[player_index]:
			knowledge.observe_open_group(player_index, group)
	var decision: Dictionary = BasicTrailAi.new().choose_discard_index(hand, knowledge)
	var index := int(decision.get("index", -1))
	if index < 0 or index >= hand.size():
		return {"error": decision.get("error", ERR_INVALID_PARAMETER)}
	return {"index": index, "tile": hand[index], "reason": decision.get("reason", "")}
