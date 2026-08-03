extends RefCounted

const InventoryService = preload("res://src/inventory/inventory_service.gd")
const QuestService = preload("res://src/quests/quest_service.gd")
const QuestEventAdapter = preload("res://src/quests/quest_event_adapter.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var quests = QuestService.new()
	quests.register_definition(_definition())
	quests.start(&"delivery_quest")
	var inventory = InventoryService.new()
	var adapter = QuestEventAdapter.new()
	adapter.bind(quests, inventory)
	var connections: int = inventory.item_changed.get_connections().size()
	adapter.bind(quests, inventory)
	if inventory.item_changed.get_connections().size() != connections:
		failures.append("repeated adapter binding should not duplicate inventory listeners")
	inventory.add_item(&"crop_beans")
	if int(quests.projection(&"delivery_quest")["live_counts"].get(&"crop_beans", 0)) != 1:
		failures.append("adapter inventory signals should replace live projection state")
	var fake := {"transaction_id": &"inventory.tx.fake", "items": [{"item_id": &"crop_beans", "quantity": 1}]}
	if adapter.submit_delivery(&"test.delivery", &"test_source", fake) != quests.REJECTED_INVALID:
		failures.append("delivery without an inventory-owned committed receipt should be rejected")
	var receipt := inventory.remove_batch([{"item_id": &"crop_beans", "quantity": 1}])
	if adapter.submit_delivery(&"test.delivery", &"test_source", receipt) != quests.QUEST_COMPLETED:
		failures.append("a trusted batch receipt should progress its matching delivery objective")
	if adapter.submit_delivery(&"test.delivery", &"test_source", receipt) != quests.DUPLICATE:
		failures.append("a trusted receipt should be consumable only once")
	var old_inventory = inventory
	var replacement = InventoryService.new()
	adapter.bind(quests, replacement)
	if old_inventory.item_changed.is_connected(adapter._on_item_changed) or not adapter.is_bound_to(quests, replacement):
		failures.append("adapter replacement should disconnect the old service and bind the new one")
	adapter.unbind()
	return failures


func _definition() -> Dictionary:
	return {"objective_schema": 1, "id": "delivery_quest", "definition_version": 1, "requirements": {"crop_beans": 1}, "stages": [{"id": "delivery", "legacy_stage": 0, "completion_mode": "all", "objectives": [{"id": "delivery", "type": "event_once", "label_key": "test.delivery", "event_kind": "inventory.delivered", "match": {"delivery_id": "test.delivery"}}]}]}
