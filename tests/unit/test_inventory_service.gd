extends RefCounted

const InventoryService = preload("res://src/inventory/inventory_service.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var inventory = InventoryService.new()
	if inventory.record_fish(&"trout", 240) != OK or inventory.item_count(&"fish_trout") != 1:
		failures.append("recording a catch should add its fish item")
	var trout_record: Dictionary = inventory.fish_records.get(&"trout", {})
	if int(trout_record.get("catches", 0)) != 1 or int(trout_record.get("best_value_cents", 0)) != 240:
		failures.append("recording a catch should update collection records")
	inventory.add_money(500)
	if inventory.spend_money(300) != OK or inventory.money_cents != 200 or inventory.spend_money(201) != ERR_UNAVAILABLE:
		failures.append("inventory money should reject overspending")
	var restored = InventoryService.new()
	if restored.restore(inventory.snapshot()) != OK or restored.snapshot() != inventory.snapshot():
		failures.append("inventory and records should survive a snapshot round-trip")
	return failures
