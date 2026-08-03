extends RefCounted

const GameSessionScript = preload("res://src/core/game_session.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_finale_checkpoint_standoff_endings_and_credits(failures)
	_test_postgame_continuity_collections_and_migrations(failures)
	return failures


func _test_finale_checkpoint_standoff_endings_and_credits(failures: Array[String]) -> void:
	var session = _finale_ready_session(&"protect_town", failures)
	if session == null:
		return
	if session.finale.begin_championship(session.story, session.public_life) != OK or not session.finale.pre_finale_checkpoint_required:
		failures.append("P15 must gate Texas King behind the explicit warning and request a dedicated pre-finale backup")
	if session.finale.confirm_pre_finale_checkpoint() != OK:
		failures.append("P15 must confirm the dedicated pre-finale backup before seating Texas King")
	if session.finale.record_championship_result(false, session.public_life, session.day) != OK or not session.finale.can_retry_championship():
		failures.append("P15 must keep a failed Texas King match retryable without consuming the championship")
	if session.finale.record_championship_result(true, session.public_life, session.day) != OK or not session.public_life.has_completed(&"final_championship") or not session.finale.opponent_defeated:
		failures.append("P15 must record opponent eleven and complete the legal scheduled final championship only after a win")
	if session.finale.resolve_standoff(&"yield_to_claim", session.story) == OK or not session.finale.can_retry_standoff():
		failures.append("P15 must permit a failed dialogue standoff to retry locally without replaying Mahjong")
	if session.finale.retry_standoff() != OK or session.finale.resolve_standoff(&"speak_truth", session.story) != OK:
		failures.append("P15 must resolve the standoff through the documented counterable truthful-table response")
	var ending: Dictionary = session.finale.ending_summary()
	if StringName(ending.get("ending_id", "")) != &"open_hall" or not String(ending.get("father_reveal", "")).contains("father") or not String(ending.get("silas_return", "")).contains("Silas"):
		failures.append("P15 must transparently evaluate the earned consequence/standoff category and present father and Silas beats")
	if session.finale.acknowledge_credits() != OK or not session.finale.credits_seen:
		failures.append("P15 must provide credits after the ending rather than silently ending the save")
	var round_trip: Dictionary = session.snapshot()
	var restored = GameSessionScript.new()
	var restore_result: Error = restored.restore(round_trip)
	if restore_result != OK or not restored.finale.credits_seen or StringName(restored.finale.ending_id) != &"open_hall":
		failures.append("P15 finale checkpoints, ending result, and credits state must round-trip (restore %s; phase %s; ending %s)" % [restore_result, restored.finale.phase, restored.finale.ending_id])
	for outcome in [{"consequence": &"protect_town", "response": &"spare_king", "expected": &"mercy_at_sunrise"}, {"consequence": &"preserve_records", "response": &"speak_truth", "expected": &"keeper_of_truth"}, {"consequence": &"preserve_records", "response": &"spare_king", "expected": &"keeper_mercy"}]:
		var variant = _finale_ready_session(outcome["consequence"], failures)
		if variant != null:
			variant.finale.begin_championship(variant.story, variant.public_life)
			variant.finale.confirm_pre_finale_checkpoint()
			variant.finale.record_championship_result(true, variant.public_life, variant.day)
			variant.finale.resolve_standoff(outcome["response"], variant.story)
			if variant.finale.ending_id != outcome["expected"]:
				failures.append("P15 must expose all four deterministic ending categories")
			variant.free()
	session.free(); restored.free()


func _test_postgame_continuity_collections_and_migrations(failures: Array[String]) -> void:
	var session = _finale_ready_session(&"protect_town", failures)
	if session == null:
		return
	if session.postgame.enter(session.finale, session.public_life) == OK:
		failures.append("P16 must not expose postgame before an ending and credits")
	_finish_finale(session, &"speak_truth", failures)
	if session.postgame.enter(session.finale, session.public_life) != OK or not session.postgame.is_active() or session.postgame.ending_provenance != &"open_hall":
		failures.append("P16 must create one canonical postgame state with the earned ending provenance")
	if not ResourceLoader.exists("res://src/world/postgame_landmark.gd") or not ResourceLoader.exists("res://src/ui/credits_roll.gd"):
		failures.append("P15/P16 must expose credits and an in-world postgame ending-and-collection ledger")
	if session.public_life.schedule(&"postgame_tournament", session.day, session.properties, session.community, session.brands.hall_stage) != OK:
		failures.append("P16 must reset only repeatable postgame events and expose advanced tables")
	elif session.public_life.attend(&"postgame_tournament", session.day, true).has("error"):
		failures.append("P16 postgame tournament must accept repeat wins without undoing the finale")
	session.angler.record_catch(&"tarpon", 900, session.inventory)
	session.desert.record_supernatural(&"red_lantern_ledger")
	var summary: Dictionary = session.postgame.collection_summary(session)
	if int(summary.get("total_found", 0)) < 2 or not session.story.can_enter_kings_reach() or session.farm == null or session.animals == null or session.community.completed.size() != 0 and session.community.completed.size() != 10:
		failures.append("P16 must preserve King's Reach, farm/animals/fishing records, and unfinished-or-complete community state")
	var audio_file := FileAccess.open("res://data/audio/vertical_slice_audio.json", FileAccess.READ)
	var audio_data: Variant = JSON.parse_string(audio_file.get_as_text()) if audio_file != null else {}
	if not audio_data is Dictionary or not (audio_data.get("events", {}) as Dictionary).has("finale_challenge") or not (audio_data.get("events", {}) as Dictionary).has("postgame_open"):
		failures.append("P15/P16 must register non-critical finale and postgame audio feedback alongside text feedback")
	var round_trip: Dictionary = session.snapshot()
	var restored = GameSessionScript.new()
	var postgame_restore: Error = restored.restore(round_trip)
	if postgame_restore != OK or not restored.postgame.is_active() or restored.postgame.ending_provenance != &"open_hall" or not restored.angler.records.has(&"tarpon"):
		failures.append("P16 canonical postgame and collections must round-trip through a long-running save (restore %s; postgame %s; ending %s)" % [postgame_restore, restored.postgame.is_active(), restored.postgame.ending_provenance])
	var pre_p15: Dictionary = session.snapshot()
	pre_p15["schema_version"] = 19
	pre_p15.erase("finale"); pre_p15.erase("postgame")
	var migrated = GameSessionScript.new()
	var p15_migration: Error = migrated.restore(pre_p15)
	if p15_migration != OK or migrated.finale.phase != &"unstarted" or migrated.postgame.is_active():
		failures.append("pre-P15 saves must migrate to safe empty finale and postgame records (restore %s; phase %s)" % [p15_migration, migrated.finale.phase])
	var pre_p16: Dictionary = session.snapshot()
	pre_p16["schema_version"] = 20
	pre_p16.erase("postgame")
	var migrated_p16 = GameSessionScript.new()
	var p16_migration: Error = migrated_p16.restore(pre_p16)
	if p16_migration != OK or not migrated_p16.finale.credits_seen or migrated_p16.postgame.is_active():
		failures.append("pre-P16 saves must preserve finale state while gaining an inactive postgame record (restore %s; credits %s)" % [p16_migration, migrated_p16.finale.credits_seen])
	session.free(); restored.free(); migrated.free(); migrated_p16.free()


func _finish_finale(session, response: StringName, failures: Array[String]) -> void:
	if session.finale.begin_championship(session.story, session.public_life) != OK or session.finale.confirm_pre_finale_checkpoint() != OK or session.finale.record_championship_result(true, session.public_life, session.day) != OK or session.finale.resolve_standoff(response, session.story) != OK or session.finale.acknowledge_credits() != OK:
		failures.append("P15 setup must be able to complete the final match, earned standoff, and credits")


func _finale_ready_session(choice: StringName, failures: Array[String]):
	var session = GameSessionScript.new()
	session.start_new_game(1516)
	for arc_id_value in session.community.definitions:
		var arc_id := StringName(arc_id_value)
		for _step in 3:
			if session.community.advance(arc_id, session.community.expected_action(arc_id), session.relationships, session.helpers).has("error"):
				failures.append("P15/P16 setup must complete required community support")
				return null
	for item_id in [&"artisan_cheese", &"crop_wheat", &"fish_tarpon", &"flour"]:
		session.inventory.add_item(item_id)
	for resolution in [{"id": &"saints_landing_depot", "method": &"quest"}, {"id": &"ironhook_customs_warehouse", "method": &"order"}, {"id": &"red_testament_expedition", "method": &"clue"}, {"id": &"bridlewood_water_right", "method": &"quest"}, {"id": &"gulls_rest_mooring", "method": &"quest"}, {"id": &"saints_market_charter", "method": &"quest"}]:
		if session.properties.resolve(resolution["id"], resolution["method"], session.inventory) != OK:
			failures.append("P15/P16 setup must preserve each authored property resolution method")
	session.public_life.sync_property_contributions(session.properties)
	session.brands.hall_stage = 5
	session.public_life.event_states[&"hall_reopening"] = {"phase": "completed", "scheduled_day": 0, "completions": 1}
	session.public_life.event_states[&"final_championship"] = {"phase": "scheduled", "scheduled_day": session.day, "completions": 0}
	for clue_id in [&"inheritance_deed", &"silas_first_lantern_note", &"silas_bridlewood_ledger", &"silas_government_record", &"silas_cargo_ledger", &"silas_gulls_rest_letter", &"texas_king_counter_deed"]:
		session.evidence.discover(clue_id)
	session.story.validate_clue_chain(session.evidence); session.story.discover_bargain(session.evidence); session.story.choose_consequence(choice)
	for rule_id in [&"binding_stake", &"category_declaration", &"bloodline_claim"]:
		session.story.explain_rule(rule_id, session.evidence)
	session.story.prove_silas_alive(session.evidence)
	for site_id in [&"outer_gate", &"sealed_study", &"watchtower"]:
		session.story.explore_kings_reach(site_id)
	if session.story.accept_final_warning(session.public_life, session.community) != OK:
		failures.append("P15/P16 setup must satisfy the P14 final-warning gate")
		return null
	return session
