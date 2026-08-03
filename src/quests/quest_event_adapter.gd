extends RefCounted

const QuestEvent = preload("res://src/quests/quest_event.gd")

var _quests
var _inventory
var _known_counts: Dictionary = {}
var _trusted_receipts: Dictionary = {}
var _used_receipts: Dictionary = {}


func bind(quests, inventory) -> Error:
	if quests == null or inventory == null:
		return ERR_INVALID_PARAMETER
	if _quests == quests and _inventory == inventory:
		resync()
		return OK
	unbind()
	_quests = quests
	_inventory = inventory
	_inventory.item_changed.connect(_on_item_changed)
	_inventory.batch_removed.connect(_on_batch_removed)
	resync()
	return OK


func unbind() -> void:
	if _inventory != null:
		if _inventory.item_changed.is_connected(_on_item_changed):
			_inventory.item_changed.disconnect(_on_item_changed)
		if _inventory.batch_removed.is_connected(_on_batch_removed):
			_inventory.batch_removed.disconnect(_on_batch_removed)
	_quests = null
	_inventory = null
	_known_counts.clear()
	_trusted_receipts.clear()
	_used_receipts.clear()


func is_bound_to(quests, inventory) -> bool:
	return _quests == quests and _inventory == inventory


func resync() -> void:
	if _quests == null or _inventory == null:
		return
	var current: Dictionary = _inventory.items.duplicate(true)
	var ids: Array = _known_counts.keys()
	for item_value in current:
		if not ids.has(item_value):
			ids.append(item_value)
	ids.sort_custom(func(a, b): return String(a) < String(b))
	for item_value in ids:
		var item_id := StringName(item_value)
		var previous := int(_known_counts.get(item_id, 0))
		var next := int(current.get(item_id, 0))
		_quests.submit_event(QuestEvent.make_inventory_report(item_id, previous, next, &"adapter_sync"))
	_known_counts = current
	_quests.projection_refreshed.emit()


func submit_interaction(interaction_id: StringName, source_id: StringName, event_id: StringName) -> int:
	if _quests == null:
		return QuestEvent.SubmitResult.REJECTED_INVALID
	return _quests.submit_event(QuestEvent.make_interaction(interaction_id, source_id, event_id))


func submit_delivery(delivery_id: StringName, source_id: StringName, receipt: Dictionary) -> int:
	if _quests == null:
		return QuestEvent.SubmitResult.REJECTED_INVALID
	var transaction_id := StringName(receipt.get("transaction_id", ""))
	if _used_receipts.has(transaction_id):
		return QuestEvent.SubmitResult.DUPLICATE
	if transaction_id.is_empty() or not _trusted_receipts.has(transaction_id) or _trusted_receipts[transaction_id] != receipt:
		return QuestEvent.SubmitResult.REJECTED_INVALID
	_trusted_receipts.erase(transaction_id)
	if _quests.authorize_delivery_receipt(transaction_id) != OK:
		return QuestEvent.SubmitResult.REJECTED_INVALID
	var result: int = _quests.submit_event(QuestEvent.make_delivery(delivery_id, source_id, receipt))
	if is_progress_result(result):
		_used_receipts[transaction_id] = true
	return result


func is_progress_result(result: int) -> bool:
	return result in [QuestEvent.SubmitResult.PROGRESSED, QuestEvent.SubmitResult.STAGE_COMPLETED, QuestEvent.SubmitResult.QUEST_COMPLETED]


func _on_item_changed(item_id: StringName, current_count: int) -> void:
	if _quests == null:
		return
	var previous := int(_known_counts.get(item_id, 0))
	if current_count == 0:
		_known_counts.erase(item_id)
	else:
		_known_counts[item_id] = current_count
	_quests.submit_event(QuestEvent.make_inventory_report(item_id, previous, current_count, &"service_signal"))


func _on_batch_removed(receipt: Dictionary) -> void:
	var transaction_id := StringName(receipt.get("transaction_id", ""))
	if not transaction_id.is_empty():
		_trusted_receipts[transaction_id] = receipt.duplicate(true)
