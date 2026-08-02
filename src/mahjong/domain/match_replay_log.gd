extends RefCounted

var seed: int
var actions: Array[Dictionary] = []


func _init(match_seed: int) -> void:
	seed = match_seed


func append_action(action_type: StringName, payload: Dictionary) -> void:
	actions.append({
		"index": actions.size(),
		"type": str(action_type),
		"payload": payload.duplicate(true),
	})


func snapshot() -> Dictionary:
	return {"seed": seed, "actions": actions.duplicate(true)}
