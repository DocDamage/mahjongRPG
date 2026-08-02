extends "res://src/interaction/world_interactable.gd"

const MahjongTable = preload("res://src/mahjong/presentation/mahjong_table.gd")

signal feedback(message: String)


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	_draw_table_ellipse(Vector2.ZERO, Vector2(42, 27), Color("4f2b19"))
	_draw_table_ellipse(Vector2.ZERO, Vector2(34, 20), Color("c8954c"))
	draw_circle(Vector2(-16, -10), 4.0, Color("d8e1db"))
	draw_circle(Vector2(16, -10), 4.0, Color("d8e1db"))


func _on_interacted(_actor: Node2D) -> void:
	if get_tree().get_first_node_in_group(&"mahjong_table_overlay") != null:
		return
	var table = MahjongTable.new()
	table.add_to_group(&"mahjong_table_overlay")
	get_tree().root.add_child(table)
	feedback.emit("Trail Rules match started. The match pauses the world.")


func _draw_table_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
