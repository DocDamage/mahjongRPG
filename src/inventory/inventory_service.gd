extends RefCounted

signal item_changed(item_id: StringName, count: int)
signal money_changed(cents: int)
signal fish_record_updated(fish_id: StringName, catches: int)

var money_cents := 0
var items: Dictionary = {}
var fish_records: Dictionary = {}


func add_item(item_id: StringName, count := 1) -> Error:
	if item_id.is_empty() or count <= 0:
		return ERR_INVALID_PARAMETER
	items[item_id] = item_count(item_id) + count
	item_changed.emit(item_id, item_count(item_id))
	return OK


func remove_item(item_id: StringName, count := 1) -> Error:
	if item_id.is_empty() or count <= 0:
		return ERR_INVALID_PARAMETER
	if item_count(item_id) < count:
		return ERR_UNAVAILABLE
	items[item_id] = item_count(item_id) - count
	if item_count(item_id) == 0:
		items.erase(item_id)
	item_changed.emit(item_id, item_count(item_id))
	return OK


func item_count(item_id: StringName) -> int:
	return int(items.get(item_id, 0))


func add_money(cents: int) -> Error:
	if cents < 0:
		return ERR_INVALID_PARAMETER
	money_cents += cents
	money_changed.emit(money_cents)
	return OK


func spend_money(cents: int) -> Error:
	if cents < 0:
		return ERR_INVALID_PARAMETER
	if money_cents < cents:
		return ERR_UNAVAILABLE
	money_cents -= cents
	money_changed.emit(money_cents)
	return OK


func record_fish(fish_id: StringName, sell_value_cents: int) -> Error:
	if fish_id.is_empty() or sell_value_cents < 0:
		return ERR_INVALID_PARAMETER
	var item_id := StringName("fish_%s" % fish_id)
	add_item(item_id)
	var record: Dictionary = fish_records.get(fish_id, {"catches": 0, "best_value_cents": 0})
	record["catches"] = int(record["catches"]) + 1
	record["best_value_cents"] = maxi(int(record["best_value_cents"]), sell_value_cents)
	fish_records[fish_id] = record
	fish_record_updated.emit(fish_id, int(record["catches"]))
	return OK


func snapshot() -> Dictionary:
	return {"money_cents": money_cents, "items": items.duplicate(true), "fish_records": fish_records.duplicate(true)}


func restore(data: Dictionary) -> Error:
	var next_money := int(data.get("money_cents", -1))
	var next_items_value: Variant = data.get("items", {})
	var next_records_value: Variant = data.get("fish_records", {})
	if next_money < 0 or not next_items_value is Dictionary or not next_records_value is Dictionary:
		return ERR_INVALID_DATA
	for item_value in next_items_value.values():
		if int(item_value) < 0:
			return ERR_INVALID_DATA
	for record_value in next_records_value.values():
		if not record_value is Dictionary or int(record_value.get("catches", -1)) < 0 or int(record_value.get("best_value_cents", -1)) < 0:
			return ERR_INVALID_DATA
	money_cents = next_money
	items = next_items_value.duplicate(true)
	fish_records = next_records_value.duplicate(true)
	return OK
