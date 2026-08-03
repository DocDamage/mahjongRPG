extends RefCounted

const GameSessionScript = preload("res://src/core/game_session.gd")
const DialogueCatalog = preload("res://src/dialogue/dialogue_catalog.gd")
const CommunityPortrait = preload("res://src/dialogue/community_portrait.gd")
const OpponentSchedule = preload("res://src/npcs/opponent_schedule.gd")

const FIRST_HALF: Array[StringName] = [&"mayor_bell", &"river_rose", &"dynamite_bill", &"ada_rook", &"gideon_shaw"]
const SECOND_HALF: Array[StringName] = [&"registrar_elise", &"constable_mara", &"mariner_ves", &"captain_coral", &"witness_ash"]
const SECRET_ARCS: Array[StringName] = [&"mayor_bell", &"river_rose", &"ada_rook", &"gideon_shaw", &"registrar_elise", &"constable_mara", &"mariner_ves", &"witness_ash"]


func run() -> Array[String]:

	var failures: Array[String] = []
	_test_phase_eleven_arcs_helpers_and_migration(failures)
	_test_phase_twelve_homes_secrets_finale_and_round_trip(failures)
	return failures


func _test_phase_eleven_arcs_helpers_and_migration(failures: Array[String]) -> void:

	var session = GameSessionScript.new()
	session.start_new_game(1111)
	if session.community.definitions.size() != 10:
		failures.append("P11/P12 must register exactly ten relationship-backed community arcs")
	for arc_id in session.community.definitions:
		var relationship_id: StringName = StringName(session.community.definitions[arc_id].get("relationship_id", ""))
		if relationship_id.is_empty() or not session.relationships.definitions.has(relationship_id):
			failures.append("Every community arc must reference a registered relationship")
		var portrait := CommunityPortrait.new()
		portrait.configure(session.community.definitions[arc_id])
		portrait.free()
		for action_id in [&"meet", &"favor", &"resolve"]:
			if DialogueCatalog.text(StringName("community.%s.%s" % [arc_id, action_id])).is_empty():
				failures.append("Every authored community stage must have a stable localization key")
		var schedule: Dictionary = OpponentSchedule.state(StringName(arc_id), &"clear", 14)
		if String(schedule.get("resolved_activity", "")).is_empty():
			failures.append("Every community opponent must expose a post-resolution schedule activity")
	for arc_id in FIRST_HALF:
		_complete_arc(session, arc_id, failures)
	if session.community.completed.size() != 5 or not session.helpers.has_action(&"water_all") or not session.helpers.has_action(&"feed_animals"):
		failures.append("P11 must complete arcs 1–5 and unlock active farm helpers")
	if session.helpers.passive_total(&"shop_discount_percent") < 10.0 or session.helpers.passive_total(&"fish_reel_bonus") <= 0.0 or session.helpers.passive_total(&"mahjong_opening_charge") < 1.0:
		failures.append("P11 helpers must provide visible economy, fishing, and Mahjong passives")
	var active = GameSessionScript.new()
	active.start_new_game(1112)
	var first_action: StringName = active.community.expected_action(&"mayor_bell")
	active.community.advance(&"mayor_bell", first_action, active.relationships, active.helpers)
	var mixed_snapshot := active.snapshot()
	var restored_mixed = GameSessionScript.new()
	if restored_mixed.restore(mixed_snapshot) != OK or not restored_mixed.community.active.has(&"mayor_bell") or restored_mixed.community.expected_action(&"mayor_bell") != &"favor":
		failures.append("P11 active and mixed arc state must survive a round-trip")
	var pre_phase_eleven := session.snapshot()
	pre_phase_eleven["schema_version"] = 15
	pre_phase_eleven.erase("community")
	var migrated = GameSessionScript.new()
	if migrated.restore(pre_phase_eleven) != OK or not migrated.community.completed.is_empty() or not migrated.community.discovered_secrets.is_empty():
		failures.append("pre-P11 saves must gain safe empty arc, secret, and finale-support state")
	session.free(); active.free(); restored_mixed.free(); migrated.free()


func _test_phase_twelve_homes_secrets_finale_and_round_trip(failures: Array[String]) -> void:

	var session = GameSessionScript.new()
	session.start_new_game(1212)
	for arc_id in FIRST_HALF + SECOND_HALF:
		_complete_arc(session, arc_id, failures)
		var home: String = session.community.home_scene(arc_id)
		if home.is_empty() or not ResourceLoader.exists(home):
			failures.append("P12 must provide a reachable home scene for %s" % arc_id)
	for arc_id in SECRET_ARCS:
		if session.community.discover_secret(arc_id) != OK:
			failures.append("P12 secrets must unlock only after their resident's completed arc")
	if session.community.completed.size() != 10 or session.community.discovered_secrets.size() != 8 or not session.community.finale_support.has(&"community_allies_ready"):
		failures.append("P12 must finish ten arcs, eight secrets, and finale-support state")
	var round_trip := session.snapshot()
	var restored = GameSessionScript.new()
	if restored.restore(round_trip) != OK or restored.community.completed.size() != 10 or restored.community.discovered_secrets.size() != 8 or not restored.community.finale_support.has(&"community_allies_ready"):
		failures.append("P12 complete arcs, secrets, helpers, and finale support must round-trip")
	var pre_phase_twelve := session.snapshot()
	pre_phase_twelve["schema_version"] = 16
	var p12_restored = GameSessionScript.new()
	if p12_restored.restore(pre_phase_twelve) != OK or p12_restored.community.completed.size() != 10:
		failures.append("P11 schema saves must forward-migrate without losing completed community arcs")
	var p11_active = GameSessionScript.new()
	p11_active.start_new_game(1213)
	p11_active.community.advance(&"registrar_elise", &"meet", p11_active.relationships, p11_active.helpers)
	var active_p11_snapshot := p11_active.snapshot()
	active_p11_snapshot["schema_version"] = 16
	var active_p12_restored = GameSessionScript.new()
	if active_p12_restored.restore(active_p11_snapshot) != OK or not active_p12_restored.community.active.has(&"registrar_elise"):
		failures.append("P12 migration must preserve active P11 arc state")
	session.free(); restored.free(); p12_restored.free(); p11_active.free(); active_p12_restored.free()


func _complete_arc(session, arc_id: StringName, failures: Array[String]) -> void:

	for _index in 3:
		var action: StringName = session.community.expected_action(arc_id)
		var result: Dictionary = session.community.advance(arc_id, action, session.relationships, session.helpers)
		if result.has("error"):
			failures.append("Community arc %s must accept its authored stage sequence" % arc_id)
			return
	if not session.community.is_completed(arc_id) or not session.helpers.is_assigned(StringName(session.community.definitions[arc_id]["helper_id"])):
		failures.append("Completing %s must persist its relationship and helper assignment" % arc_id)
