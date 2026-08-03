extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

enum Action { CROP_ORDER, REPAIR, SHORTCUT, PROCESS, DISCOVER_CLUE, ASSIGN_HELPER, BUY_ANIMAL, BREED_ANIMAL }

@export var action: Action
@export var target_id: StringName
@export var prerequisite_id: StringName
@export var animal_name := ""


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-28, -22, 56, 44), Color("7c5434"))
	draw_rect(Rect2(-28, -22, 56, 44), Color("f0d08c"), false, 2.0)
	draw_circle(Vector2(0, -30), 9.0, Color("f5c45e") if action == Action.DISCOVER_CLUE else Color("b6d477"))


func _on_interacted(_actor: Node2D) -> void:
	var result := ERR_UNAVAILABLE
	match action:
		Action.CROP_ORDER:
			result = GameSession.regions.fulfill_crop_order(target_id, GameSession.inventory)
		Action.REPAIR:
			result = GameSession.regions.repair(target_id, GameSession.farm, GameSession.inventory)
			if result == OK:
				GameSession.animals.sync_capacity_from_farm(GameSession.farm)
		Action.SHORTCUT:
			result = GameSession.regions.unlock_shortcut(target_id, prerequisite_id)
		Action.PROCESS:
			var processed: Dictionary = GameSession.processing.process(target_id, GameSession.farm, GameSession.inventory)
			result = processed.get("error", OK)
			if result == OK:
				feedback.emit("Processed %d %s." % [int(processed["output_count"]), String(processed["output_id"]).replace("_", " ").capitalize()])
				return
		Action.DISCOVER_CLUE:
			result = GameSession.evidence.discover(target_id)
		Action.ASSIGN_HELPER:
			result = GameSession.helpers.assign(target_id)
		Action.BUY_ANIMAL:
			result = _buy_animal()
		Action.BREED_ANIMAL:
			result = _breed_animal()
	if result == OK or (action == Action.DISCOVER_CLUE and result == ERR_ALREADY_IN_USE):
		feedback.emit(_success_text())
		return
	feedback.emit(_failure_text())


func _success_text() -> String:
	match action:
		Action.CROP_ORDER: return "Crop order fulfilled. The ranch ledger pays and opens its workbench."
		Action.REPAIR: return "Structure repaired. Its capacity and machine services are now available."
		Action.SHORTCUT: return "Farm shortcut unlocked. You can now use the Bridlewood hitching post."
		Action.DISCOVER_CLUE: return "Silas's Bridlewood clue was recorded in the evidence journal."
		Action.ASSIGN_HELPER: return "The ranch hand is assigned to the daily farm roster."
		Action.BUY_ANIMAL: return "A named %s joins your ranch roster." % String(target_id).capitalize()
		Action.BREED_ANIMAL: return "A new named lineage has begun at the ranch."
	return "Ranch work complete."


func _failure_text() -> String:
	match action:
		Action.CROP_ORDER: return "The order needs the listed crops in your inventory."
		Action.REPAIR: return "This repair needs its materials and an unbroken construction anchor."
		Action.SHORTCUT: return "Repair the ranch bridge before opening this shortcut."
		Action.PROCESS: return "Repair the required machine and bring its input product."
		Action.ASSIGN_HELPER: return "This helper assignment is unavailable."
		Action.BUY_ANIMAL: return "Repair the matching animal building and bring $1.00 for a named animal."
		Action.BREED_ANIMAL: return "Two mature animals of this type and free capacity are required."
	return "That clue is already recorded."


func _buy_animal() -> Error:
	if GameSession.inventory.spend_money(100) != OK:
		return ERR_UNAVAILABLE
	var definition: Dictionary = GameSession.animals.definitions.get(target_id, {})
	var variants: Array = definition.get("variants", [])
	var name := animal_name if not animal_name.is_empty() else String(target_id).capitalize()
	var result: Dictionary = GameSession.animals.add_animal(target_id, name, StringName(variants[0]) if not variants.is_empty() else &"classic", GameSession.day)
	if result.has("error"):
		GameSession.inventory.add_money(100)
		return result["error"]
	return OK


func _breed_animal() -> Error:
	var parents: Array[StringName] = []
	for animal_id_value in GameSession.animals.animals:
		var animal_id := StringName(animal_id_value)
		if StringName(GameSession.animals.animals[animal_id].get("species_id", "")) == target_id and GameSession.animals.is_mature(animal_id, GameSession.day):
			parents.append(animal_id)
	if parents.size() < 2:
		return ERR_UNAVAILABLE
	var result: Dictionary = GameSession.animals.breed(parents[0], parents[1], "Sprout", GameSession.day)
	return result.get("error", OK)
