extends RefCounted

const PersonalityProfile = preload("res://src/mahjong/ai/personality_profile.gd")

func choose_discard_index(hand: Array, visible_knowledge, personality_data: Dictionary = {}) -> Dictionary:
	if hand.is_empty():
		return {"error": ERR_INVALID_PARAMETER}
	var personality := PersonalityProfile.new(personality_data)
	var best_index := 0
	var best_score := INF
	for index in hand.size():
		var score := _keep_score(index, hand, visible_knowledge, personality)
		if score < best_score or (is_equal_approx(score, best_score) and hand[index].key() > hand[best_index].key()):
			best_index = index
			best_score = score
	return {
		"index": best_index,
		"reason": "Discard keeps existing sets, runs, and unseen waits while using only visible information.",
	}


func _keep_score(index: int, hand: Array, visible_knowledge, personality) -> float:
	var tile: Variant = hand[index]
	var score := 0.0
	for other_index in hand.size():
		if other_index == index:
			continue
		var other: Variant = hand[other_index]
		if tile.identity.equals(other.identity):
			score += 3.0 * personality.set_weight
		elif tile.identity.is_numbered() and other.identity.is_numbered() and tile.identity.suit == other.identity.suit:
			var distance: int = abs(int(tile.identity.rank) - int(other.identity.rank))
			if distance == 1:
				score += 2.0 * personality.run_weight
			elif distance == 2:
				score += personality.run_weight
	score -= visible_knowledge.seen_identity_count(tile.identity_key()) * personality.seen_tile_weight
	return score
