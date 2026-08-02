extends RefCounted

var definitions: Dictionary = {}
var assignments: Dictionary = {}
var last_used_day: Dictionary = {}


func register_definition(data: Dictionary) -> Error:
	var helper_id := StringName(data.get("id", ""))
	var action_id := StringName(data.get("action", ""))
	if helper_id.is_empty() or action_id.is_empty():
		return ERR_INVALID_DATA
	definitions[helper_id] = data.duplicate(true)
	return OK


func assign(helper_id: StringName) -> Error:
	if not definitions.has(helper_id):
		return ERR_DOES_NOT_EXIST
	assignments[helper_id] = true
	return OK


func is_assigned(helper_id: StringName) -> bool:
	return assignments.has(helper_id)


func activate(helper_id: StringName, farm, day: int) -> Dictionary:
	if not is_assigned(helper_id) or not definitions.has(helper_id) or farm == null:
		return {"error": ERR_UNAVAILABLE}
	if int(last_used_day.get(helper_id, 0)) == day:
		return {"error": ERR_BUSY}
	var definition: Dictionary = definitions[helper_id]
	if StringName(definition.get("action", "")) != &"water_all":
		return {"error": ERR_UNAVAILABLE}
	var watered := 0
	for cell in farm.field_cells():
		var crop = farm.crop_at(cell)
		if crop != null and farm.water(cell, day) == OK:
			watered += 1
	last_used_day[helper_id] = day
	return {"watered": watered, "message": String(definition.get("success_text", "Helper action complete."))}


func snapshot() -> Dictionary:
	return {"assignments": assignments.duplicate(true), "last_used_day": last_used_day.duplicate(true)}


func restore(data: Dictionary) -> Error:
	var assignments_value: Variant = data.get("assignments", {})
	var last_used_value: Variant = data.get("last_used_day", {})
	if not assignments_value is Dictionary or not last_used_value is Dictionary:
		return ERR_INVALID_DATA
	assignments = assignments_value.duplicate(true)
	last_used_day = last_used_value.duplicate(true)
	for helper_value in assignments:
		if not definitions.has(StringName(helper_value)):
			return ERR_DOES_NOT_EXIST
	return OK
