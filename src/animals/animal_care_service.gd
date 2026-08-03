extends RefCounted

const MAX_QUALITY := 3

var definitions: Dictionary = {}
var animals: Dictionary = {}
var capacities: Dictionary = {}


func register_definition(data: Dictionary) -> Error:
	var species_id := StringName(data.get("id", ""))
	var product_id := StringName(data.get("product_id", ""))
	if species_id.is_empty() or product_id.is_empty() or int(data.get("product_quantity", 0)) < 1 or definitions.has(species_id):
		return ERR_INVALID_DATA
	var variants_value: Variant = data.get("variants", ["classic"])
	if not variants_value is Array or variants_value.is_empty():
		return ERR_INVALID_DATA
	definitions[species_id] = data.duplicate(true)
	var starter_id := StringName(data.get("starter_id", species_id))
	if not animals.has(starter_id):
		_add_animal(starter_id, species_id, String(data.get("starter_name", data.get("display_name", species_id))), StringName(variants_value[0]), 1, [])
	return OK


func set_capacity(building_id: StringName, capacity: int) -> Error:
	if building_id.is_empty() or capacity < 0:
		return ERR_INVALID_PARAMETER
	capacities[building_id] = capacity
	return OK


func sync_capacity_from_farm(farm) -> void:
	if farm == null:
		return
	capacities[&"farm"] = farm.animal_capacity()
	for definition_value in definitions.values():
		var building_id := StringName(definition_value.get("building_id", "farm"))
		capacities[building_id] = farm.animal_capacity_for(building_id)


func add_animal(species_id: StringName, name: String, variant: StringName, day: int, parent_ids: Array = []) -> Dictionary:
	if day < 1 or name.strip_edges().is_empty() or not definitions.has(species_id) or not _valid_variant(species_id, variant):
		return {"error": ERR_INVALID_PARAMETER}
	if _species_count(species_id) >= _capacity_for(species_id):
		return {"error": ERR_UNAVAILABLE}
	var animal_id := _unique_id(species_id, name)
	_add_animal(animal_id, species_id, name.strip_edges(), variant, day, parent_ids)
	return {"animal_id": animal_id}


func breed(parent_a: StringName, parent_b: StringName, name: String, day: int, variant: StringName = &"") -> Dictionary:
	if not animals.has(parent_a) or not animals.has(parent_b) or parent_a == parent_b:
		return {"error": ERR_DOES_NOT_EXIST}
	var first: Dictionary = animals[parent_a]
	var second: Dictionary = animals[parent_b]
	var species_id := StringName(first.get("species_id", ""))
	if species_id != StringName(second.get("species_id", "")) or not is_mature(parent_a, day) or not is_mature(parent_b, day) or bool(first.get("retired", false)) or bool(second.get("retired", false)):
		return {"error": ERR_UNAVAILABLE}
	var chosen_variant := variant if not variant.is_empty() else StringName(first.get("variant", "classic"))
	return add_animal(species_id, name, chosen_variant, day, [str(parent_a), str(parent_b)])


func retire(animal_id: StringName, day: int) -> Error:
	if not animals.has(animal_id) or day < 1:
		return ERR_DOES_NOT_EXIST
	advance_to_day(day)
	var state: Dictionary = animals[animal_id]
	if bool(state.get("retired", false)):
		return ERR_ALREADY_IN_USE
	state["retired"] = true
	animals[animal_id] = state
	return OK


func feed(animal_id: StringName, day: int) -> Error:
	if day < 1:
		return ERR_INVALID_PARAMETER
	var targets := _targets(animal_id)
	if targets.is_empty():
		return ERR_INVALID_PARAMETER
	advance_to_day(day)
	var changed := false
	for target in targets:
		var state: Dictionary = animals[target]
		if not bool(state.get("retired", false)) and int(state["last_care_day"]) != day:
			state["last_care_day"] = day
			animals[target] = state
			changed = true
	return OK if changed else ERR_ALREADY_IN_USE


func collect(animal_id: StringName, day: int) -> int:
	if day < 1:
		return 0
	advance_to_day(day)
	var total := 0
	for target in _targets(animal_id):
		var state: Dictionary = animals[target]
		total += int(state["products_ready"])
		state["products_ready"] = 0
		animals[target] = state
	return total


