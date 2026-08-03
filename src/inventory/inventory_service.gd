extends RefCounted

signal item_changed(item_id: StringName, count: int)
signal money_changed(cents: int)
signal fish_record_updated(fish_id: StringName, catches: int)
signal batch_removed(receipt: Dictionary)

var money_cents := 0
var items: Dictionary = {}
var fish_records: Dictionary = {}
var _open_transactions: Dictionary = {}
var _transaction_sequence := 0


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


func validate_batch_removal(item_batch: Array) -> Error:
	var normalized := _normalize_batch(item_batch)
	if normalized.is_empty():
		return ERR_INVALID_PARAMETER
	for entry in normalized:
		if item_count(StringName(entry["item_id"])) < int(entry["quantity"]):
			return ERR_UNAVAILABLE
	return OK


func remove_batch(item_batch: Array) -> Dictionary:
	var normalized := _normalize_batch(item_batch)
	var validation := validate_batch_removal(normalized)
	if validation != OK:
		return {"error": validation}
	for entry in normalized:
		var item_id := StringName(entry["item_id"])
		items[item_id] = item_count(item_id) - int(entry["quantity"])
		if item_count(item_id) == 0:
			items.erase(item_id)
	_transaction_sequence += 1
	var transaction_id := StringName("inventory.tx.%d.%d" % [Time.get_ticks_msec(), _transaction_sequence])
	var receipt := {"transaction_id": transaction_id, "items": normalized.duplicate(true)}
	_open_transactions[transaction_id] = receipt.duplicate(true)
	for entry in normalized:
		var item_id := StringName(entry["item_id"])
		item_changed.emit(item_id, item_count(item_id))
	batch_removed.emit(receipt.duplicate(true))
	return receipt


func commit_transaction(transaction_id: StringName) -> Error:
	if not _open_transactions.has(transaction_id):
		return ERR_DOES_NOT_EXIST
	_open_transactions.erase(transaction_id)
	return OK


func rollback_transaction(transaction_id: StringName) -> Error:
	if not _open_transactions.has(transaction_id):
		return ERR_DOES_NOT_EXIST
	var receipt: Dictionary = _open_transactions[transaction_id]
	_open_transactions.erase(transaction_id)
	for entry in receipt["items"]:
		var item_id := StringName(entry["item_id"])
		items[item_id] = item_count(item_id) + int(entry["quantity"])
		item_changed.emit(item_id, item_count(item_id))
	return OK


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
	_open_transactions.clear()
	return OK


func _normalize_batch(item_batch: Array) -> Array[Dictionary]:
	var quantities: Dictionary = {}
	for entry_value in item_batch:
		if not entry_value is Dictionary:
			return []
		var entry: Dictionary = entry_value
		if entry.size() != 2 or not entry.has("item_id") or not entry.has("quantity"):
			return []
		var item_id := StringName(entry.get("item_id", ""))
		var quantity_value: Variant = entry.get("quantity")
		if item_id.is_empty() or not quantity_value is int or int(quantity_value) <= 0:
			return []
		quantities[item_id] = int(quantities.get(item_id, 0)) + int(quantity_value)
	var ids: Array = quantities.keys()
	ids.sort_custom(func(a, b): return String(a) < String(b))
	var normalized: Array[Dictionary] = []
	for item_value in ids:
		normalized.append({"item_id": StringName(item_value), "quantity": int(quantities[item_value])})
	return normalized
