extends RefCounted

const EndingEvaluator = preload("res://src/finale/ending_evaluator.gd")

signal finale_updated()

var definition: Dictionary = {}
var phase: StringName = &"unstarted"
var pre_finale_checkpoint_required := false
var pre_finale_checkpoint_captured := false
var championship_losses := 0
var opponent_defeated := false
var standoff_failures := 0
var ending_id: StringName = &""
var standoff_response: StringName = &""
var credits_seen := false


func register_definition(data: Dictionary) -> Error:
	var opponent_value: Variant = data.get("opponent", {})
	var endings_value: Variant = data.get("endings", [])
	if not definition.is_empty() or StringName(data.get("id", "")) != &"texas_king" or not opponent_value is Dictionary or not endings_value is Array or endings_value.size() != 4:
		return ERR_INVALID_DATA
	definition = data.duplicate(true)
	return OK


func begin_championship(story, public_life) -> Error:
	if phase != &"unstarted" or story == null or public_life == null or not story.final_warning_accepted or not public_life.is_scheduled(&"final_championship"):
		return ERR_UNAVAILABLE
	phase = &"championship"
	pre_finale_checkpoint_required = true
	finale_updated.emit()
	return OK


func confirm_pre_finale_checkpoint() -> Error:
	if phase != &"championship" or not pre_finale_checkpoint_required:
		return ERR_UNAVAILABLE
	pre_finale_checkpoint_captured = true
	finale_updated.emit()
	return OK


func can_start_championship_table() -> bool:
	return phase == &"championship" and pre_finale_checkpoint_captured


func record_championship_result(won: bool, public_life, day: int) -> Error:
	if phase != &"championship" or not pre_finale_checkpoint_captured or public_life == null:
		return ERR_UNAVAILABLE
	if not won:
		championship_losses += 1
		finale_updated.emit()
		return OK
	var result: Dictionary = public_life.attend(&"final_championship", day, true)
	if result.has("error"):
		return ERR_UNAVAILABLE
	opponent_defeated = true
	phase = &"standoff"
	finale_updated.emit()
	return OK


func can_retry_championship() -> bool:
	return phase == &"championship" and championship_losses > 0


func resolve_standoff(response: StringName, story) -> Error:
	if phase != &"standoff" or story == null:
		return ERR_UNAVAILABLE
	if response == &"yield_to_claim":
		phase = &"standoff_failed"
		standoff_failures += 1
		finale_updated.emit()
		return ERR_CANT_ACQUIRE_RESOURCE
	if response not in [&"speak_truth", &"end_reign"]:
		return ERR_INVALID_PARAMETER
	var consequence := _consequence(story)
	var evaluated := EndingEvaluator.evaluate(consequence, response)
	if evaluated.is_empty():
		return ERR_INVALID_DATA
	standoff_response = response
	ending_id = StringName(evaluated["id"])
	phase = &"ending"
	finale_updated.emit()
	return OK


func can_retry_standoff() -> bool:
	return phase == &"standoff_failed"


func retry_standoff() -> Error:
	if not can_retry_standoff():
		return ERR_UNAVAILABLE
	phase = &"standoff"
	finale_updated.emit()
	return OK


func ending_summary() -> Dictionary:
	var evaluated := EndingEvaluator.evaluate(_saved_consequence(), standoff_response)
	return {
		"ending_id": ending_id,
		"title": evaluated.get("title", "Ending pending"),
		"category": evaluated.get("category", "No ending category has been earned yet."),
		"consequence": _saved_consequence(),
		"standoff_response": standoff_response,
		"father_reveal": "Texas King admits he is your father; Silas preserved the truthful ledger that makes the counter possible.",
		"silas_return": "Silas returns to the reopened Hall, alive to witness its first fair table.",
	}


func acknowledge_credits() -> Error:
	if phase != &"ending" or ending_id.is_empty():
		return ERR_UNAVAILABLE
	credits_seen = true
	phase = &"credits"
	finale_updated.emit()
	return OK


func opponent() -> Dictionary:
	var value: Variant = definition.get("opponent", {})
	return value.duplicate(true) if value is Dictionary else {}


func snapshot() -> Dictionary:
	return {"phase": str(phase), "pre_finale_checkpoint_required": pre_finale_checkpoint_required, "pre_finale_checkpoint_captured": pre_finale_checkpoint_captured, "championship_losses": championship_losses, "opponent_defeated": opponent_defeated, "standoff_failures": standoff_failures, "ending_id": str(ending_id), "standoff_response": str(standoff_response), "credits_seen": credits_seen}


func restore(data: Dictionary) -> Error:
	var next_phase := StringName(data.get("phase", "unstarted"))
	var next_ending := StringName(data.get("ending_id", ""))
	var next_response := StringName(data.get("standoff_response", ""))
	if next_phase not in [&"unstarted", &"championship", &"standoff", &"standoff_failed", &"ending", &"credits"] or int(data.get("championship_losses", 0)) < 0 or int(data.get("standoff_failures", 0)) < 0:
		return ERR_INVALID_DATA
	if next_phase in [&"ending", &"credits"] and EndingEvaluator.evaluate(_data_consequence(data), next_response).is_empty():
		return ERR_INVALID_DATA
	if next_phase in [&"standoff", &"standoff_failed", &"ending", &"credits"] and not bool(data.get("opponent_defeated", false)):
		return ERR_INVALID_DATA
	if bool(data.get("credits_seen", false)) != (next_phase == &"credits"):
		return ERR_INVALID_DATA
	phase = next_phase
	pre_finale_checkpoint_required = bool(data.get("pre_finale_checkpoint_required", false))
	pre_finale_checkpoint_captured = bool(data.get("pre_finale_checkpoint_captured", false))
	championship_losses = int(data.get("championship_losses", 0))
	opponent_defeated = bool(data.get("opponent_defeated", false))
	standoff_failures = int(data.get("standoff_failures", 0))
	ending_id = next_ending
	standoff_response = next_response
	credits_seen = bool(data.get("credits_seen", false))
	return OK


func _consequence(story) -> StringName:
	for choice_value in story.choices:
		return StringName(choice_value)
	return &""


func _saved_consequence() -> StringName:
	return _consequence_from_ending()


func _consequence_from_ending() -> StringName:
	if ending_id in [&"open_hall", &"mercy_at_sunrise"]:
		return &"protect_town"
	if ending_id in [&"keeper_of_truth", &"keeper_mercy"]:
		return &"preserve_records"
	return &""


func _data_consequence(data: Dictionary) -> StringName:
	var response := StringName(data.get("standoff_response", ""))
	var id := StringName(data.get("ending_id", ""))
	for key_value in EndingEvaluator.ENDINGS:
		var entry: Dictionary = EndingEvaluator.ENDINGS[key_value]
		if StringName(entry.get("id", "")) == id and StringName(String(key_value).get_slice(":", 1)) == response:
			return StringName(String(key_value).get_slice(":", 0))
	return &""
