extends RefCounted

const InventoryService = preload("res://src/inventory/inventory_service.gd")
const ShippingService = preload("res://src/economy/shipping_service.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var shipping = ShippingService.new()
	if shipping.configure({"items": [{"id": "crop_beans", "sell_value_cents": 70}, {"id": "fish_trout", "sell_value_cents": 240}]}) != OK:
		failures.append("shipping prices should load from declarative item data")
		return failures
	var inventory = InventoryService.new()
	inventory.add_item(&"crop_beans", 2)
	inventory.record_fish(&"trout", 240)
	inventory.add_item(&"unknown", 3)
	var shipped: Dictionary = shipping.ship_all(inventory)
	if int(shipped.get("items", 0)) != 3 or int(shipped.get("earned_cents", 0)) != 380:
		failures.append("shipping should total priced crop and fish inventory")
	if inventory.money_cents != 380 or inventory.item_count(&"unknown") != 3 or inventory.item_count(&"crop_beans") != 0:
		failures.append("shipping should leave unsupported items and remove only sold stock")
	return failures
