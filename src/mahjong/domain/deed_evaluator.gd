extends RefCounted

const TrailHandValidator = preload("res://src/mahjong/domain/trail_hand_validator.gd")

const DEED_RENOWN := {
	"three_trails": 2,
	"posse": 2,
	"claimed_territory": 2,
	"home_turf": 2,
	"cattle_rustler": 2,
	"full_frontier": 3,
	"quickdraw": 3,
	"self_made": 1,
	"long_trail": 2,
	"against_the_odds": 2,
}


static func evaluate(tiles: Array, context: Dictionary = {}) -> Array[Dictionary]:
	var decompositions := TrailHandValidator.decompose_hand(tiles)
	if decompositions.is_empty():
		return []
	var decomposition: Dictionary = decompositions.front()
	var groups_value: Variant = decomposition.get("groups", [])
	if not groups_value is Array:
		return []
	var groups: Array = groups_value
	var deeds: Array[Dictionary] = []
	var run_count := 0
	var set_count := 0
	for group_value in groups:
		if group_value is Dictionary:
			if String(group_value.get("kind", "")) == "run":
				run_count += 1
			elif String(group_value.get("kind", "")) == "set":
				set_count += 1
	if run_count == 3:
		_add(deeds, "three_trails", "Three Trails: every group is a Run.")
	if set_count == 3:
		_add(deeds, "posse", "The Posse: every group is a matching Set.")
	var numbered_suits := _numbered_suits(tiles)
	if numbered_suits.size() == 1 and _all_numbered(tiles):
		_add(deeds, "claimed_territory", "Claimed Territory: the hand stays in one numbered suit.")
	var brands := _brand_counts(tiles)
	var equipped_value: Variant = context.get("equipped_brands", [])
	if equipped_value is Array and _count_brands(brands, equipped_value) >= 8:
		_add(deeds, "home_turf", "Home Turf: eight or more tiles carry your equipped Brands.")
	var opponent_value: Variant = context.get("opponent_brands", [])
	if opponent_value is Array and _count_brands(brands, opponent_value) >= 6:
		_add(deeds, "cattle_rustler", "Cattle Rustler: six or more tiles carry the opponent's Brands.")
	if brands.keys().size() == 6:
		_add(deeds, "full_frontier", "Full Frontier: all six Brands appear in the winning hand.")
	if bool(context.get("won_at_high_noon", false)):
		_add(deeds, "quickdraw", "Quickdraw: win during a declared High Noon.")
	if bool(context.get("won_by_draw", false)):
		_add(deeds, "self_made", "Self-Made: win from your own draw.")
	if _has_long_trail(groups):
		_add(deeds, "long_trail", "Long Trail: your Runs span ranks one through nine.")
	if bool(context.get("opponent_declared_high_noon", false)):
		_add(deeds, "against_the_odds", "Against the Odds: win after the opponent declares High Noon.")
	return deeds


static func _add(deeds: Array[Dictionary], deed_id: String, explanation: String) -> void:
	deeds.append({"id": deed_id, "renown": int(DEED_RENOWN[deed_id]), "explanation": explanation})


static func _numbered_suits(tiles: Array) -> Array[StringName]:
	var suits: Array[StringName] = []
	for tile in tiles:
		if tile != null and tile.identity.is_numbered() and not suits.has(tile.identity.suit):
			suits.append(tile.identity.suit)
	return suits


static func _all_numbered(tiles: Array) -> bool:
	return tiles.all(func(tile) -> bool: return tile != null and tile.identity.is_numbered())


static func _brand_counts(tiles: Array) -> Dictionary:
	var counts: Dictionary = {}
	for tile in tiles:
		if tile != null:
			counts[tile.brand] = int(counts.get(tile.brand, 0)) + 1
	return counts


static func _count_brands(counts: Dictionary, brands: Array) -> int:
	var count := 0
	for brand_value in brands:
		count += int(counts.get(brand_value, 0))
	return count


static func _has_long_trail(groups: Array) -> bool:
	var ranks: Array[int] = []
	for group_value in groups:
		if not group_value is Dictionary or String(group_value.get("kind", "")) != "run":
			continue
		var keys_value: Variant = group_value.get("keys", [])
		if keys_value is Array:
			for key_value in keys_value:
				var parts := String(key_value).split(":")
				if parts.size() == 2:
					ranks.append(int(parts[1]))
	ranks.sort()
	return ranks == [1, 2, 3, 4, 5, 6, 7, 8, 9]
