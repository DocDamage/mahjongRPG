extends "res://src/interaction/world_interactable.gd"

const ShippingService = preload("res://src/economy/shipping_service.gd")

signal feedback(message: String)

var shipping = ShippingService.new()


func _ready() -> void:
	interacted.connect(_on_interacted)
	_load_prices()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-28, -20, 56, 40), Color("71401f"))
	draw_rect(Rect2(-28, -20, 56, 40), Color("d9b46e"), false, 3.0)
	draw_line(Vector2(-22, 0), Vector2(22, 0), Color("d9b46e"), 2.0)


func _on_interacted(_actor: Node2D) -> void:
	var result: Dictionary = shipping.ship_all(GameSession.inventory)
	if result.has("error"):
		feedback.emit("The shipping crate is unavailable.")
		return
	var item_count := int(result.get("items", 0))
	var earned := int(result.get("earned_cents", 0))
	if item_count == 0:
		feedback.emit("The shipping crate is empty.")
		return
	feedback.emit("Shipped %d item(s) for $%.2f." % [item_count, earned / 100.0])


func _load_prices() -> void:
	var file := FileAccess.open("res://data/items/vertical_slice_items.json", FileAccess.READ)
	if file == null:
		push_error("Missing vertical-slice item data")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or shipping.configure(parsed) != OK:
		push_error("Invalid vertical-slice item data")
