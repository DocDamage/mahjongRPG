extends RefCounted

var definitions: Dictionary = {}
var crafted: Dictionary = {}


func register_definition(data: Dictionary) -> Error:
	var recipe_id := StringName(data.get("id", ""))
	var ingredients: Variant = data.get("ingredients", [])
	if recipe_id.is_empty() or definitions.has(recipe_id) or not ingredients is Array or ingredients.is_empty() or StringName(data.get("output_id", "")).is_empty():
		return ERR_INVALID_DATA
	definitions[recipe_id] = data.duplicate(true)
	return OK


func craft(recipe_id: StringName, inventory) -> Dictionary:
	var recipe: Dictionary = definitions.get(recipe_id, {})
	if recipe.is_empty() or inventory == null:
		return {"error": ERR_DOES_NOT_EXIST}
	for ingredient_value in recipe["ingredients"]:
		if not ingredient_value is Dictionary or inventory.item_count(StringName(ingredient_value.get("item_id", ""))) < int(ingredient_value.get("count", 0)):
			return {"error": ERR_UNAVAILABLE}
	for ingredient_value in recipe["ingredients"]:
		inventory.remove_item(StringName(ingredient_value["item_id"]), int(ingredient_value["count"]))
	var output_id := StringName(recipe["output_id"])
	var output_count := maxi(1, int(recipe.get("output_count", 1)))
	inventory.add_item(output_id, output_count)
	crafted[recipe_id] = int(crafted.get(recipe_id, 0)) + 1
	return {"recipe_id": recipe_id, "output_id": output_id, "output_count": output_count}


func snapshot() -> Dictionary:
	return {"crafted": crafted.duplicate(true)}


func restore(data: Dictionary) -> Error:
	var next_crafted: Variant = data.get("crafted", {})
	if not next_crafted is Dictionary:
		return ERR_INVALID_DATA
	for recipe_id_value in next_crafted:
		if not definitions.has(StringName(recipe_id_value)) or int(next_crafted[recipe_id_value]) < 0:
			return ERR_INVALID_DATA
	crafted = next_crafted.duplicate(true)
	return OK
