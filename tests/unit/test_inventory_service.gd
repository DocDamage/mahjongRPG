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
	inventory.add_item(&"crop_beans", 2)
	inventory.add_item(&"fish_anchovy")
	var batch: Array = [{"item_id": &"crop_beans", "quantity": 1}, {"item_id": &"fish_anchovy", "quantity": 1}]
	var receipt := inventory.remove_batch(batch)
	if receipt.has("error") or inventory.item_count(&"crop_beans") != 1 or inventory.item_count(&"fish_anchovy") != 0:
		failures.append("batch removal should validate and atomically remove every selected item")
	if inventory.rollback_transaction(StringName(receipt.get("transaction_id", ""))) != OK or inventory.item_count(&"crop_beans") != 2 or inventory.item_count(&"fish_anchovy") != 1:
		failures.append("an open inventory transaction should roll back its exact batch")
	var unavailable := inventory.remove_batch([{"item_id": &"crop_beans", "quantity": 3}, {"item_id": &"fish_anchovy", "quantity": 1}])
	if not unavailable.has("error") or inventory.item_count(&"crop_beans") != 2 or inventory.item_count(&"fish_anchovy") != 1:
		failures.append("a failed batch preflight must not partially remove inventory")
	return failures
