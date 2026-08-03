extends RefCounted

const GameSessionScript = preload("res://src/core/game_session.gd")
const DialogueCatalog = preload("res://src/dialogue/dialogue_catalog.gd")
const CommunityDialogueCoordinator = preload("res://src/dialogue/community_dialogue_coordinator.gd")
const CommunityDialogueFlow = preload("res://src/dialogue/community_dialogue_flow.gd")
const OpponentSchedule = preload("res://src/npcs/opponent_schedule.gd")
const CommunityArcPanel = preload("res://src/world/community_arc_panel.gd")
const CommunityLandmark = preload("res://src/world/community_landmark.gd")

const ARC_ID := &"mayor_bell"
const FIXTURE_PATHS := [
	"res://tests/fixtures/community/mayor_bell_inactive.json",
	"res://tests/fixtures/community/mayor_bell_stage_0.json",
	"res://tests/fixtures/community/mayor_bell_stage_1.json",
	"res://tests/fixtures/community/mayor_bell_stage_2.json",
	"res://tests/fixtures/community/mayor_bell_completed.json",
]


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_three_authored_commits_and_exactly_once_effects(failures)
	_test_cancel_reopen_and_event_publication_boundary(failures)
	_test_legacy_save_points_and_schedule(failures)
	_test_session_replacement_gate(failures)
	_test_fresh_play_through_generic_flow(failures)
	_test_migrated_callers_do_not_fall_through_to_legacy_advance(failures)
	return failures


