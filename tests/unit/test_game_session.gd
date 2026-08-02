extends RefCounted

const GameSessionScript = preload("res://src/core/game_session.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var session = GameSessionScript.new()
	session.start_new_game(42)
	session.advance_minutes(1_440 + 5)
	if session.day != 2 or session.minute_of_day != 485:
		failures.append("time should roll into the next day")
	session.request_pause(&"dialogue")
	session.advance_minutes(30)
	if session.minute_of_day != 485:
		failures.append("paused time should not advance")
	session.release_pause(&"dialogue")
	session.complete_mahjong_match()
	if session.minute_of_day != 575:
		failures.append("a Mahjong match should cost 90 minutes")
	var snapshot := session.snapshot()
	var restored = GameSessionScript.new()
	if restored.restore(snapshot) != OK or restored.snapshot() != snapshot:
		failures.append("session snapshot should round-trip")
	var legacy := snapshot.duplicate(true)
	legacy["schema_version"] = 1
	legacy.erase("inventory")
	if restored.restore(legacy) != OK or restored.inventory.money_cents != 0:
		failures.append("version-one session saves should migrate an empty inventory safely")
	var version_two := snapshot.duplicate(true)
	version_two["schema_version"] = 2
	version_two.erase("quests")
	if restored.restore(version_two) != OK or not restored.quests.completed.is_empty():
		failures.append("version-two session saves should migrate empty quest state safely")
	session.free()
	restored.free()
	return failures
