extends "res://src/interaction/world_interactable.gd"

const ShippingService = preload("res://src/economy/shipping_service.gd")

signal feedback(message: String)

var sales = ShippingService.new()


func _ready() -> void:
	interacted.connect(_on_interacted)
	_load_prices()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, -14), 12.0, Color("e7c28f"))
	draw_rect(Rect2(-15, -2, 30, 30), Color("5a7344"))
	draw_rect(Rect2(-18, -30, 36, 8), Color("453522"))


func _on_interacted(_actor: Node2D) -> void:
	var result: Dictionary = sales.ship_all(GameSession.inventory)
	var items: int = int(result.get("items", 0))
	var earned: int = int(result.get("earned_cents", 0))
	if items == 0:
		feedback.emit("Storekeeper: I buy crops and fish. Your sellable inventory is empty.")
		return
	feedback.emit("Storekeeper: Sold %d item(s) for $%.2f." % [items, earned / 100.0])


func _load_prices() -> void:
	var file := FileAccess.open("res://data/items/vertical_slice_items.json", FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		sales.configure(parsed)
