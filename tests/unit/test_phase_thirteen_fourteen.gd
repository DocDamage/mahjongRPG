extends RefCounted

const GameSessionScript = preload("res://src/core/game_session.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_public_life_properties_events_and_rank(failures)
	_test_act_three_kings_reach_readiness_and_migrations(failures)
	return failures


func _test_public_life_properties_events_and_rank(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(1314)
	_complete_community(session, failures)
	_resolve_public_properties(session, failures)
	if session.public_life.contribution_total() != 6:
		failures.append("P13 must collect a stable public contribution from every resolved property")
	if session.public_life.schedule(&"market_day", session.day, session.properties, session.community, session.brands.hall_stage) != OK or session.public_life.reschedule(&"market_day", session.day + 1) != OK:
		failures.append("P13 repeatable public events must be schedulable and reschedulable")
	var market: Dictionary = session.public_life.attend(&"market_day", session.day + 1)
	if market.has("error") or not session.public_life.has_completed(&"market_day"):
		failures.append("P13 market day must attend safely after its rescheduled day")
	if session.public_life.schedule(&"town_tournament", session.day, session.properties, session.community, session.brands.hall_stage) != OK:
		failures.append("P13 tournament must require the completed market event and authored public cases")
	if not session.public_life.attend(&"town_tournament", session.day).has("error"):
		failures.append("P13 tournament completion must require a real public Mahjong match win")
	var tournament: Dictionary = session.public_life.attend(&"town_tournament", session.day, true)
	if tournament.has("error") or int(tournament.get("hall_stage", 0)) != 4 or session.brands.unlock_hall_stage(4) != OK:
		failures.append("P13 town tournament must raise the Hall to public stage four")
	if session.public_life.schedule(&"hall_reopening", session.day, session.properties, session.community, session.brands.hall_stage) != OK:
		failures.append("P13 reopening must require contributions, community support, properties, and tournament completion")
	var reopening: Dictionary = session.public_life.attend(&"hall_reopening", session.day)
	if reopening.has("error") or int(reopening.get("hall_stage", 0)) != 5 or session.brands.unlock_hall_stage(5) != OK or session.brands.hall_stage != 5:
		failures.append("P13 must restore the legendary fifth Hall stage")
	if session.public_life.schedule(&"final_championship", session.day, session.properties, session.community, session.brands.hall_stage) != OK or not session.public_life.is_scheduled(&"final_championship"):
		failures.append("P13 must schedule, but not prematurely play, the separately gated final championship")
	var round_trip := session.snapshot()
	var restored = GameSessionScript.new()
	if restored.restore(round_trip) != OK or restored.brands.hall_stage != 5 or not restored.public_life.is_scheduled(&"final_championship") or restored.public_life.rank_id != &"legend":
		failures.append("P13 public properties, event phases, Hall stage, rank, and final schedule must round-trip")
	session.free(); restored.free()


func _test_act_three_kings_reach_readiness_and_migrations(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(1414)
	_complete_community(session, failures)
	_resolve_public_properties(session, failures)
	_complete_public_loop(session, failures)
	for clue_id in [&"inheritance_deed", &"silas_first_lantern_note", &"silas_bridlewood_ledger", &"silas_government_record", &"silas_cargo_ledger", &"silas_gulls_rest_letter", &"texas_king_counter_deed"]:
		session.evidence.discover(clue_id)
	if session.story.validate_clue_chain(session.evidence) != OK or session.story.discover_bargain(session.evidence) != OK:
		failures.append("P14 must validate the authored regional clue chain before revealing the bargain")
	for rule_id in [&"binding_stake", &"category_declaration", &"bloodline_claim"]:
		if session.story.explain_rule(rule_id, session.evidence) != OK:
			failures.append("P14 must explain every altered Texas King rule from its evidence")
	if session.story.prove_silas_alive(session.evidence) != OK or not session.story.can_enter_kings_reach():
		failures.append("P14 must prove Silas alive before unlocking King's Reach")
	if session.story.choose_consequence(&"protect_town") != OK or session.story.choose_consequence(&"preserve_records") == OK:
		failures.append("P14 must save one consequential investigation choice rather than accepting contradictory choices")
	for site_id in [&"outer_gate", &"sealed_study", &"watchtower"]:
		if session.story.explore_kings_reach(site_id) != OK:
			failures.append("P14 King's Reach must expose every authored exploration site")
	if session.story.accept_final_warning(session.public_life, session.community) != OK or not session.story.final_warning_accepted:
		failures.append("P14 must end safely at an explicit warning with the final championship still separately gated")
	var round_trip := session.snapshot()
	var restored = GameSessionScript.new()
	if restored.restore(round_trip) != OK or not restored.story.final_warning_accepted or not restored.evidence.has(&"silas_alive_signal"):
		failures.append("P14 evidence, choices, exploration, and readiness state must round-trip")
	var corrupt_warning := round_trip.duplicate(true)
	corrupt_warning["public_life"]["event_states"]["final_championship"]["phase"] = "available"
	var corrupt_restored = GameSessionScript.new()
	if corrupt_restored.restore(corrupt_warning) == OK:
		failures.append("P14 corrupt readiness state must reject a warning without its scheduled championship")
	var pre_thirteen := session.snapshot()
	pre_thirteen["schema_version"] = 17
	pre_thirteen.erase("public_life"); pre_thirteen.erase("story")
	var p13_migrated = GameSessionScript.new()
	if p13_migrated.restore(pre_thirteen) != OK or p13_migrated.public_life.rank_points != 0 or p13_migrated.public_life.contribution_total() != 6 or p13_migrated.story.chain_validated:
		failures.append("pre-P13 saves must gain safe public rank/story defaults while recognizing prior resolved property contributions")
	var pre_fourteen := session.snapshot()
	pre_fourteen["schema_version"] = 18
	pre_fourteen.erase("story")
	var p14_migrated = GameSessionScript.new()
	if p14_migrated.restore(pre_fourteen) != OK or p14_migrated.public_life.rank_points <= 0 or p14_migrated.story.chain_validated:
		failures.append("P13 saves must retain public-life state while gaining safe empty P14 story records")
	session.free(); restored.free(); corrupt_restored.free(); p13_migrated.free(); p14_migrated.free()


func _complete_community(session, failures: Array[String]) -> void:
	for arc_id_value in session.community.definitions:
		var arc_id := StringName(arc_id_value)
		for _index in 3:
			var action: StringName = session.community.expected_action(arc_id)
			if session.community.advance(arc_id, action, session.relationships, session.helpers).has("error"):
				failures.append("P13/P14 setup must complete every authored community arc")
				return


func _resolve_public_properties(session, failures: Array[String]) -> void:
	for item_id in [&"artisan_cheese", &"crop_wheat", &"fish_tarpon", &"flour"]:
		session.inventory.add_item(item_id)
	var resolutions := [{"id": &"saints_landing_depot", "method": &"quest"}, {"id": &"ironhook_customs_warehouse", "method": &"order"}, {"id": &"red_testament_expedition", "method": &"clue"}, {"id": &"bridlewood_water_right", "method": &"quest"}, {"id": &"gulls_rest_mooring", "method": &"quest"}, {"id": &"saints_market_charter", "method": &"quest"}]
	for resolution in resolutions:
		if session.properties.resolve(resolution["id"], resolution["method"], session.inventory) != OK:
			failures.append("P13 property resolution must preserve every authored resolution method")
	session.public_life.sync_property_contributions(session.properties)
	if session.brands.unlock_hall_stage(3) != OK:
		failures.append("P13 setup requires the prior public Hall practice stage")


func _complete_public_loop(session, failures: Array[String]) -> void:
	if session.public_life.schedule(&"market_day", session.day, session.properties, session.community, session.brands.hall_stage) != OK or session.public_life.attend(&"market_day", session.day).has("error"):
		failures.append("P14 setup must complete the P13 market loop")
	if session.public_life.schedule(&"town_tournament", session.day, session.properties, session.community, session.brands.hall_stage) != OK:
		failures.append("P14 setup must schedule the public tournament")
	var tournament: Dictionary = session.public_life.attend(&"town_tournament", session.day, true)
	if tournament.has("error") or session.brands.unlock_hall_stage(int(tournament.get("hall_stage", 0))) != OK:
		failures.append("P14 setup must restore Hall stage four")
	if session.public_life.schedule(&"hall_reopening", session.day, session.properties, session.community, session.brands.hall_stage) != OK:
		failures.append("P14 setup must schedule the Hall reopening")
	var reopening: Dictionary = session.public_life.attend(&"hall_reopening", session.day)
	if reopening.has("error") or session.brands.unlock_hall_stage(int(reopening.get("hall_stage", 0))) != OK:
		failures.append("P14 setup must restore Hall stage five")
	if session.public_life.schedule(&"final_championship", session.day, session.properties, session.community, session.brands.hall_stage) != OK:
		failures.append("P14 setup must schedule the final championship")
