extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

@export var animal_id: StringName = &"juniper_hens"


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-28, -20, 56, 40), Color("805939"))
	draw_rect(Rect2(-28, -20, 56, 40), Color("d9b46e"), false, 3.0)
	draw_circle(Vector2(-10, -5), 8.0, Color("e8ded0"))
	draw_circle(Vector2(10, 5), 8.0, Color("e8ded0"))


func _on_interacted(_actor: Node2D) -> void:
	var animal_name: String = GameSession.animals.display_name(animal_id)
	var products: int = GameSession.animals.collect(animal_id, GameSession.day)
	if products > 0:
		GameSession.inventory.add_item(GameSession.animals.product_id(animal_id), products)
		feedback.emit("Collected %d egg(s) from %s. Happiness: %d%%." % [products, animal_name, GameSession.animals.happiness(animal_id)])
		return
	var result: Error = GameSession.animals.feed(animal_id, GameSession.day)
	if result == OK:
		feedback.emit("Fed %s. They will lay eggs tomorrow. Happiness: %d%%." % [animal_name, GameSession.animals.happiness(animal_id)])
	else:
		feedback.emit("%s are already fed today. Happiness: %d%%." % [animal_name, GameSession.animals.happiness(animal_id)])
