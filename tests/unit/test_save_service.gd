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
	var session = GameSessionScript.new()
	session.start_new_game(91)
	session.farm.plant(Vector2i(0, 0), &"beans", 1)
	session.farm.water(Vector2i(0, 0), 1)
	session.advance_minutes(90)
	if service.save(&"manual_2", session.snapshot()) != OK:
		failures.append("a full game-session snapshot should save")
	else:
		var restored = GameSessionScript.new()
		var saved_session := service.load_save(&"manual_2")
		if restored.restore(saved_session.get("payload", {})) != OK or restored.snapshot() != session.snapshot():
			failures.append("time, weather, and farm state should round-trip through SaveService")
		restored.free()
	session.free()
	service.free()
	return failures
