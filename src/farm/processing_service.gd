extends RefCounted

var definitions: Dictionary = {}


func register_definition(data: Dictionary) -> Error:
	var recipe_id := StringName(data.get("id", ""))
	var input_id := StringName(data.get("input_id", ""))
	var output_id := StringName(data.get("output_id", ""))
	if recipe_id.is_empty() or input_id.is_empty() or output_id.is_empty() or int(data.get("input_count", 0)) < 1 or int(data.get("output_count", 0)) < 1:
		return ERR_INVALID_DATA
	definitions[recipe_id] = data.duplicate(true)
	return OK


func process(recipe_id: StringName, farm, inventory) -> Dictionary:
	var recipe: Dictionary = definitions.get(recipe_id, {})
	if recipe.is_empty() or farm == null or inventory == null:
		return {"error": ERR_DOES_NOT_EXIST}
	var machine_id := StringName(recipe.get("machine_id", ""))
	if not farm.has_repaired_construction(machine_id):
		return {"error": ERR_UNAVAILABLE}
	var input_id := StringName(recipe["input_id"])
	var input_count := int(recipe["input_count"])
	if inventory.remove_item(input_id, input_count) != OK:
		return {"error": ERR_UNAVAILABLE}
	var output_id := StringName(recipe["output_id"])
	var output_count := int(recipe["output_count"])
	inventory.add_item(output_id, output_count)
	return {"recipe_id": recipe_id, "output_id": output_id, "output_count": output_count}