func _test_three_authored_commits_and_exactly_once_effects(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(3034)
	var expected_actions := [&"meet", &"favor", &"resolve"]
	for index in expected_actions.size():
		var action: StringName = expected_actions[index]
		var sequence_id: StringName = session.community.expected_dialogue_sequence(ARC_ID)
		var sequence: Dictionary = DialogueCatalog.sequence(sequence_id)
		if sequence_id != StringName("mayor_bell.%s" % action) or StringName(sequence.get("start_node", "")) != &"opening":
			failures.append("Mayor Bell action %s must map to an authored sequence starting at its first node" % action)
			break
		var coordinator := CommunityDialogueCoordinator.new()
		if coordinator.begin(ARC_ID, sequence, session.community, session.relationships, session.helpers) != OK:
			failures.append("Mayor Bell action %s should begin its validated coordinator" % action)
			break
		var result: Dictionary = coordinator.commit_terminal()
		if result.has("error") or session.relationships.value(ARC_ID) != index + 1:
			failures.append("Mayor Bell action %s must commit its relationship delta exactly once" % action)
		if not coordinator.commit_terminal().has("error") or session.relationships.value(ARC_ID) != index + 1:
			failures.append("repeated terminal commit for %s must not advance or mutate relationships" % action)
	if not session.community.is_completed(ARC_ID) or not session.helpers.is_assigned(ARC_ID):
		failures.append("Mayor Bell resolution must complete the arc and assign its helper exactly once")
	if session.community.expected_dialogue_sequence(ARC_ID) != &"":
		failures.append("a completed Mayor Bell sequence must not reopen")
	session.free()


func _test_cancel_reopen_and_event_publication_boundary(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(3035)
	var sequence: Dictionary = DialogueCatalog.sequence(session.community.expected_dialogue_sequence(ARC_ID))
	var coordinator := CommunityDialogueCoordinator.new()
	coordinator.begin(ARC_ID, sequence, session.community, session.relationships, session.helpers)
	coordinator.cancel()
	if session.community.expected_action(ARC_ID) != &"meet" or session.relationships.value(ARC_ID) != 0:
		failures.append("cancel before terminal acknowledgment must leave all domain state unchanged")
	var publications: Array = []
	coordinator = CommunityDialogueCoordinator.new()
	coordinator.begin(ARC_ID, sequence, session.community, session.relationships, session.helpers, Callable(), func(event): publications.append(event))
	coordinator.commit_terminal()
	if not publications.is_empty():
		failures.append("dialogue.seen must not publish when no objective consumer exists")
	sequence = DialogueCatalog.sequence(session.community.expected_dialogue_sequence(ARC_ID))
	coordinator = CommunityDialogueCoordinator.new()
	coordinator.begin(ARC_ID, sequence, session.community, session.relationships, session.helpers, func(_event): return true, func(event): publications.append(event))
	coordinator.commit_terminal()
	if publications.size() != 1 or StringName(publications[0].get("kind", "")) != &"dialogue.seen":
		failures.append("dialogue.seen must publish once and only after a successful domain commit when consumed")
	session.free()


func _test_legacy_save_points_and_schedule(failures: Array[String]) -> void:
	for fixture_path in FIXTURE_PATHS:
		var fixture := _fixture(fixture_path)
		if fixture.is_empty():
			failures.append("missing Mayor Bell fixture: %s" % fixture_path)
			continue
		var source = GameSessionScript.new()
		source.start_new_game(3036)
		var snapshot := source.snapshot()
		for key in ["community", "relationships", "helpers"]:
			snapshot[key] = fixture[key]
		var restored = GameSessionScript.new()
		if restored.restore(snapshot) != OK:
			failures.append("legacy Mayor Bell fixture should restore atomically: %s" % fixture_path)
		else:
			var expected_sequence := StringName(fixture.get("expected_sequence_id", ""))
			if restored.community.expected_dialogue_sequence(ARC_ID) != expected_sequence:
				failures.append("fixture %s should restore the expected next sequence" % fixture_path)
			elif not expected_sequence.is_empty() and StringName(DialogueCatalog.sequence(expected_sequence).get("start_node", "")) != &"opening":
				failures.append("restored stages must restart presentation from the first node")
			while not restored.community.is_completed(ARC_ID):
				var sequence := DialogueCatalog.sequence(restored.community.expected_dialogue_sequence(ARC_ID))
				var coordinator := CommunityDialogueCoordinator.new()
				if coordinator.begin(ARC_ID, sequence, restored.community, restored.relationships, restored.helpers) != OK or coordinator.commit_terminal().has("error"):
					failures.append("fixture %s must remain completable through authored dialogue" % fixture_path)
					break
			if not restored.community.is_completed(ARC_ID) or not restored.helpers.is_assigned(ARC_ID) or restored.relationships.value(ARC_ID) != 3:
				failures.append("fixture %s must reach the same final domain outcome" % fixture_path)
			_assert_resolved_schedule(restored, "restored fixture %s" % fixture_path, failures)
		source.free(); restored.free()


func _test_session_replacement_gate(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	if session.start_new_game(3037) != OK:
		failures.append("session setup should remain available")
	var snapshot := session.snapshot()
	session.session_gate.request(&"dialogue_sequence")
	if session.start_new_game(3038) != ERR_BUSY or session.restore(snapshot) != ERR_BUSY or session.seed != 3037:
		failures.append("new game and direct restore must reject session replacement while dialogue is open")
	session.session_gate.release(&"dialogue_sequence")
	if session.restore(snapshot) != OK:
		failures.append("session replacement must be allowed after dialogue cancel or completion")
	session.free()


func _test_fresh_play_through_generic_flow(failures: Array[String]) -> void:
	var root: Window = Engine.get_main_loop().root
	var session = root.get_node("GameSession")
	var original_snapshot: Dictionary = session.snapshot()
	session.start_new_game(3038)
	var save_service = root.get_node("SaveService")
	var cancel_flow := CommunityDialogueFlow.new()
	root.add_child(cancel_flow)
	if cancel_flow.start(ARC_ID) != OK:
		failures.append("fresh Mayor Bell dialogue should open through the generic presentation flow")
	else:
		cancel_flow.get_child(0).cancel()
		if session.community.expected_action(ARC_ID) != &"meet" or not save_service.can_save() or not session.session_gate.can_replace_session():
			failures.append("generic flow cancel must preserve stage and release all restrictions")
	root.remove_child(cancel_flow)
	cancel_flow.free()
	for expected_value in [1, 2, 3]:
		var flow := CommunityDialogueFlow.new()
		root.add_child(flow)
		if flow.start(ARC_ID) != OK:
			failures.append("generic flow should open every remaining Mayor Bell action")
			root.remove_child(flow); flow.free()
			break
		var runner = flow.get_child(0)
		runner.reveal_current_line(); runner.confirm()
		runner.reveal_current_line(); runner.confirm(); runner.confirm()
		if session.relationships.value(ARC_ID) != expected_value or not save_service.can_save():
			failures.append("generic flow terminal acknowledgment must commit once and release save state (expected %d, relationship %d, action %s, can_save %s)" % [expected_value, session.relationships.value(ARC_ID), session.community.expected_action(ARC_ID), save_service.can_save()])
		root.remove_child(flow)
		flow.free()
	if not session.community.is_completed(ARC_ID) or not session.helpers.is_assigned(ARC_ID):
		failures.append("fresh generic-flow play must reach Mayor Bell's unchanged final outcome")
	_assert_resolved_schedule(session, "fresh generic-flow completion", failures)
	var completed_flow := CommunityDialogueFlow.new()
	root.add_child(completed_flow)
	if completed_flow.start(ARC_ID) != ERR_DOES_NOT_EXIST:
		failures.append("a completed Mayor Bell sequence must not reopen through the generic flow")
	root.remove_child(completed_flow)
	completed_flow.free()
	session.restore(original_snapshot)


func _assert_resolved_schedule(session, context: String, failures: Array[String]) -> void:
	if not session.community.is_completed(ARC_ID):
		failures.append("%s must be completed before resolved schedule presentation" % context)
		return
	var clear: Dictionary = OpponentSchedule.state(ARC_ID, &"clear", 10)
	var rain: Dictionary = OpponentSchedule.state(ARC_ID, &"rain", 10)
	if String(clear.get("resolved_activity", "")) != "welcoming claimants to a fair hearing" or String(rain.get("resolved_activity", "")) != "sharing the corrected claim file under the awning":
		failures.append("%s must preserve both authored post-resolution schedule variants" % context)


func _test_migrated_callers_do_not_fall_through_to_legacy_advance(failures: Array[String]) -> void:
	var root: Window = Engine.get_main_loop().root
	var session = root.get_node("GameSession")
	var original_snapshot: Dictionary = session.snapshot()
	for caller_kind in ["panel", "landmark"]:
		session.start_new_game(3040)
		var caller
		if caller_kind == "panel":
			caller = CommunityArcPanel.new()
			root.add_child(caller)
			caller._advance(ARC_ID)
		else:
			caller = CommunityLandmark.new()
			caller.arc_id = ARC_ID
			root.add_child(caller)
			caller._on_interacted(null)
		if session.community.expected_action(ARC_ID) != &"meet" or session.relationships.value(ARC_ID) != 0:
			failures.append("migrated %s caller must wait for terminal dialogue acknowledgment before advancing" % caller_kind)
		if caller._dialogue_flow == null or caller._dialogue_flow.get_child_count() != 1:
			failures.append("migrated %s caller must keep the generic dialogue flow open" % caller_kind)
		else:
			caller._dialogue_flow.get_child(0).cancel()
		root.remove_child(caller)
		caller.free()
	session.restore(original_snapshot)


func _fixture(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	return parsed if parsed is Dictionary else {}
