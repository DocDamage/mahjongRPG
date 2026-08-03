extends RefCounted

const FishCatalog = preload("res://src/fishing/fish_catalog.gd")
const GameSessionScript = preload("res://src/core/game_session.gd")
const OpponentSchedule = preload("res://src/npcs/opponent_schedule.gd")
const WeatherCatalog = preload("res://src/weather/weather_catalog.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_angler_catalog_progression_and_contest(failures)
	_test_desert_weather_story_and_migrations(failures)
	return failures


func _test_angler_catalog_progression_and_contest(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(909)
	if FishCatalog.definitions().size() < 12 or FishCatalog.shore_conditions() != [&"creek", &"river", &"harbor", &"coast", &"reef"]:
		failures.append("P9 must register the complete launch roster across every authored shore condition")
	var tarpon := FishCatalog.definition(&"tarpon")
	if tarpon.is_empty() or not session.angler.gear_profile().has("hook_window_multiplier") or session.angler.has_condition(&"high_tide"):
		failures.append("P9 new saves must own a valid starter loadout and leave rare conditions undiscovered")
	session.inventory.add_money(2_000)
	for gear in [{"id": &"coastal_rod", "category": &"rod"}, {"id": &"brine_bait", "category": &"bait"}, {"id": &"tide_spoon", "category": &"lure"}, {"id": &"circle_hook", "category": &"hook"}, {"id": &"salt_line", "category": &"line"}, {"id": &"lantern_bobber", "category": &"bobber"}]:
		if session.angler.buy_gear(gear["id"], session.inventory) != OK or session.angler.equip(gear["category"], gear["id"]) != OK:
			failures.append("P9 must support purchase and equip progression for every gear category")
	if float(session.angler.gear_profile()["reel_multiplier"]) <= 1.08:
		failures.append("P9 gear purchases must persist and improve the equipped fishing profile")
	if session.angler.discover_condition(&"high_tide") != OK or session.angler.record_catch(&"tarpon", int(tarpon["sell_value_cents"]), session.inventory) != OK:
		failures.append("P9 must record rare conditions and catches through the stable angler service")
	var contest: Dictionary = session.angler.enter_contest(&"gulls_rest_weekly", &"tarpon", session.inventory)
	if contest.has("error") or not bool(contest.get("won", false)) or int(session.angler.contests[&"gulls_rest_weekly"]["entries"]) != 1:
		failures.append("P9 contests must consume an eligible catch, score it, reward it, and remain repeatable")
	var pre_phase_nine := session.snapshot()
	pre_phase_nine["schema_version"] = 13
	pre_phase_nine.erase("angler"); pre_phase_nine.erase("desert")
	var restored = GameSessionScript.new()
	if restored.restore(pre_phase_nine) != OK or not restored.angler.owned_gear.has(&"cork_bobber") or not restored.angler.records.is_empty():
		failures.append("pre-P9 saves must gain safe empty fish, gear, record, and contest state")
	session.free(); restored.free()


func _test_desert_weather_story_and_migrations(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(1010)
	if session.regions.is_unlocked(&"gulls_rest") or session.regions.is_unlocked(&"red_testament") or session.crafting.definitions.size() < 8:
		failures.append("P9/P10 regions must be registered but honestly locked on a fresh save, with coastal recipes available")
	for weather_id in WeatherCatalog.active_ids():
		if OpponentSchedule.state(&"captain_coral", weather_id, 14).is_empty() or OpponentSchedule.state(&"witness_ash", weather_id, 14).is_empty():
			failures.append("P9/P10 opponents require inspectable schedules for every active weather variant")
	session.set_weather(&"dust_wind")
	if session.desert.survive_route(&"red_testament_windward_pass", session.weather_id) != OK or session.desert.record_supernatural(&"red_lantern_ledger") != OK or session.desert.discover_secret(&"red_testament_sun_dial") != OK:
		failures.append("P10 must save a weather-dependent route and a supernatural record")
	if session.properties.resolve(&"red_testament_expedition", &"clue") != OK or not session.properties.route_is_open(&"red_testament_ruins") or session.evidence.discover(&"texas_king_counter_deed") != OK:
		failures.append("P10 must provide a property-gated ruin route and a counterable Texas King rule clue")
	var round_trip := session.snapshot()
	var restored = GameSessionScript.new()
	if restored.restore(round_trip) != OK or not restored.desert.route_survived(&"red_testament_windward_pass") or not restored.desert.region_secrets.has(&"red_testament_sun_dial") or not restored.evidence.has(&"texas_king_counter_deed"):
		failures.append("P10 route, supernatural, and clue state must round-trip")
	var pre_phase_ten := session.snapshot()
	pre_phase_ten["schema_version"] = 14
	pre_phase_ten.erase("desert")
	var migrated = GameSessionScript.new()
	if migrated.restore(pre_phase_ten) != OK or not migrated.desert.route_states.is_empty() or not migrated.desert.recovered_clues.is_empty() or not migrated.desert.region_secrets.is_empty():
		failures.append("pre-P10 saves must gain empty desert route, record, and clue state")
	session.free(); restored.free(); migrated.free()
