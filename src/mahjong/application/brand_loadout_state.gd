extends RefCounted

const STARTER_BRANDS := [&"orange", &"blue"]

var unlocked: Dictionary = {}
var last_selected: Array[StringName] = []


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
	}


func restore(data: Dictionary) -> Error:
	var unlocked_value: Variant = data.get("unlocked", {})
	var selected_value: Variant = data.get("last_selected", [])
	if not unlocked_value is Dictionary or not selected_value is Array:
		return ERR_INVALID_DATA
	unlocked = unlocked_value.duplicate(true)
	last_selected.clear()
	for brand_value in selected_value:
		last_selected.append(StringName(brand_value))
	grant_starters()
	return OK
