extends RefCounted

enum SubmitResult {
	PROGRESSED,
	STAGE_COMPLETED,
	QUEST_COMPLETED,
	ACCEPTED_NO_PROGRESS,
	DUPLICATE,
	REJECTED_INVALID,
	REJECTED_NOT_ACTIVE,
	REJECTED_OUT_OF_ORDER,
}

const CONTRACT_VERSION := 1
const ENABLED_KINDS := [&"interaction.completed", &"inventory.changed", &"inventory.delivered"]
const RESERVED_KINDS := [&"dialogue.seen", &"mahjong.won", &"story.choice"]
const ENVELOPE_KEYS := ["contract_version", "event_id", "kind", "source_id", "payload"]


static func normalize(event_value: Variant) -> Dictionary:
	if not event_value is Dictionary:
		return _failure("$", "event must be a dictionary")
	var event: Dictionary = event_value
	var unknown := _unknown_keys(event, ENVELOPE_KEYS)
	if not unknown.is_empty():
		return _failure("$.%s" % unknown[0], "unknown event field")
	for required in ENVELOPE_KEYS:
		if not event.has(required):
			return _failure("$.%s" % required, "required event field is missing")
	if int(event.get("contract_version", -1)) != CONTRACT_VERSION:
		return _failure("$.contract_version", "unsupported quest-event contract version")
	var kind := StringName(event.get("kind", ""))
	if RESERVED_KINDS.has(kind):
		return _failure("$.kind", "reserved event kind is not enabled")
	if not ENABLED_KINDS.has(kind):
		return _failure("$.kind", "unknown event kind")
	for field in ["source_id", "kind"]:
		if not _valid_id(String(event.get(field, ""))):
			return _failure("$.%s" % field, "must be a stable ID")
	var event_id := String(event.get("event_id", ""))
	if kind != &"inventory.changed" and not _valid_id(event_id):
		return _failure("$.event_id", "committed events require a stable event ID")
	if kind == &"inventory.changed" and not event_id.is_empty():
		return _failure("$.event_id", "state reports must use an empty event ID")
	var payload_value: Variant = event.get("payload")
	if not payload_value is Dictionary or not _stable_value(payload_value):
		return _failure("$.payload", "payload must contain only stable data values")
	var payload_result := _validate_payload(kind, payload_value)
	if not payload_result.is_empty():
		return payload_result
	return {"event": event.duplicate(true)}


static func make_interaction(interaction_id: StringName, source_id: StringName, event_id: StringName) -> Dictionary:
	return {"contract_version": CONTRACT_VERSION, "event_id": event_id, "kind": &"interaction.completed", "source_id": source_id, "payload": {"interaction_id": interaction_id}}


static func make_inventory_report(item_id: StringName, previous_count: int, current_count: int, reason: StringName) -> Dictionary:
	return {"contract_version": CONTRACT_VERSION, "event_id": "", "kind": &"inventory.changed", "source_id": &"inventory", "payload": {"item_id": item_id, "previous_count": previous_count, "current_count": current_count, "reason": reason}}


static func make_delivery(delivery_id: StringName, source_id: StringName, receipt: Dictionary) -> Dictionary:
	var transaction_id := StringName(receipt.get("transaction_id", ""))
	return {"contract_version": CONTRACT_VERSION, "event_id": transaction_id, "kind": &"inventory.delivered", "source_id": source_id, "payload": {"delivery_id": delivery_id, "transaction_id": transaction_id, "items": receipt.get("items", []).duplicate(true)}}


static func _validate_payload(kind: StringName, payload: Dictionary) -> Dictionary:
	match kind:
		&"interaction.completed":
			return _validate_id_payload(payload, ["interaction_id"])
		&"inventory.changed":
			var shape := _validate_exact_keys(payload, ["item_id", "previous_count", "current_count", "reason"])
			if not shape.is_empty():
				return shape
			if not _valid_id(String(payload.get("item_id", ""))) or not _valid_id(String(payload.get("reason", ""))):
				return _failure("$.payload", "item_id and reason must be stable IDs")
			if not payload.get("previous_count") is int or not payload.get("current_count") is int or int(payload["previous_count"]) < 0 or int(payload["current_count"]) < 0:
				return _failure("$.payload.current_count", "inventory counts must be non-negative integers")
		&"inventory.delivered":
			var shape := _validate_exact_keys(payload, ["delivery_id", "transaction_id", "items"])
			if not shape.is_empty():
				return shape
			for field in ["delivery_id", "transaction_id"]:
				if not _valid_id(String(payload.get(field, ""))):
					return _failure("$.payload.%s" % field, "must be a stable ID")
			var items_value: Variant = payload.get("items")
			if not items_value is Array or items_value.is_empty():
				return _failure("$.payload.items", "delivery requires a non-empty item array")
			for index in items_value.size():
				var item_value: Variant = items_value[index]
				if not item_value is Dictionary:
					return _failure("$.payload.items[%d]" % index, "delivery item must be a dictionary")
				var item_shape := _validate_exact_keys(item_value, ["item_id", "quantity"], "$.payload.items[%d]" % index)
				if not item_shape.is_empty():
					return item_shape
				if not _valid_id(String(item_value.get("item_id", ""))):
					return _failure("$.payload.items[%d].item_id" % index, "must be a stable ID")
				if not item_value.get("quantity") is int or int(item_value["quantity"]) <= 0:
					return _failure("$.payload.items[%d].quantity" % index, "delivery quantity must be a positive integer")
	return {}


static func _validate_id_payload(payload: Dictionary, keys: Array) -> Dictionary:
	var shape := _validate_exact_keys(payload, keys)
	if not shape.is_empty():
		return shape
	for key in keys:
		if not _valid_id(String(payload.get(key, ""))):
			return _failure("$.payload.%s" % key, "must be a stable ID")
	return {}


static func _validate_exact_keys(value: Dictionary, keys: Array, path := "$.payload") -> Dictionary:
	var unknown := _unknown_keys(value, keys)
	if not unknown.is_empty():
		return _failure("%s.%s" % [path, unknown[0]], "unknown payload field")
	for key in keys:
		if not value.has(key):
			return _failure("%s.%s" % [path, key], "required payload field is missing")
	return {}


static func _unknown_keys(value: Dictionary, allowed: Array) -> Array[String]:
	var result: Array[String] = []
	for key_value in value:
		var key := String(key_value)
		if not allowed.has(key):
			result.append(key)
	result.sort()
	return result


static func _valid_id(value: String) -> bool:
	if value.is_empty():
		return false
	for index in value.length():
		var code := value.unicode_at(index)
		if not (code >= 97 and code <= 122) and not (code >= 48 and code <= 57) and code not in [45, 46, 95]:
			return false
	return value.unicode_at(0) >= 97 and value.unicode_at(0) <= 122


static func _stable_value(value: Variant) -> bool:
	if value == null or value is bool or value is int or value is String or value is StringName:
		return true
	if value is Array:
		for child in value:
			if not _stable_value(child):
				return false
		return true
	if value is Dictionary:
		for key in value:
			if not (key is String or key is StringName) or not _stable_value(value[key]):
				return false
		return true
	return false


static func _failure(path: String, message: String) -> Dictionary:
	return {"diagnostic": {"path": path, "message": message}}
