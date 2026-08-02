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
	if session.farm.place_field(Vector2i(4, 1)) != ERR_UNAVAILABLE or session.farm.place_field(Vector2i(4, 2)) != ERR_ALREADY_EXISTS:
		failures.append("Wayward Farm should protect its route and permanent-object cells from placement")
	session.record_player_state("res://src/world/wayward_farm.tscn", Vector2(123, 234))
	session.set_tutorial_step(&"tenderfoot", 4)
	var weather_session = GameSessionScript.new()
	weather_session.start_new_game(42)
	weather_session.advance_minutes(24 * 60)
	if weather_session.weather_id not in [&"clear", &"rain"]:
		failures.append("day changes should select a supported vertical-slice weather state")
	var snapshot := session.snapshot()
	var restored = GameSessionScript.new()
	if restored.restore(snapshot) != OK or restored.snapshot() != snapshot:
		failures.append("session snapshot should round-trip")
	if session.animals.feed(&"juniper_hens", session.day) != OK:
		failures.append("a new game should initialize the vertical-slice animal group")
	session.advance_minutes(24 * 60)
	if session.animals.collect(&"juniper_hens", session.day) != 2:
		failures.append("daily time progression should generate products for fed animal groups")
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
	var version_three := snapshot.duplicate(true)
	version_three["schema_version"] = 3
	version_three.erase("player")
	if restored.restore(version_three) != OK or not restored.player_scene.is_empty():
		failures.append("version-three session saves should migrate empty player location safely")
	var version_four := snapshot.duplicate(true)
	version_four["schema_version"] = 4
	version_four.erase("tutorial_steps")
	if restored.restore(version_four) != OK or restored.tutorial_step(&"tenderfoot") != 0:
		failures.append("version-four session saves should migrate empty tutorial progress safely")
	var version_five := snapshot.duplicate(true)
	version_five["schema_version"] = 5
	version_five.erase("animals")
	if restored.restore(version_five) != OK or restored.animals.happiness(&"juniper_hens") != 55 or int(restored.animals.snapshot()["animals"]["juniper_hens"]["last_progress_day"]) != int(snapshot["day"]):
		failures.append("version-five session saves should migrate default animal care safely")
	var version_six := snapshot.duplicate(true)
	version_six["schema_version"] = 6
	version_six["farm"].erase("constructions")
	if restored.restore(version_six) != OK or not restored.farm.construction_anchors().is_empty():
		failures.append("version-six saves should migrate an empty construction layer safely")
	session.free()
	restored.free()
	weather_session.free()
	return failures
