extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

enum Action { POST_ORDER, FULFILL_ORDER, BUY_ITEM, CRAFT, USE_FOOD, RESOLVE_PROPERTY, DISCOVER_CLUE }

@export var action: Action
@export var target_id: StringName
@export var shop_id: StringName


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-28, -22, 56, 44), Color("345b71"))
	draw_rect(Rect2(-28, -22, 56, 44), Color("f0d08c"), false, 2.0)
	draw_circle(Vector2(0, -30), 9.0, Color("f5c45e") if action == Action.DISCOVER_CLUE else Color("8bc5c0"))


func _on_interacted(_actor: Node2D) -> void:
	match action:
		Action.POST_ORDER:
			feedback.emit("Posted order accepted." if GameSession.trade.post_order(target_id) == OK else "That order is already active or completed.")
		Action.FULFILL_ORDER:
			var result: Dictionary = GameSession.trade.fulfill_order(target_id, GameSession.inventory)
			if result.has("error"):
				feedback.emit("Post this order first, then bring every listed good. Duplicate deliveries are refused.")
			else:
				if target_id == &"ironhook_smokehouse_run":
					GameSession.properties.resolve(&"ironhook_customs_warehouse", &"order")
				feedback.emit("Order delivered: $%.2f and %d table token(s)." % [int(result["money_cents"]) / 100.0, GameSession.trade.table_tokens])
		Action.BUY_ITEM:
			feedback.emit("Bought %s%s." % [String(target_id).replace("_", " "), _discount_note()] if GameSession.trade.buy(shop_id, target_id, GameSession.inventory, GameSession.helpers.passive_total(&"shop_discount_percent")) == OK else "That shop is sold out or you need more money.")
		Action.CRAFT:
			var crafted: Dictionary = GameSession.crafting.craft(target_id, GameSession.inventory)
			feedback.emit("Prepared %s." % String(crafted.get("output_id", "")).replace("_", " ") if not crafted.has("error") else "Bring the listed ingredients to prepare that recipe.")
		Action.USE_FOOD:
			feedback.emit("Prepared effect stored for your next Mahjong match." if GameSession.effects.consume(target_id, GameSession.inventory, GameSession.day) == OK else "That food is missing or its effect has already been used today.")
		Action.RESOLVE_PROPERTY:
			feedback.emit("The warehouse claim is recorded." if GameSession.properties.is_resolved(target_id) else "Complete the Smokehouse Supply Run to settle this dock property claim.")
		Action.DISCOVER_CLUE:
			var result: Error = GameSession.evidence.discover(target_id)
			feedback.emit("The cargo ledger joins your evidence journal." if result == OK else "That cargo ledger is already in your journal.")


func _discount_note() -> String:

	var discount := int(GameSession.helpers.passive_total(&"shop_discount_percent"))
	return " with %d%% community terms" % discount if discount > 0 else ""
