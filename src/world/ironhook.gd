extends Node2D

@onready var status_label: Label = $HUD/Status
@onready var message_label: Label = $HUD/Message


func _ready() -> void:
	queue_redraw()
	for landmark in get_tree().get_nodes_in_group(&"trade_landmark"):
		landmark.feedback.connect(_show_message)
	for opponent in get_tree().get_nodes_in_group(&"ironhook_opponent"):
		opponent.feedback.connect(_show_message)
	for exit_node in get_tree().get_nodes_in_group(&"ironhook_exit"):
		exit_node.feedback.connect(_show_message)
	_create_trade_controls()
	_update_status()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("3d7081"))
	draw_rect(Rect2(0, 0, 960, 86), Color("1f3037"))
	draw_rect(Rect2(0, 350, 960, 190), Color("24536b"))
	draw_rect(Rect2(65, 135, 280, 155), Color("866449"))
	draw_rect(Rect2(420, 125, 330, 170), Color("6b4f3c"))
	draw_line(Vector2(0, 330), Vector2(960, 330), Color("d0ab68"), 22.0)


func _update_status() -> void:
	var order_state := "complete" if GameSession.trade.completed_orders.has(&"ironhook_smokehouse_run") else "posted" if GameSession.trade.active_orders.has(&"ironhook_smokehouse_run") else "available"
	status_label.text = "IRONHOOK DOCKS  •  Smokehouse order: %s  •  Table tokens: %d  •  $%.2f" % [order_state, GameSession.trade.table_tokens, GameSession.inventory.money_cents / 100.0]


func _show_message(message: String) -> void:
	message_label.text = message
	_update_status()


func _create_trade_controls() -> void:
	var recipe_ids: Array = GameSession.crafting.definitions.keys()
	recipe_ids.sort()
	for index in recipe_ids.size():
		var recipe_id := StringName(recipe_ids[index])
		var recipe: Dictionary = GameSession.crafting.definitions[recipe_id]
		var button := Button.new()
		button.position = Vector2(18 + (index % 2) * 220, 92 + (index / 2) * 34)
		button.size = Vector2(210, 28)
		button.text = "Prepare %s" % String(recipe.get("display_name", recipe_id))
		button.pressed.connect(_craft_recipe.bind(recipe_id))
		add_child(button)
		var use_button := Button.new()
		use_button.position = Vector2(465 + (index % 2) * 230, 92 + (index / 2) * 34)
		use_button.size = Vector2(220, 28)
		use_button.text = "Use %s" % String(recipe.get("output_id", "")).replace("_", " ")
		use_button.pressed.connect(_use_food.bind(StringName(recipe.get("output_id", ""))))
		add_child(use_button)
	var shop_index := 0
	for shop_id_value in GameSession.trade.shop_definitions:
		var shop_id := StringName(shop_id_value)
		for stock_value in GameSession.trade.shop_definitions[shop_id].get("stock", []):
			if stock_value is Dictionary:
				var item_id := StringName(stock_value.get("item_id", ""))
				var shop_button := Button.new()
				shop_button.position = Vector2(18 + (shop_index % 2) * 220, 230 + (shop_index / 2) * 34)
				shop_button.size = Vector2(210, 28)
				shop_button.text = "Buy %s" % String(item_id).replace("_", " ")
				shop_button.pressed.connect(_buy_item.bind(shop_id, item_id))
				add_child(shop_button)
				shop_index += 1


func _craft_recipe(recipe_id: StringName) -> void:
	var result: Dictionary = GameSession.crafting.craft(recipe_id, GameSession.inventory)
	_show_message("Prepared %s." % String(result.get("output_id", "")).replace("_", " ") if not result.has("error") else "Bring the listed ingredients to prepare that recipe.")


func _use_food(item_id: StringName) -> void:
	_show_message("Prepared effect stored for your next Mahjong match." if GameSession.effects.consume(item_id, GameSession.inventory, GameSession.day) == OK else "That food is missing or its effect has already been used today.")


func _buy_item(shop_id: StringName, item_id: StringName) -> void:
	_show_message("Bought %s." % String(item_id).replace("_", " ") if GameSession.trade.buy(shop_id, item_id, GameSession.inventory) == OK else "That shop is sold out or you need more money.")
