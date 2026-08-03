extends RefCounted

const QuestEvent = preload("res://src/quests/quest_event.gd")
const QUEST_ID := &"first_lantern"
const INTRO_OBJECTIVE := &"meet_mabel"
const DELIVERY_OBJECTIVE := &"deliver_selected_provisions"
const LANTERN_OBJECTIVE := &"complete_lantern_interaction"

var quests
var inventory
var helpers
var evidence
var events


func configure(quest_service, inventory_service, helper_service, evidence_service, event_adapter) -> Error:
	if quest_service == null or inventory_service == null or helper_service == null or evidence_service == null or event_adapter == null:
		return ERR_INVALID_PARAMETER
	quests = quest_service
	inventory = inventory_service
	helpers = helper_service
	evidence = evidence_service
	events = event_adapter
	return OK


func introduce() -> int:
	if quests.completed.has(QUEST_ID):
		return QuestEvent.SubmitResult.REJECTED_NOT_ACTIVE
	if not quests.is_active(QUEST_ID) and quests.start(QUEST_ID) != OK:
		return QuestEvent.SubmitResult.REJECTED_INVALID
	if not quests.expects_objective(QUEST_ID, INTRO_OBJECTIVE):
		return QuestEvent.SubmitResult.REJECTED_OUT_OF_ORDER
	return events.submit_interaction(&"first_lantern.meet_mabel", &"hall_foreman", &"first_lantern.meet_mabel")


func eligible_fish() -> Array[StringName]:
	var result: Array[StringName] = []
	for item_value in inventory.items:
		var item_id := StringName(item_value)
		if String(item_id).begins_with("fish_") and inventory.item_count(item_id) > 0:
			result.append(item_id)
	result.sort_custom(func(a, b): return String(a) < String(b))
	return result


func can_offer_delivery() -> bool:
	return quests.expects_objective(QUEST_ID, DELIVERY_OBJECTIVE) and inventory.item_count(&"crop_beans") >= 1 and not eligible_fish().is_empty()


func deliver_selected(fish_id: StringName) -> Dictionary:
	if not quests.expects_objective(QUEST_ID, DELIVERY_OBJECTIVE):
		return {"error": ERR_UNAVAILABLE, "quest_result": QuestEvent.SubmitResult.REJECTED_OUT_OF_ORDER}
	if not String(fish_id).begins_with("fish_") or inventory.item_count(fish_id) < 1:
		return {"error": ERR_INVALID_PARAMETER}
	var batch: Array = [{"item_id": &"crop_beans", "quantity": 1}, {"item_id": fish_id, "quantity": 1}]
	if inventory.validate_batch_removal(batch) != OK:
		return {"error": ERR_UNAVAILABLE}
	var receipt: Dictionary = inventory.remove_batch(batch)
	if receipt.has("error"):
		return receipt
	var quest_result: int = events.submit_delivery(&"first_lantern.provisions", &"hall_foreman", receipt)
	var transaction_id := StringName(receipt.get("transaction_id", ""))
	if events.is_progress_result(quest_result):
		inventory.commit_transaction(transaction_id)
		return {"quest_result": quest_result, "receipt": receipt}
	var rollback_result: int = inventory.rollback_transaction(transaction_id)
	return {"error": ERR_INVALID_DATA if rollback_result == OK else rollback_result, "quest_result": quest_result, "rolled_back": rollback_result == OK}


func complete_lantern(autosave_callback: Callable = Callable()) -> Dictionary:
	if not quests.expects_objective(QUEST_ID, LANTERN_OBJECTIVE):
		return {"error": ERR_UNAVAILABLE, "quest_result": QuestEvent.SubmitResult.REJECTED_OUT_OF_ORDER}
	var quest_result: int = events.submit_interaction(&"first_lantern.lantern", &"hall_foreman", &"first_lantern.lantern")
	if quest_result != QuestEvent.SubmitResult.QUEST_COMPLETED:
		return {"error": ERR_INVALID_DATA, "quest_result": quest_result}
	var helper_result: int = helpers.assign(&"mabel")
	var evidence_result: int = evidence.discover(&"silas_first_lantern_note")
	var save_result: int = int(autosave_callback.call()) if autosave_callback.is_valid() else OK
	return {"quest_result": quest_result, "helper_result": helper_result, "evidence_result": evidence_result, "save_result": save_result}
