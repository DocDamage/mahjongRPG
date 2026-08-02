extends RefCounted

const SaveServiceScript = preload("res://src/save/save_service.gd")
const GameSessionScript = preload("res://src/core/game_session.gd")


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
	for slot_number in range(1, SaveServiceScript.MANUAL_SLOT_COUNT + 1):
		var manual_slot := StringName("manual_%d" % slot_number)
		if not service.is_valid_slot(manual_slot):
			failures.append("every configured manual slot should be valid")
			continue
		var slot_payload := {"slot": slot_number}
		if service.save(manual_slot, slot_payload) != OK or service.load_save(manual_slot).get("payload", {}) != slot_payload:
			failures.append("manual slot %d should independently round-trip" % slot_number)
	if service.save_current_session(slot) != ERR_UNAVAILABLE or service.load_current_session(slot) != ERR_UNAVAILABLE:
		failures.append("detached save services should report unavailable game sessions")
	var recovery_slot := &"manual_6"
	var backup_payload := {"revision": 1}
	if service.save(recovery_slot, backup_payload) != OK or service.save(recovery_slot, {"revision": 2}) != OK:
		failures.append("save recovery setup should write primary and backup documents")
	else:
		var corrupt_file := FileAccess.open("%s/%s.json" % [SaveServiceScript.SAVE_DIRECTORY, recovery_slot], FileAccess.WRITE)
		if corrupt_file == null:
			failures.append("save recovery test should be able to corrupt the primary document")
		else:
			corrupt_file.store_string("not valid json")
			corrupt_file.close()
			var recovered := service.load_save(recovery_slot)
			if recovered.get("payload", {}) != backup_payload or not recovered.get("recovered_from_backup", false):
				failures.append("a corrupt primary save should recover the prior backup")
	var session = GameSessionScript.new()
	session.start_new_game(91)
	session.farm.plant(Vector2i(0, 0), &"beans", 1)
	session.farm.water(Vector2i(0, 0), 1)
	session.horse.discover(&"wayward_farm")
	session.horse.mount(true)
	session.advance_minutes(90)
	if service.save(&"manual_2", session.snapshot()) != OK:
		failures.append("a full game-session snapshot should save")
	else:
		var restored = GameSessionScript.new()
		var saved_session := service.load_save(&"manual_2")
		if restored.restore(saved_session.get("payload", {})) != OK or restored.snapshot() != session.snapshot():
			failures.append("time, weather, farm, and horse state should round-trip through SaveService")
		restored.free()
	session.free()
	service.free()
	return failures
