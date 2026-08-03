extends RefCounted

var _prices: Dictionary = {}


func configure(data: Dictionary) -> Error:
	var entries_value: Variant = data.get("items", [])
	if not entries_value is Array:
		return ERR_INVALID_DATA
	_prices.clear()
	for entry_value in entries_value:
		if not entry_value is Dictionary:
			return ERR_INVALID_DATA
		var entry: Dictionary = entry_value
		var item_id := StringName(entry.get("id", ""))
		var price := int(entry.get("sell_value_cents", -1))
		if item_id.is_empty() or price < 0 or _prices.has(item_id):
			return ERR_INVALID_DATA
		_prices[item_id] = price
	return OK


func ship_all(inventory) -> Dictionary:
	if inventory == null:
		return {"error": ERR_INVALID_PARAMETER}
	var item_count := 0
	var earned := 0
	var item_ids: Array = inventory.items.keys()
	for item_value in item_ids:
		var item_id := StringName(item_value)
		var count: int = inventory.item_count(item_id)
		if count <= 0 or not _prices.has(item_id):
			continue
		inventory.remove_item(item_id, count)
		item_count += count
		earned += count * int(_prices[item_id])
	if earned > 0:
		inventory.add_money(earned)
	return {"items": item_count, "earned_cents": earned}
