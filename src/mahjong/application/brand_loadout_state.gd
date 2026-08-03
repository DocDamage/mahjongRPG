extends RefCounted

const STARTER_BRANDS := [&"orange", &"blue"]
const MAX_UPGRADE_RANK := 1
const MASTERY_UNLOCKS := {
	&"river_rose": &"green",
	&"dynamite_bill": &"pink",
	&"mayor_bell": &"dark",
}

var unlocked: Dictionary = {}
var last_selected: Array[StringName] = []
var upgrades: Dictionary = {}
var upgrade_points := 0
var match_wins: Dictionary = {}
var hall_stage := 1
var unlocked_rulesets: Dictionary = {&"trail": true}
var discovered_deeds: Dictionary = {}


func _init() -> void:
	grant_starters()


func grant_starters() -> void:
	for brand in STARTER_BRANDS:
		unlocked[brand] = true
	if not is_valid_loadout(last_selected):
		last_selected.clear()
		for brand in STARTER_BRANDS:
			last_selected.append(brand)


func is_unlocked(brand: StringName) -> bool:
	return unlocked.has(brand)


func upgrade_rank(brand: StringName) -> int:
	return int(upgrades.get(brand, 0))


func can_upgrade(brand: StringName) -> bool:
	return is_unlocked(brand) and upgrade_points > 0 and upgrade_rank(brand) < MAX_UPGRADE_RANK


func upgrade(brand: StringName) -> Error:
	if not can_upgrade(brand):
		return ERR_UNAVAILABLE
	upgrades[brand] = upgrade_rank(brand) + 1
	upgrade_points -= 1
	return OK


func record_match_win(opponent_id: StringName, ruleset: StringName) -> Dictionary:
	match_wins[opponent_id] = int(match_wins.get(opponent_id, 0)) + 1
	var result := {"unlocked": StringName(), "unlocked_brands": [], "hall_reopened": false, "upgrade_point": false}
	var earned: StringName = MASTERY_UNLOCKS.get(opponent_id, &"")
	if not earned.is_empty() and not is_unlocked(earned):
		unlocked[earned] = true
		upgrade_points += 1
		result["unlocked"] = earned
		result["unlocked_brands"].append(earned)
		result["upgrade_point"] = true
	if ruleset == &"frontier" and not is_unlocked(&"purple"):
		unlocked[&"purple"] = true
		upgrade_points += 1
		result["unlocked"] = &"purple"
		result["unlocked_brands"].append(&"purple")
		result["upgrade_point"] = true
	_refresh_hall_stage(result)
	return result


func complete_hall_cleanup() -> Dictionary:
	var result := {"unlocked": StringName(), "unlocked_brands": [], "hall_reopened": false, "upgrade_point": false}
	_refresh_hall_stage(result)
	return result


func unlock_hall_stage(stage: int) -> Error:
	if stage < 1 or stage > 5 or stage <= hall_stage:
		return ERR_UNAVAILABLE
	hall_stage = stage
	return OK


func can_play_frontier() -> bool:
	return unlocked_rulesets.has(&"frontier")


func record_deeds(deeds: Array) -> void:
	for deed_value in deeds:
		if deed_value is Dictionary:
			var deed_id := StringName(deed_value.get("id", ""))
			if not deed_id.is_empty():
				discovered_deeds[deed_id] = true


func unlocked_brands() -> Array[StringName]:
	var brands: Array[StringName] = []
	for brand_value in unlocked:
		brands.append(StringName(brand_value))
	brands.sort()
	return brands


func select(loadout: Array[StringName]) -> Error:
	if not is_valid_loadout(loadout):
		return ERR_INVALID_PARAMETER
	last_selected = loadout.duplicate()
	return OK


func is_valid_loadout(loadout: Array[StringName]) -> bool:
	if loadout.size() != 2 or loadout[0] == loadout[1]:
		return false
	for brand in loadout:
		if not is_unlocked(brand):
			return false
	return true


func snapshot() -> Dictionary:
	return {
		"unlocked": unlocked.duplicate(true),
		"last_selected": last_selected.duplicate(),
		"upgrades": upgrades.duplicate(true),
		"upgrade_points": upgrade_points,
		"match_wins": match_wins.duplicate(true),
		"hall_stage": hall_stage,
		"unlocked_rulesets": unlocked_rulesets.duplicate(true),
		"discovered_deeds": discovered_deeds.duplicate(true),
	}


func restore(data: Dictionary) -> Error:
	var unlocked_value: Variant = data.get("unlocked", {})
	var selected_value: Variant = data.get("last_selected", [])
	var upgrades_value: Variant = data.get("upgrades", {})
	var wins_value: Variant = data.get("match_wins", {})
	var rulesets_value: Variant = data.get("unlocked_rulesets", {})
	var deeds_value: Variant = data.get("discovered_deeds", {})
	if not unlocked_value is Dictionary or not selected_value is Array or not upgrades_value is Dictionary or not wins_value is Dictionary or not rulesets_value is Dictionary or not deeds_value is Dictionary:
		return ERR_INVALID_DATA
	unlocked = unlocked_value.duplicate(true)
	upgrades = upgrades_value.duplicate(true)
	match_wins = wins_value.duplicate(true)
	upgrade_points = maxi(0, int(data.get("upgrade_points", 0)))
	hall_stage = clampi(int(data.get("hall_stage", 1)), 1, 5)
	unlocked_rulesets = rulesets_value.duplicate(true)
	discovered_deeds = deeds_value.duplicate(true)
	unlocked_rulesets[&"trail"] = true
	last_selected.clear()
	for brand_value in selected_value:
		last_selected.append(StringName(brand_value))
	grant_starters()
	return OK


func _refresh_hall_stage(result: Dictionary) -> void:
	if hall_stage >= 2:
		return
	for opponent_id in MASTERY_UNLOCKS:
		if int(match_wins.get(opponent_id, 0)) < 1:
			return
	hall_stage = 2
	unlocked_rulesets[&"frontier"] = true
	result["hall_reopened"] = true
	if not is_unlocked(&"purple"):
		unlocked[&"purple"] = true
		upgrade_points += 1
		result["unlocked"] = &"purple"
		result["unlocked_brands"].append(&"purple")
		result["upgrade_point"] = true
