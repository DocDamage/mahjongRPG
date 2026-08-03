extends RefCounted

signal order_completed(order_id: StringName)
signal table_tokens_changed(tokens: int)

var order_definitions: Dictionary = {}
var shop_definitions: Dictionary = {}
var table_tokens := 0
var active_orders: Dictionary = {}
var completed_orders: Dictionary = {}
var shop_stock: Dictionary = {}


func register_order(data: Dictionary) -> Error:
	var order_id := StringName(data.get("id", ""))
	if order_id.is_empty() or order_definitions.has(order_id) or not data.get("requirements", []) is Array:
		return ERR_INVALID_DATA
	order_definitions[order_id] = data.duplicate(true)
	return OK


func register_shop(data: Dictionary) -> Error:
	var shop_id := StringName(data.get("id", ""))
	if shop_id.is_empty() or shop_definitions.has(shop_id) or not data.get("stock", []) is Array:
		return ERR_INVALID_DATA
	shop_definitions[shop_id] = data.duplicate(true)
	return OK


func post_order(order_id: StringName) -> Error:
	if not order_definitions.has(order_id) or active_orders.has(order_id) or completed_orders.has(order_id):
		return ERR_UNAVAILABLE
	active_orders[order_id] = true
	return OK


func fulfill_order(order_id: StringName, inventory) -> Dictionary:
	if inventory == null or not active_orders.has(order_id):
		return {"error": ERR_UNAVAILABLE}
	var order: Dictionary = order_definitions.get(order_id, {})
	for requirement_value in order.get("requirements", []):
		if not requirement_value is Dictionary or inventory.item_count(StringName(requirement_value.get("item_id", ""))) < int(requirement_value.get("count", 0)):
			return {"error": ERR_UNAVAILABLE}
	for requirement_value in order["requirements"]:
		inventory.remove_item(StringName(requirement_value["item_id"]), int(requirement_value["count"]))
	var rewards: Dictionary = order.get("rewards", {})
	inventory.add_money(maxi(0, int(rewards.get("money_cents", 0))))
	for item_value in rewards.get("items", []):
		if item_value is Dictionary:
			inventory.add_item(StringName(item_value.get("item_id", "")), maxi(1, int(item_value.get("count", 1))))
	table_tokens += maxi(0, int(rewards.get("table_tokens", 0)))
	active_orders.erase(order_id)
	completed_orders[order_id] = true
	table_tokens_changed.emit(table_tokens)
	order_completed.emit(order_id)
	return {"order_id": order_id, "table_tokens": table_tokens, "money_cents": int(rewards.get("money_cents", 0))}


func buy(shop_id: StringName, item_id: StringName, inventory) -> Error:
	if inventory == null or not shop_definitions.has(shop_id):
		return ERR_INVALID_PARAMETER
	_ensure_shop_stock(shop_id)
	var shop: Dictionary = shop_stock[shop_id]
	var entry: Dictionary = shop.get(item_id, {})
	if entry.is_empty() or int(entry.get("count", 0)) < 1 or inventory.spend_money(int(entry.get("price_cents", -1))) != OK:
		return ERR_UNAVAILABLE
	entry["count"] = int(entry["count"]) - 1
	shop[item_id] = entry
	shop_stock[shop_id] = shop
	return inventory.add_item(item_id)


func spend_table_token() -> Error:
	if table_tokens < 1:
		return ERR_UNAVAILABLE
	table_tokens -= 1
	table_tokens_changed.emit(table_tokens)
	return OK


func snapshot() -> Dictionary:
	return {"table_tokens": table_tokens, "active_orders": active_orders.duplicate(true), "completed_orders": completed_orders.duplicate(true), "shop_stock": shop_stock.duplicate(true)}


func restore(data: Dictionary) -> Error:
	var active: Variant = data.get("active_orders", {})
	var completed: Variant = data.get("completed_orders", {})
	var stock: Variant = data.get("shop_stock", {})
	if int(data.get("table_tokens", -1)) < 0 or not active is Dictionary or not completed is Dictionary or not stock is Dictionary:
		return ERR_INVALID_DATA
	for order_id_value in active:
		if not order_definitions.has(StringName(order_id_value)) or completed.has(order_id_value):
			return ERR_INVALID_DATA
	for order_id_value in completed:
		if not order_definitions.has(StringName(order_id_value)):
			return ERR_INVALID_DATA
	for shop_id_value in stock:
		var shop_id := StringName(shop_id_value)
		if not shop_definitions.has(shop_id) or not stock[shop_id_value] is Dictionary:
			return ERR_INVALID_DATA
		for item_id_value in stock[shop_id_value]:
			var entry: Variant = stock[shop_id_value][item_id_value]
			if not entry is Dictionary or int(entry.get("count", -1)) < 0 or int(entry.get("price_cents", -1)) < 0:
				return ERR_INVALID_DATA
	table_tokens = int(data["table_tokens"])
	active_orders = active.duplicate(true)
	completed_orders = completed.duplicate(true)
	shop_stock = stock.duplicate(true)
	return OK


func _ensure_shop_stock(shop_id: StringName) -> void:
	if shop_stock.has(shop_id):
		return
	var stock := {}
	for entry_value in shop_definitions[shop_id].get("stock", []):
		if entry_value is Dictionary:
			stock[StringName(entry_value.get("item_id", ""))] = entry_value.duplicate(true)
	shop_stock[shop_id] = stock
