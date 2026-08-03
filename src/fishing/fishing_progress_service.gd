extends RefCounted

const FishCatalog = preload("res://src/fishing/fish_catalog.gd")
const FishingGearCatalog = preload("res://src/fishing/fishing_gear_catalog.gd")

var owned_gear: Dictionary = {}
var loadout: Dictionary = {}
var discovered_conditions: Dictionary = {}
var records: Dictionary = {}
var contests: Dictionary = {}


func _init() -> void:
	loadout = FishingGearCatalog.default_loadout()
	for gear_id in FishingGearCatalog.starter_ids():
		owned_gear[gear_id] = true


func gear_profile() -> Dictionary:
	return FishingGearCatalog.profile(loadout)


func buy_gear(gear_id: StringName, inventory) -> Error:
	var entry := FishingGearCatalog.entry(gear_id)
	if entry.is_empty() or owned_gear.has(gear_id) or inventory == null:
		return ERR_UNAVAILABLE
	if inventory.spend_money(int(entry.get("price_cents", -1))) != OK:
		return ERR_UNAVAILABLE
	owned_gear[gear_id] = true
	return OK


func equip(category: StringName, gear_id: StringName) -> Error:
	if FishingGearCatalog.category_for(gear_id) != category or not owned_gear.has(gear_id):
		return ERR_UNAVAILABLE
	loadout[category] = gear_id
	return OK if not gear_profile().is_empty() else ERR_INVALID_DATA


func discover_condition(condition_id: StringName) -> Error:
	if condition_id.is_empty() or discovered_conditions.has(condition_id):
		return ERR_ALREADY_IN_USE
	discovered_conditions[condition_id] = true
	return OK


func has_condition(condition_id: StringName) -> bool:
	return discovered_conditions.has(condition_id)


func record_catch(fish_id: StringName, value_cents: int, inventory) -> Error:
	if FishCatalog.definition(fish_id).is_empty() or inventory == null or inventory.record_fish(fish_id, value_cents) != OK:
		return ERR_INVALID_DATA
	var record: Dictionary = records.get(fish_id, {"catches": 0, "best_value_cents": 0})
	record["catches"] = int(record["catches"]) + 1
	record["best_value_cents"] = maxi(int(record["best_value_cents"]), value_cents)
	records[fish_id] = record
	return OK


func enter_contest(contest_id: StringName, fish_id: StringName, inventory) -> Dictionary:
	var fish := FishCatalog.definition(fish_id)
	if contest_id != &"gulls_rest_weekly" or fish.is_empty() or inventory == null:
		return {"error": ERR_INVALID_PARAMETER}
	if inventory.remove_item(StringName("fish_%s" % fish_id)) != OK:
		return {"error": ERR_UNAVAILABLE}
	var score := int(fish.get("sell_value_cents", 0)) + int(fish.get("rarity_score", 0)) * 100
	var result: Dictionary = contests.get(contest_id, {"entries": 0, "best_score": 0, "wins": 0})
	result["entries"] = int(result["entries"]) + 1
	if score > int(result["best_score"]):
		result["best_score"] = score
	if score >= 500:
		result["wins"] = int(result["wins"]) + 1
		inventory.add_money(300)
	contests[contest_id] = result
	return {"score": score, "won": score >= 500, "entries": result["entries"]}


func snapshot() -> Dictionary:
	return {"owned_gear": owned_gear.duplicate(true), "loadout": loadout.duplicate(true), "discovered_conditions": discovered_conditions.duplicate(true), "records": records.duplicate(true), "contests": contests.duplicate(true)}


func restore(data: Dictionary) -> Error:
	for key in ["owned_gear", "loadout", "discovered_conditions", "records", "contests"]:
		if not data.get(key, {}) is Dictionary:
			return ERR_INVALID_DATA
	for gear_value in data["owned_gear"]:
		if FishingGearCatalog.entry(StringName(gear_value)).is_empty():
			return ERR_DOES_NOT_EXIST
	owned_gear = data["owned_gear"].duplicate(true)
	loadout = data["loadout"].duplicate(true)
	for category_value in FishingGearCatalog.default_loadout():
		var category := StringName(category_value)
		var gear_id := StringName(loadout.get(category, ""))
		if FishingGearCatalog.category_for(gear_id) != category or not owned_gear.has(gear_id):
			return ERR_INVALID_DATA
	if gear_profile().is_empty():
		return ERR_INVALID_DATA
	for fish_value in data["records"]:
		var record: Variant = data["records"][fish_value]
		if FishCatalog.definition(StringName(fish_value)).is_empty() or not record is Dictionary or int(record.get("catches", -1)) < 0 or int(record.get("best_value_cents", -1)) < 0:
			return ERR_INVALID_DATA
	for condition_value in data["discovered_conditions"]:
		if not FishCatalog.rare_conditions().has(StringName(condition_value)):
			return ERR_INVALID_DATA
	for contest_value in data["contests"].values():
		if not contest_value is Dictionary or int(contest_value.get("entries", -1)) < 0 or int(contest_value.get("best_score", -1)) < 0 or int(contest_value.get("wins", -1)) < 0:
			return ERR_INVALID_DATA
	discovered_conditions = data["discovered_conditions"].duplicate(true)
	records = data["records"].duplicate(true)
	contests = data["contests"].duplicate(true)
	return OK
