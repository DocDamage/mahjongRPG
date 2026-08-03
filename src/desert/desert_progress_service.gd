extends RefCounted

var route_states: Dictionary = {}
var supernatural_records: Dictionary = {}
var recovered_clues: Dictionary = {}
var region_secrets: Dictionary = {}


func survive_route(route_id: StringName, weather_id: StringName) -> Error:
	if route_id.is_empty() or weather_id not in [&"dust_wind", &"supernatural_fog"]:
		return ERR_UNAVAILABLE
	route_states[route_id] = true
	return OK


func route_survived(route_id: StringName) -> bool:
	return route_states.has(route_id)


func record_supernatural(record_id: StringName) -> Error:
	if record_id.is_empty() or supernatural_records.has(record_id):
		return ERR_ALREADY_IN_USE
	supernatural_records[record_id] = true
	return OK


func recover_clue(clue_id: StringName) -> Error:
	if clue_id.is_empty() or recovered_clues.has(clue_id):
		return ERR_ALREADY_IN_USE
	recovered_clues[clue_id] = true
	return OK


func discover_secret(secret_id: StringName) -> Error:
	if secret_id.is_empty() or region_secrets.has(secret_id):
		return ERR_ALREADY_IN_USE
	region_secrets[secret_id] = true
	return OK


func snapshot() -> Dictionary:
	return {"route_states": route_states.duplicate(true), "supernatural_records": supernatural_records.duplicate(true), "recovered_clues": recovered_clues.duplicate(true), "region_secrets": region_secrets.duplicate(true)}


func restore(data: Dictionary) -> Error:
	for key in ["route_states", "supernatural_records", "recovered_clues", "region_secrets"]:
		if not data.get(key, {}) is Dictionary:
			return ERR_INVALID_DATA
	route_states = data["route_states"].duplicate(true)
	supernatural_records = data["supernatural_records"].duplicate(true)
	recovered_clues = data["recovered_clues"].duplicate(true)
	region_secrets = data["region_secrets"].duplicate(true)
	return OK
