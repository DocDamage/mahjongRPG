extends RefCounted

const BrandLoadoutState = preload("res://src/mahjong/application/brand_loadout_state.gd")
const HelperService = preload("res://src/helpers/helper_service.gd")
const EvidenceService = preload("res://src/story/evidence_service.gd")
const GameSessionScript = preload("res://src/core/game_session.gd")
const HorseTravelState = preload("res://src/horses/horse_travel_state.gd")
const OpponentSchedule = preload("res://src/npcs/opponent_schedule.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_brands(failures)
	_test_helper_and_evidence(failures)
	_test_mounted_location(failures)
	_test_schedule_feedback(failures)
	return failures


func _test_brands(failures: Array[String]) -> void:
	var brands := BrandLoadoutState.new()
	if not brands.is_unlocked(&"orange") or not brands.is_unlocked(&"blue"):
		failures.append("new games must grant both playable starter Brands")
	if brands.select([&"orange", &"orange"]) != ERR_INVALID_PARAMETER:
		failures.append("a Brand loadout must contain two distinct unlocked Brands")
	if brands.select([&"blue", &"orange"]) != OK or brands.last_selected != [&"blue", &"orange"]:
		failures.append("the chosen pre-match Brand loadout must persist in state")


func _test_helper_and_evidence(failures: Array[String]) -> void:
	var session := GameSessionScript.new()
	session.start_new_game(15)
	if session.helpers.assign(&"mabel") != OK:
		failures.append("Mabel must be assignable from canonical helper data")
	if session.farm.plant(Vector2i(0, 0), &"corn", session.day) != OK:
		failures.append("helper test must plant an active crop")
	var result: Dictionary = session.helpers.activate(&"mabel", session.farm, session.day)
	if int(result.get("watered", 0)) != 1 or session.helpers.activate(&"mabel", session.farm, session.day).get("error") != ERR_BUSY:
		failures.append("Mabel must water crops once per day with visible bounded use")
	if session.evidence.discover(&"silas_first_lantern_note") != OK or not session.evidence.has(&"silas_first_lantern_note"):
		failures.append("the first Silas clue must be tracked as evidence")
	var restored := GameSessionScript.new()
	if restored.restore(session.snapshot()) != OK or not restored.helpers.is_assigned(&"mabel") or not restored.evidence.has(&"silas_first_lantern_note"):
		failures.append("helper assignments and evidence must round-trip through saves")
	session.free()
	restored.free()


func _test_mounted_location(failures: Array[String]) -> void:
	var horse := HorseTravelState.new()
	horse.mount(true, "res://src/world/wayward_farm.tscn", Vector2(332, 211))
	horse.record_mounted_location("res://src/world/wayward_farm.tscn", Vector2(401, 288))
	var restored := HorseTravelState.new()
	if restored.restore(horse.snapshot()) != OK or not restored.mounted or restored.mounted_position != Vector2(401, 288):
		failures.append("a mounted save must restore the horse at its recorded world location")
	var legacy := horse.snapshot()
	legacy.erase("mounted_position")
	if restored.restore(legacy) != OK or restored.mounted:
		failures.append("legacy mounted saves without a position must use a safe dismounted fallback")


func _test_schedule_feedback(failures: Array[String]) -> void:
	var available := OpponentSchedule.state(&"mayor_bell", &"clear", 10)
	var unavailable := OpponentSchedule.state(&"mayor_bell", &"rain", 8)
	if not bool(available.get("available", false)) or String(available.get("activity", "")).is_empty() or bool(unavailable.get("available", true)) or String(unavailable.get("activity", "")).is_empty():
		failures.append("opponent schedules must expose availability and readable activity feedback")
