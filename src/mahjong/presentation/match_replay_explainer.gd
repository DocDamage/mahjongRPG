extends RefCounted


static func explain(replay_snapshot: Dictionary) -> Array[String]:
	var explanations: Array[String] = []
	var actions: Variant = replay_snapshot.get("actions", [])
	if not actions is Array:
		return explanations
	for action_value in actions:
		if action_value is Dictionary:
			explanations.append(_explain(String(action_value.get("type", "")), action_value.get("payload", {})))
	return explanations


static func summary(replay_snapshot: Dictionary) -> String:
	var lines := explain(replay_snapshot)
	return "%d deterministic replay events • %s" % [lines.size(), String(replay_snapshot.get("hash", "")).left(12)]


static func _explain(action_type: String, payload: Variant) -> String:
	var data: Dictionary = payload if payload is Dictionary else {}
	match action_type:
		"draw": return "Player %d drew a tile." % int(data.get("player", -1))
		"discard": return "Player %d discarded %s." % [int(data.get("player", -1)), String(data.get("tile", ""))]
		"brand_claim": return "Player %d made the visible %s claim." % [int(data.get("player", -1)), String(data.get("kind", ""))]
		"orange_activated", "blue_activated", "green_activated", "pink_offered", "pink_exchanged", "dark_activated", "purple_activated": return "A visible %s power resolved." % action_type.replace("_activated", "").replace("_", " ").capitalize()
		"hand_completed": return "Hand %d awarded %d Renown." % [int(data.get("hand", -1)), int(data.get("renown", 0))]
		_: return action_type.replace("_", " ").capitalize() + "."
