extends RefCounted

const SaveServiceScript = preload("res://src/save/save_service.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var service = SaveServiceScript.new()
	var slot := &"manual_1"
	var payload := {"day": 2, "inventory": {"corn": 3}}
	if service.save(slot, payload) != OK:
		failures.append("save should write a valid manual slot")
	else:
		var loaded := service.load_save(slot)
		if loaded.get("payload", {}) != payload:
			failures.append("save payload should round-trip: %s" % loaded)
	if service.is_valid_slot(&"manual_7"):
		failures.append("manual slot seven should be rejected")
	service.free()
	return failures
