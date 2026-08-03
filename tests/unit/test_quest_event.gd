extends RefCounted

const QuestEvent = preload("res://src/quests/quest_event.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var valid := QuestEvent.make_interaction(&"test.interaction", &"trusted_source", &"event.1")
	if not QuestEvent.normalize(valid).has("event"):
		failures.append("a valid interaction event should normalize")
	var unknown := valid.duplicate(true)
	unknown["unexpected"] = true
	if QuestEvent.normalize(unknown).get("diagnostic", {}).get("path", "") != "$.unexpected":
		failures.append("unknown envelope fields should fail with their JSON path")
	var reserved := valid.duplicate(true)
	reserved["kind"] = &"mahjong.won"
	if QuestEvent.normalize(reserved).has("event"):
		failures.append("reserved event kinds should remain disabled in Q1/Q2")
	var malformed := valid.duplicate(true)
	malformed["source_id"] = "Scene/Node"
	if QuestEvent.normalize(malformed).has("event"):
		failures.append("node-path-like source IDs should be rejected")
	var delivery := QuestEvent.make_delivery(&"test.delivery", &"trusted_source", {"transaction_id": &"inventory.tx.1", "items": [{"item_id": &"crop_beans", "quantity": 0}]})
	if QuestEvent.normalize(delivery).has("event"):
		failures.append("delivery quantities must be positive integers")
	var mutable := QuestEvent.make_inventory_report(&"crop_beans", 0, 1, &"test_sync")
	var normalized := QuestEvent.normalize(mutable)
	mutable["payload"]["current_count"] = 99
	if int(normalized["event"]["payload"]["current_count"]) != 1:
		failures.append("normalized event payloads should be deep copied")
	var object_payload := valid.duplicate(true)
	object_payload["payload"]["node"] = RefCounted.new()
	if QuestEvent.normalize(object_payload).has("event"):
		failures.append("runtime object references should be rejected from event payloads")
	return failures
