extends "res://src/interaction/world_interactable.gd"

const FishingGearCatalog = preload("res://src/fishing/fishing_gear_catalog.gd")

signal feedback(message: String)

enum Action { DISCOVER_CONDITION, BUY_AND_EQUIP, ENTER_CONTEST, CRAFT, DISCOVER_RELATIONSHIP_CLUE, SELL_CATCH }

@export var action: Action
@export var target_id: StringName
@export var secondary_id: StringName


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-28, -22, 56, 44), Color("245c70"))
	draw_rect(Rect2(-28, -22, 56, 44), Color("f4d58a"), false, 2.0)
	draw_circle(Vector2(0, -28), 8.0, Color("c5e6db") if action == Action.DISCOVER_CONDITION else Color("f7b955"))


func _on_interacted(_actor: Node2D) -> void:
	match action:
		Action.DISCOVER_CONDITION:
			feedback.emit("Rare condition recorded: %s." % String(target_id).replace("_", " ") if GameSession.angler.discover_condition(target_id) == OK else "That rare condition is already in your angler journal.")
		Action.BUY_AND_EQUIP:
			var category := FishingGearCatalog.category_for(target_id)
			var bought: int = GameSession.angler.buy_gear(target_id, GameSession.inventory)
			if bought == OK or GameSession.angler.owned_gear.has(target_id):
				feedback.emit("%s equipped." % String(target_id).replace("_", " ") if GameSession.angler.equip(category, target_id) == OK else "Gear ownership changed, but the loadout is invalid.")
			else:
				feedback.emit("Bring more money for that coastal gear upgrade.")
		Action.ENTER_CONTEST:
			var result: Dictionary = GameSession.angler.enter_contest(target_id, secondary_id, GameSession.inventory)
			feedback.emit("Contest score %d — %s." % [int(result.get("score", 0)), "prize won" if bool(result.get("won", false)) else "enter again with a rarer catch"] if not result.has("error") else "Bring the named caught fish to enter the repeatable contest.")
		Action.CRAFT:
			var crafted: Dictionary = GameSession.crafting.craft(target_id, GameSession.inventory)
			feedback.emit("Cooked %s." % String(crafted.get("output_id", "")).replace("_", " ") if not crafted.has("error") else "Bring the listed catch and ingredients to cook this recipe.")
		Action.DISCOVER_RELATIONSHIP_CLUE:
			GameSession.relationships.record_choice(&"coral_fenn_letter", &"coral_fenn", 1)
			feedback.emit("Relationship clue recorded." if GameSession.evidence.discover(target_id) == OK else "That relationship clue is already in your journal.")
		Action.SELL_CATCH:
			if GameSession.inventory.remove_item(StringName("fish_%s" % target_id)) == OK:
				GameSession.inventory.add_money(180)
				feedback.emit("Sold the catch at Gull's Rest market.")
			else:
				feedback.emit("Bring that catch to market first.")
