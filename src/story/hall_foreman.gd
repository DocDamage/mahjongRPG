extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

const QUEST_ID := &"first_lantern"
const DialogueCatalog = preload("res://src/dialogue/dialogue_catalog.gd")
const FirstLanternCoordinator = preload("res://src/quests/first_lantern_coordinator.gd")
const ProvisionDeliveryDialog = preload("res://src/ui/provision_delivery_dialog.gd")

var _coordinator = FirstLanternCoordinator.new()
var _dialog
var _bound_quests


func _ready() -> void:
	interacted.connect(_on_interacted)
	GameSession.session_replacing.connect(_on_session_replacing)
	GameSession.session_started.connect(_on_session_ready.unbind(1))
	GameSession.session_restored.connect(_on_session_ready)
	_on_session_ready()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, -14), 12.0, Color("e7c28f"))
	draw_rect(Rect2(-16, -2, 32, 30), Color("7a4b78"))
	draw_rect(Rect2(-18, -30, 36, 8), Color("32231f"))
	draw_circle(Vector2(-6, -14), 2.0, Color("33251c"))
	draw_circle(Vector2(6, -14), 2.0, Color("33251c"))
	if GameSession.quests.completed.has(QUEST_ID):
		draw_circle(Vector2(0, -50), 11.0, Color("f5c45e", 0.25))
		draw_rect(Rect2(-4, -58, 8, 16), Color("f3b648"))
		draw_circle(Vector2(0, -50), 4.0, Color("fff1ae"))


func _on_interacted(_actor: Node2D) -> void:
	if _dialog != null:
		return
	if GameSession.quests.completed.has(QUEST_ID):
		feedback.emit("%s\n%s\n%s" % [DialogueCatalog.text(&"first_lantern.after"), _hall_mastery_text(), _silas_evidence_text()])
		return
	if not GameSession.quests.is_active(QUEST_ID) or GameSession.quests.expects_objective(QUEST_ID, &"meet_mabel"):
		var result: int = _coordinator.introduce()
		if GameSession.quest_events.is_progress_result(result):
			feedback.emit("%s\n%s" % [DialogueCatalog.text(&"first_lantern.intro"), DialogueCatalog.text(&"first_lantern.gather")])
		return
	if GameSession.quests.expects_objective(QUEST_ID, &"deliver_selected_provisions"):
		_offer_delivery()
		return
	if GameSession.quests.expects_objective(QUEST_ID, &"complete_lantern_interaction"):
		_complete_lantern()


func _offer_delivery() -> void:
	var bean_count: int = GameSession.inventory.item_count(&"crop_beans")
	var fish_ids: Array[StringName] = _coordinator.eligible_fish()
	if bean_count < 1 or fish_ids.is_empty():
		feedback.emit(DialogueCatalog.text(&"first_lantern.missing", {"beans": bean_count, "fish": fish_ids.size()}))
		return
	_dialog = ProvisionDeliveryDialog.new()
	add_child(_dialog)
	_dialog.confirmed.connect(_on_delivery_confirmed)
	_dialog.canceled.connect(_on_delivery_canceled)
	_dialog.configure(fish_ids, bean_count)


func _on_delivery_confirmed(fish_id: StringName) -> void:
	_dialog = null
	var result: Dictionary = _coordinator.deliver_selected(fish_id)
	feedback.emit(DialogueCatalog.text(&"first_lantern.delivery") if not result.has("error") else DialogueCatalog.text(&"first_lantern.missing", {"beans": GameSession.inventory.item_count(&"crop_beans"), "fish": _coordinator.eligible_fish().size()}))


func _on_delivery_canceled() -> void:
	_dialog = null
	feedback.emit("Provision delivery canceled; no items were removed.")


func _complete_lantern() -> void:
	var result: Dictionary = _coordinator.complete_lantern(Callable(SaveService, "autosave").bind(&"quest_completion"))
	if result.has("error"):
		return
	var completion_text := DialogueCatalog.text(&"first_lantern.complete")
	feedback.emit("%s\n%s%s" % [completion_text, _silas_evidence_text(), " Autosaved." if int(result.get("save_result", FAILED)) == OK else ""])
	queue_redraw()


func _on_session_replacing() -> void:
	_unbind_quest_signal()


func _on_session_ready() -> void:
	_unbind_quest_signal()
	_bound_quests = GameSession.quests
	_bound_quests.quest_completed.connect(_on_quest_completed)
	_coordinator.configure(GameSession.quests, GameSession.inventory, GameSession.helpers, GameSession.evidence, GameSession.quest_events)
	queue_redraw()


func _unbind_quest_signal() -> void:
	if _bound_quests != null and _bound_quests.quest_completed.is_connected(_on_quest_completed):
		_bound_quests.quest_completed.disconnect(_on_quest_completed)
	_bound_quests = null


func _on_quest_completed(quest_id: StringName) -> void:
	if quest_id == QUEST_ID:
		queue_redraw()


func _silas_evidence_text() -> String:
	return DialogueCatalog.text(&"evidence.silas_first_lantern_note.text") if GameSession.evidence.has(&"silas_first_lantern_note") else ""


func _hall_mastery_text() -> String:
	if GameSession.brands.can_play_frontier():
		return "The cleanup is complete. The rebuilt western table now teaches Frontier Rules; Purple has returned to the Hall."
	var wins: Dictionary = GameSession.brands.match_wins
	return "Hall cleanup ledger — River Rose: %s, Dynamite Bill: %s, Mayor Bell: %s. Win each Trail Rules rematch to claim Green, Pink, and Dark and reopen the Frontier table." % ["done" if int(wins.get(&"river_rose", 0)) > 0 else "pending", "done" if int(wins.get(&"dynamite_bill", 0)) > 0 else "pending", "done" if int(wins.get(&"mayor_bell", 0)) > 0 else "pending"]
