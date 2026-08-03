extends RefCounted

signal event_scheduled(event_id: StringName, day: int)
signal event_attended(event_id: StringName, completions: int)

const RANKS := [
	{"id": &"tenderfoot", "minimum": 0},
	{"id": &"tablehand", "minimum": 10},
	{"id": &"marshal", "minimum": 25},
	{"id": &"legend", "minimum": 40},
]

var definitions: Dictionary = {}
var rank_points := 0
var rank_id: StringName = &"tenderfoot"
var event_states: Dictionary = {}
var contributions: Dictionary = {}
var hall_milestones: Dictionary = {}


func register_definition(data: Dictionary) -> Error:
	var event_id := StringName(data.get("id", ""))
	var required_properties: Variant = data.get("required_properties", [])
	if event_id.is_empty() or definitions.has(event_id) or not required_properties is Array or int(data.get("rank_points", 0)) < 0:
		return ERR_INVALID_DATA
	definitions[event_id] = data.duplicate(true)
	return OK


func sync_property_contributions(properties) -> void:
	if properties == null:
		return
	for property_id_value in properties.outcomes:
		var property_id := StringName(property_id_value)
		var property_data: Dictionary = properties.definitions.get(property_id, {})
		var value := maxi(0, int(property_data.get("public_contribution", 0)))
		if value > 0:
			contributions[property_id] = value


func contribution_total() -> int:
	var total := 0
	for value in contributions.values():
		total += maxi(0, int(value))
	return total


func can_schedule(event_id: StringName, properties, community, hall_stage: int) -> bool:
	if not definitions.has(event_id):
		return false
	var state: Dictionary = event_states.get(event_id, {})
	if String(state.get("phase", "available")) == "scheduled":
		return false
	if String(state.get("phase", "available")) == "completed" and not bool(definitions[event_id].get("repeatable", false)):
		return false
	return _requirements_met(definitions[event_id], properties, community, hall_stage)


func schedule(event_id: StringName, day: int, properties, community, hall_stage: int) -> Error:
	if day < 1 or not can_schedule(event_id, properties, community, hall_stage):
		return ERR_UNAVAILABLE
	var state: Dictionary = event_states.get(event_id, {})
	state["phase"] = "scheduled"
	state["scheduled_day"] = day
	state["completions"] = int(state.get("completions", 0))
	event_states[event_id] = state
	event_scheduled.emit(event_id, day)
	return OK


func reschedule(event_id: StringName, day: int) -> Error:
	var state: Dictionary = event_states.get(event_id, {})
	if day < 1 or String(state.get("phase", "")) != "scheduled":
		return ERR_UNAVAILABLE
	state["scheduled_day"] = day
	event_states[event_id] = state
	event_scheduled.emit(event_id, day)
	return OK


func attend(event_id: StringName, day: int, match_won := false) -> Dictionary:
	var state: Dictionary = event_states.get(event_id, {})
	if not definitions.has(event_id) or String(state.get("phase", "")) != "scheduled" or day < int(state.get("scheduled_day", 0)):
		return {"error": ERR_UNAVAILABLE}
	var definition: Dictionary = definitions[event_id]
	if bool(definition.get("requires_match", false)) and not match_won:
		return {"error": ERR_UNAVAILABLE}
	var completions := int(state.get("completions", 0)) + 1
	state["completions"] = completions
	state["phase"] = "available" if bool(definition.get("repeatable", false)) else "completed"
	state["scheduled_day"] = 0
	event_states[event_id] = state
	rank_points += maxi(0, int(definition.get("rank_points", 0)))
	_refresh_rank()
	var hall_stage := int(definition.get("hall_stage", 0))
	if hall_stage > 0:
		hall_milestones[event_id] = true
	event_attended.emit(event_id, completions)
	return {"event_id": event_id, "completions": completions, "rank_id": rank_id, "hall_stage": hall_stage}


func has_completed(event_id: StringName) -> bool:
	return int(event_states.get(event_id, {}).get("completions", 0)) > 0


func is_scheduled(event_id: StringName) -> bool:
	return String(event_states.get(event_id, {}).get("phase", "")) == "scheduled"


func scheduled_day(event_id: StringName) -> int:
	return int(event_states.get(event_id, {}).get("scheduled_day", 0))


func snapshot() -> Dictionary:
	return {"rank_points": rank_points, "rank_id": str(rank_id), "event_states": event_states.duplicate(true), "contributions": contributions.duplicate(true), "hall_milestones": hall_milestones.duplicate(true)}


func restore(data: Dictionary) -> Error:
	var states_value: Variant = data.get("event_states", {})
	var contributions_value: Variant = data.get("contributions", {})
	var milestones_value: Variant = data.get("hall_milestones", {})
	if not states_value is Dictionary or not contributions_value is Dictionary or not milestones_value is Dictionary:
		return ERR_INVALID_DATA
	for event_id_value in states_value:
		var event_id := StringName(event_id_value)
		var state: Variant = states_value[event_id_value]
		if not definitions.has(event_id) or not state is Dictionary or not String(state.get("phase", "available")) in ["available", "scheduled", "completed"]:
			return ERR_INVALID_DATA
	for event_id_value in milestones_value:
		if not definitions.has(StringName(event_id_value)):
			return ERR_INVALID_DATA
	rank_points = maxi(0, int(data.get("rank_points", 0)))
	event_states = states_value.duplicate(true)
	contributions = contributions_value.duplicate(true)
	hall_milestones = milestones_value.duplicate(true)
	_refresh_rank()
	return OK


func _requirements_met(definition: Dictionary, properties, community, hall_stage: int) -> bool:
	if hall_stage < int(definition.get("required_hall_stage", 1)) or contribution_total() < int(definition.get("minimum_contributions", 0)):
		return false
	for property_id_value in definition.get("required_properties", []):
		if properties == null or not properties.is_resolved(StringName(property_id_value)):
			return false
	if bool(definition.get("requires_community_allies", false)) and (community == null or not community.finale_support.has(&"community_allies_ready")):
		return false
	for prior_event_value in definition.get("required_events", []):
		if not has_completed(StringName(prior_event_value)):
			return false
	return true


func _refresh_rank() -> void:
	rank_id = &"tenderfoot"
	for rank_value in RANKS:
		if rank_points >= int(rank_value["minimum"]):
			rank_id = rank_value["id"]
