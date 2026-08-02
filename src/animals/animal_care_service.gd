extends RefCounted

var definitions: Dictionary = {}
var animals: Dictionary = {}


func register_definition(data: Dictionary) -> Error:
	var animal_id := StringName(data.get("id", ""))
	var product_id := StringName(data.get("product_id", ""))
	var quantity := int(data.get("product_quantity", 0))
	if animal_id.is_empty() or product_id.is_empty() or quantity < 1 or definitions.has(animal_id):
		return ERR_INVALID_DATA
	definitions[animal_id] = data.duplicate(true)
	animals[animal_id] = {"last_care_day": 0, "last_progress_day": 1, "happiness": 55, "products_ready": 0}
	return OK


func feed(animal_id: StringName, day: int) -> Error:
	if day < 1 or not animals.has(animal_id):
		return ERR_INVALID_PARAMETER
	advance_to_day(day)
	var state: Dictionary = animals[animal_id]
	if int(state["last_care_day"]) == day:
		return ERR_ALREADY_IN_USE
	state["last_care_day"] = day
	animals[animal_id] = state
	return OK


func collect(animal_id: StringName, day: int) -> int:
	if day < 1 or not animals.has(animal_id):
		return 0
	advance_to_day(day)
	var state: Dictionary = animals[animal_id]
	var products := int(state["products_ready"])
	state["products_ready"] = 0
	animals[animal_id] = state
	return products


func advance_to_day(day: int) -> Error:
	if day < 1:
		return ERR_INVALID_PARAMETER
	for animal_value in animals.keys():
		var animal_id := StringName(animal_value)
		var state: Dictionary = animals[animal_id]
		while int(state["last_progress_day"]) < day:
			var care_day := int(state["last_progress_day"])
			if int(state["last_care_day"]) == care_day:
				state["happiness"] = mini(100, int(state["happiness"]) + 10)
				var definition: Dictionary = definitions[animal_id]
				state["products_ready"] = int(state["products_ready"]) + int(definition["product_quantity"])
			else:
				state["happiness"] = maxi(0, int(state["happiness"]) - 12)
			state["last_progress_day"] = care_day + 1
		animals[animal_id] = state
	return OK


func display_name(animal_id: StringName) -> String:
	var definition: Dictionary = definitions.get(animal_id, {})
	return String(definition.get("display_name", animal_id))


func product_id(animal_id: StringName) -> StringName:
	var definition: Dictionary = definitions.get(animal_id, {})
	return StringName(definition.get("product_id", ""))


func happiness(animal_id: StringName) -> int:
	var state: Dictionary = animals.get(animal_id, {})
	return int(state.get("happiness", 0))


func snapshot() -> Dictionary:
	return {"animals": animals.duplicate(true)}


func restore(data: Dictionary) -> Error:
	var states_value: Variant = data.get("animals", {})
	if not states_value is Dictionary:
		return ERR_INVALID_DATA
	for animal_value in definitions.keys():
		if not states_value.has(animal_value):
			return ERR_INVALID_DATA
		var state_value: Variant = states_value[animal_value]
		if not state_value is Dictionary:
			return ERR_INVALID_DATA
		var state: Dictionary = state_value
		if int(state.get("last_care_day", -1)) < 0 or int(state.get("last_progress_day", 0)) < 1 or int(state.get("happiness", -1)) < 0 or int(state.get("happiness", 101)) > 100 or int(state.get("products_ready", -1)) < 0:
			return ERR_INVALID_DATA
	animals = states_value.duplicate(true)
	return OK