func advance_to_day(day: int) -> Error:
	if day < 1:
		return ERR_INVALID_PARAMETER
	for animal_value in animals.keys():
		var animal_id := StringName(animal_value)
		var state: Dictionary = animals[animal_id]
		while int(state["last_progress_day"]) < day:
			var care_day := int(state["last_progress_day"])
			if bool(state.get("retired", false)):
				state["last_progress_day"] = care_day + 1
				continue
			if int(state["last_care_day"]) == care_day:
				state["happiness"] = mini(100, int(state["happiness"]) + 10)
				state["quality"] = mini(MAX_QUALITY, int(state.get("quality", 0)) + (1 if int(state["happiness"]) >= 70 else 0))
				if is_mature(animal_id, care_day + 1):
					var definition: Dictionary = definitions[StringName(state["species_id"])]
					state["products_ready"] = int(state["products_ready"]) + int(definition["product_quantity"]) + int(state["quality"] / 2)
			else:
				state["happiness"] = maxi(0, int(state["happiness"]) - 12)
				state["quality"] = maxi(0, int(state.get("quality", 0)) - 1)
			var definition: Dictionary = definitions[StringName(state["species_id"])]
			if care_day + 1 - int(state["birth_day"]) >= int(definition.get("retirement_days", 99999)):
				state["retired"] = true
			state["last_progress_day"] = care_day + 1
		animals[animal_id] = state
	return OK


func is_mature(animal_id: StringName, day: int) -> bool:
	if not animals.has(animal_id):
		return false
	var state: Dictionary = animals[animal_id]
	var definition: Dictionary = definitions.get(StringName(state.get("species_id", "")), {})
	return day - int(state.get("birth_day", day)) >= int(definition.get("mature_days", 1))


func display_name(animal_id: StringName) -> String:
	var targets := _targets(animal_id)
	if targets.is_empty():
		return String(animal_id)
	var state: Dictionary = animals[targets[0]]
	return String(state.get("name", animal_id))


func product_id(animal_id: StringName) -> StringName:
	var targets := _targets(animal_id)
	if targets.is_empty():
		return &""
	return StringName(definitions[StringName(animals[targets[0]]["species_id"])].get("product_id", ""))


func happiness(animal_id: StringName) -> int:
	var targets := _targets(animal_id)
	if targets.is_empty():
		return 0
	var total := 0
	for target in targets:
		total += int(animals[target]["happiness"])
	return int(total / targets.size())


func animal_state(animal_id: StringName) -> Dictionary:
	return animals.get(animal_id, {}).duplicate(true)


func lineage(animal_id: StringName) -> Array:
	var state: Dictionary = animals.get(animal_id, {})
	return state.get("parents", []).duplicate() if state.get("parents", []) is Array else []


func snapshot() -> Dictionary:
	return {"animals": animals.duplicate(true), "capacities": capacities.duplicate(true)}


func restore(data: Dictionary) -> Error:
	var states_value: Variant = data.get("animals", {})
	var capacity_value: Variant = data.get("capacities", {})
	if not states_value is Dictionary or not capacity_value is Dictionary:
		return ERR_INVALID_DATA
	for animal_value in states_value:
		var state: Variant = states_value[animal_value]
		if not state is Dictionary or not definitions.has(StringName(state.get("species_id", animal_value))) or int(state.get("birth_day", 0)) < 1 or int(state.get("last_progress_day", 0)) < 1 or int(state.get("happiness", -1)) < 0 or int(state.get("happiness", 101)) > 100:
			return ERR_INVALID_DATA
	animals = states_value.duplicate(true)
	capacities = capacity_value.duplicate(true)
	return OK


func _add_animal(animal_id: StringName, species_id: StringName, name: String, variant: StringName, day: int, parents: Array) -> void:
	animals[animal_id] = {"species_id": str(species_id), "name": name, "variant": str(variant), "birth_day": day, "last_care_day": 0, "last_progress_day": day, "happiness": 55, "quality": 0, "products_ready": 0, "parents": parents.duplicate(), "retired": false}


func _targets(id_or_species: StringName) -> Array[StringName]:
	var targets: Array[StringName] = []
	if animals.has(id_or_species):
		targets.append(id_or_species)
		return targets
	for animal_value in animals:
		if StringName(animals[animal_value].get("species_id", "")) == id_or_species:
			targets.append(StringName(animal_value))
	return targets


func _capacity_for(species_id: StringName) -> int:
	var definition: Dictionary = definitions[species_id]
	var building_id := StringName(definition.get("building_id", "farm"))
	return int(capacities.get(building_id, capacities.get(&"farm", int(definition.get("default_capacity", 1)))))


func _species_count(species_id: StringName) -> int:
	var count := 0
	for state_value in animals.values():
		if StringName(state_value.get("species_id", "")) == species_id and not bool(state_value.get("retired", false)):
			count += 1
	return count


func _valid_variant(species_id: StringName, variant: StringName) -> bool:
	return variant in definitions[species_id].get("variants", [])


func _unique_id(species_id: StringName, name: String) -> StringName:
	var base := "%s_%s" % [species_id, name.to_lower().replace(" ", "_")]
	var candidate := StringName(base)
	var suffix := 2
	while animals.has(candidate):
		candidate = StringName("%s_%d" % [base, suffix])
		suffix += 1
	return candidate
