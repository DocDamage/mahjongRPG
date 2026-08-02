extends RefCounted

const CropDefinition = preload("res://src/crops/crop_definition.gd")

enum State { PLANTED, WATERED, GROWING, READY, WILTED, DEAD, HARVESTED }

var definition
var state := State.PLANTED
var age_days := 0
var days_without_water := 0
var last_processed_day := 0
var last_watered_day := -1


func _init(next_definition, planted_day: int) -> void:
	definition = next_definition
	if definition == null or not definition is CropDefinition:
		push_error("Crop instance requires a valid crop definition")
	last_processed_day = planted_day


func water(day: int) -> Error:
	if day < last_processed_day or state in [State.DEAD, State.HARVESTED]:
		return ERR_INVALID_DATA
	last_watered_day = day
	days_without_water = 0
	if state == State.WILTED:
		state = State.GROWING
	elif state != State.READY:
		state = State.WATERED
	return OK


func advance_to_day(day: int) -> void:
	while last_processed_day < day and state not in [State.DEAD, State.HARVESTED]:
		_process_day(last_processed_day)
		last_processed_day += 1


func harvest() -> Dictionary:
	if state != State.READY:
		return {"error": ERR_INVALID_DATA}
	state = State.HARVESTED
	return {"crop_id": str(definition.id), "quantity": 1}


func snapshot() -> Dictionary:
	return {
		"crop_id": str(definition.id),
		"state": state,
		"age_days": age_days,
		"days_without_water": days_without_water,
		"last_processed_day": last_processed_day,
		"last_watered_day": last_watered_day,
	}


func _process_day(processed_day: int) -> void:
	if last_watered_day == processed_day:
		age_days += 1
		days_without_water = 0
		if age_days >= definition.days_to_mature:
			state = State.READY
		else:
			state = State.GROWING
		return
	days_without_water += 1
	if days_without_water >= definition.die_after_days:
		state = State.DEAD
	elif days_without_water >= definition.wilt_after_days:
		state = State.WILTED
