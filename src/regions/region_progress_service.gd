extends RefCounted

signal region_unlocked(region_id: StringName)
signal crop_order_fulfilled(order_id: StringName)
signal regional_table_won(opponent_id: StringName)
signal structure_repaired(structure_id: StringName)
signal shortcut_unlocked(shortcut_id: StringName)

var definitions: Dictionary = {}
var unlocked_regions: Dictionary = {}
var fulfilled_orders: Dictionary = {}
var table_wins: Dictionary = {}
var repaired_structures: Dictionary = {}
var shortcuts: Dictionary = {}


func register_definition(data: Dictionary) -> Error:
	var region_id := StringName(data.get("id", ""))
	if region_id.is_empty() or definitions.has(region_id):
		return ERR_INVALID_DATA
	definitions[region_id] = data.duplicate(true)
	return OK


func unlock(region_id: StringName) -> Error:
	if not definitions.has(region_id):
		return ERR_DOES_NOT_EXIST
	if unlocked_regions.has(region_id):
		return ERR_ALREADY_IN_USE
	unlocked_regions[region_id] = true
	region_unlocked.emit(region_id)
	return OK


func is_unlocked(region_id: StringName) -> bool:
	return unlocked_regions.has(region_id)


func fulfill_crop_order(order_id: StringName, inventory) -> Error:
	var order := _order(order_id)
	if order.is_empty() or inventory == null or fulfilled_orders.has(order_id):
		return ERR_UNAVAILABLE
	for requirement_value in order.get("requirements", []):
		if not requirement_value is Dictionary:
			return ERR_INVALID_DATA
		if inventory.item_count(StringName(requirement_value.get("item_id", ""))) < int(requirement_value.get("count", 0)):
			return ERR_UNAVAILABLE
	for requirement_value in order["requirements"]:
		inventory.remove_item(StringName(requirement_value["item_id"]), int(requirement_value["count"]))
	inventory.add_money(int(order.get("reward_cents", 0)))
	fulfilled_orders[order_id] = true
	crop_order_fulfilled.emit(order_id)
	return OK


func record_table_win(opponent_id: StringName) -> void:
	table_wins[opponent_id] = int(table_wins.get(opponent_id, 0)) + 1
	regional_table_won.emit(opponent_id)


func has_table_win(opponent_id: StringName) -> bool:
	return int(table_wins.get(opponent_id, 0)) > 0


func repair(structure_id: StringName, farm, inventory) -> Error:
	if structure_id.is_empty() or repaired_structures.has(structure_id) or farm == null or inventory == null:
		return ERR_UNAVAILABLE
	var result: Error = farm.repair_construction(structure_id, inventory)
	if result != OK:
		return result
	repaired_structures[structure_id] = true
	structure_repaired.emit(structure_id)
	return OK


func unlock_shortcut(shortcut_id: StringName, prerequisite_structure: StringName = &"") -> Error:
	if shortcut_id.is_empty() or shortcuts.has(shortcut_id):
		return ERR_UNAVAILABLE
	if not prerequisite_structure.is_empty() and not repaired_structures.has(prerequisite_structure):
		return ERR_UNAVAILABLE
	shortcuts[shortcut_id] = true
	shortcut_unlocked.emit(shortcut_id)
	return OK


func has_shortcut(shortcut_id: StringName) -> bool:
	return shortcuts.has(shortcut_id)


func snapshot() -> Dictionary:
	return {
		"unlocked_regions": unlocked_regions.duplicate(true),
		"fulfilled_orders": fulfilled_orders.duplicate(true),
		"table_wins": table_wins.duplicate(true),
		"repaired_structures": repaired_structures.duplicate(true),
		"shortcuts": shortcuts.duplicate(true),
	}


func restore(data: Dictionary) -> Error:
	for key in ["unlocked_regions", "fulfilled_orders", "table_wins", "repaired_structures", "shortcuts"]:
		if not data.get(key, {}) is Dictionary:
			return ERR_INVALID_DATA
	unlocked_regions = data["unlocked_regions"].duplicate(true)
	fulfilled_orders = data["fulfilled_orders"].duplicate(true)
	table_wins = data["table_wins"].duplicate(true)
	repaired_structures = data["repaired_structures"].duplicate(true)
	shortcuts = data["shortcuts"].duplicate(true)
	for region_value in unlocked_regions:
		if not definitions.has(StringName(region_value)):
			return ERR_DOES_NOT_EXIST
	return OK


func _order(order_id: StringName) -> Dictionary:
	for region_value in definitions.values():
		var orders_value: Variant = region_value.get("crop_orders", [])
		if not orders_value is Array:
			continue
		for order_value in orders_value:
			if order_value is Dictionary and StringName(order_value.get("id", "")) == order_id:
				return order_value.duplicate(true)
	return {}
