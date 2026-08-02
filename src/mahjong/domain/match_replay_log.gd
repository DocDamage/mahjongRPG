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
	var snapshot := {"seed": seed, "actions": actions.duplicate(true)}
	snapshot["hash"] = replay_hash(snapshot)
	return snapshot


static func replay_hash(snapshot: Dictionary) -> String:
	var canonical := JSON.stringify({"seed": int(snapshot.get("seed", 0)), "actions": snapshot.get("actions", [])})
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(canonical.to_utf8_buffer())
	return hasher.finish().hex_encode()
