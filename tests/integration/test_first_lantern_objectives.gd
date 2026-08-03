extends RefCounted

const GameSessionScript = preload("res://src/core/game_session.gd")
const FirstLanternCoordinator = preload("res://src/quests/first_lantern_coordinator.gd")
const InventoryService = preload("res://src/inventory/inventory_service.gd")
const QuestService = preload("res://src/quests/quest_service.gd")
const QuestEventAdapter = preload("res://src/quests/quest_event_adapter.gd")
const SessionSnapshotMigrator = preload("res://src/save/session_snapshot_migrator.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_intentional_delivery_and_effects(failures)
	_test_unexpected_event_rollback(failures)
	_test_save_boundaries_and_atomic_restore(failures)
	_test_session_adapter_lifecycle(failures)
	return failures


func _test_intentional_delivery_and_effects(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(100)
	var coordinator: RefCounted = _coordinator(session)
	if coordinator.complete_lantern().get("quest_result") != session.quests.REJECTED_OUT_OF_ORDER:
		failures.append("the lantern interaction should reject before its objective is active")
	if coordinator.introduce() != session.quests.STAGE_COMPLETED or session.quests.stage_id(&"first_lantern") != &"gather_provisions":
		failures.append("Mabel's confirmed introduction should advance meet_mabel once")
	if coordinator.introduce() != session.quests.REJECTED_OUT_OF_ORDER or session.quests.stage(&"first_lantern") != 1:
		failures.append("repeating Mabel's introduction after transition should not progress again")
	session.inventory.add_item(&"crop_beans")
	session.inventory.add_item(&"fish_anchovy")
	session.inventory.add_item(&"fish_trout")
	session.inventory.add_item(&"fish_bluegill")
	if session.quests.stage(&"first_lantern") != 1:
		failures.append("owning all provisions must not complete or consume the delivery objective")
	session.inventory.remove_item(&"fish_bluegill")
	if not coordinator.deliver_selected(&"fish_bluegill").has("error") or session.inventory.item_count(&"crop_beans") != 1:
		failures.append("a selected fish used before confirmation should fail revalidation without removing beans")
	var result: Dictionary = coordinator.deliver_selected(&"fish_trout")
	if result.has("error") or session.inventory.item_count(&"crop_beans") != 0 or session.inventory.item_count(&"fish_trout") != 0 or session.inventory.item_count(&"fish_anchovy") != 1:
		failures.append("explicit delivery should remove exactly one bean and the selected eligible fish")
	var before_repeat: Dictionary = session.inventory.snapshot()
	if not coordinator.deliver_selected(&"fish_anchovy").has("error") or session.inventory.snapshot() != before_repeat:
		failures.append("repeating delivery after its stage transition must not remove more inventory")
	var autosaves := [0]
	var completion: Dictionary = coordinator.complete_lantern(func(): autosaves[0] += 1; return OK)
	if completion.has("error") or autosaves[0] != 1 or not session.helpers.is_assigned(&"mabel") or not session.evidence.has(&"silas_first_lantern_note"):
		failures.append("lantern completion should assign Mabel, discover evidence, and autosave exactly once")
	if not coordinator.complete_lantern(func(): autosaves[0] += 1; return OK).has("error") or autosaves[0] != 1:
		failures.append("repeated completion should not replay effects or autosave")
	session.free()


func _test_unexpected_event_rollback(failures: Array[String]) -> void:
	var quests = QuestService.new()
	var definition := {"objective_schema": 1, "id": "first_lantern", "definition_version": 1, "requirements": {"crop_beans": 1}, "stages": [{"id": "gather", "legacy_stage": 0, "completion_mode": "all", "objectives": [{"id": "deliver_selected_provisions", "type": "event_once", "label_key": "test.delivery", "event_kind": "inventory.delivered", "match": {"delivery_id": "different.delivery"}}]}]}
	quests.register_definition(definition)
	quests.start(&"first_lantern")
	var inventory = InventoryService.new()
	var adapter = QuestEventAdapter.new()
	adapter.bind(quests, inventory)
	var session = GameSessionScript.new()
	session.start_new_game(150)
	var coordinator = FirstLanternCoordinator.new()
	coordinator.configure(quests, inventory, session.helpers, session.evidence, adapter)
	inventory.add_item(&"crop_beans")
	inventory.add_item(&"fish_anchovy")
	var result: Dictionary = coordinator.deliver_selected(&"fish_anchovy")
	if not result.get("rolled_back", false) or inventory.item_count(&"crop_beans") != 1 or inventory.item_count(&"fish_anchovy") != 1:
		failures.append("unexpected post-removal quest rejection should roll back the exact inventory batch")
	adapter.unbind()
	session.free()


func _test_save_boundaries_and_atomic_restore(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(200)
	var coordinator: RefCounted = _coordinator(session)
	coordinator.introduce()
	var gather_snapshot := session.snapshot()
	if session.restore(gather_snapshot) != OK or session.restore(session.snapshot()) != OK or session.quests.stage_id(&"first_lantern") != &"gather_provisions":
		failures.append("two consecutive save/restore cycles should preserve the next intentional action")
	coordinator = _coordinator(session)
	session.inventory.add_item(&"crop_beans")
	session.inventory.add_item(&"fish_anchovy")
	coordinator.deliver_selected(&"fish_anchovy")
	var lantern_snapshot := session.snapshot()
	if session.restore(lantern_snapshot) != OK or session.quests.stage_id(&"first_lantern") != &"light_lantern":
		failures.append("the lantern objective boundary should round-trip with the same next action")
	coordinator = _coordinator(session)
	var restore_autosaves := [0]
	coordinator.complete_lantern(func(): restore_autosaves[0] += 1; return OK)
	var completed_snapshot := session.snapshot()
	if session.restore(completed_snapshot) != OK or session.restore(session.snapshot()) != OK or restore_autosaves[0] != 1 or not session.quests.completed.has(&"first_lantern"):
		failures.append("completed quest restore should not replay effects, feedback triggers, or autosave")
	var prior := session.snapshot()
	var corrupt := prior.duplicate(true)
	corrupt["inventory"]["money_cents"] = 999
	corrupt["quests"]["progress"]["first_lantern"] = 99
	if session.restore(corrupt) != ERR_INVALID_DATA or session.snapshot() != prior:
		failures.append("a semantically rejected session restore must not partially mutate earlier services")
	for stage_index in 3:
		var fixture := _fixture("first_lantern_stage_%d.json" % stage_index)
		if SessionSnapshotMigrator.migrate(fixture, 21) != fixture:
			failures.append("schema-21 First Lantern migration should be idempotent at stage %d" % stage_index)
		var candidate := gather_snapshot.duplicate(true)
		candidate["quests"] = fixture["quests"]
		if session.restore(candidate) != OK or session.quests.stage(&"first_lantern") != stage_index:
			failures.append("schema-21 stage %d should restore to the equivalent objective boundary" % stage_index)
	session.free()


func _test_session_adapter_lifecycle(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(300)
	var old_inventory = session.inventory
	var old_quests = session.quests
	session.start_new_game(301)
	if old_inventory.item_changed.get_connections().size() != 0 or old_inventory.batch_removed.get_connections().size() != 0 or not session.quest_events.is_bound_to(session.quests, session.inventory) or session.quests == old_quests:
		failures.append("new-game service replacement should disconnect old adapter sources and bind replacements")
	var snapshot := session.snapshot()
	if session.restore(snapshot) != OK or not session.quest_events.is_bound_to(session.quests, session.inventory):
		failures.append("restore should reuse the session adapter and bind it exactly once to staged services")
	var count: int = session.inventory.item_changed.get_connections().size()
	if session.restore(session.snapshot()) != OK or session.inventory.item_changed.get_connections().size() != count:
		failures.append("a second restore should not duplicate adapter signal bindings")
	session.free()


func _coordinator(session) -> RefCounted:
	var coordinator = FirstLanternCoordinator.new()
	coordinator.configure(session.quests, session.inventory, session.helpers, session.evidence, session.quest_events)
	return coordinator


func _fixture(filename: String) -> Dictionary:
	var file := FileAccess.open("res://tests/fixtures/schema21/%s" % filename, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	return parsed if parsed is Dictionary else {}
