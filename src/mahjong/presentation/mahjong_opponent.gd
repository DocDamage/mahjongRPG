extends "res://src/interaction/world_interactable.gd"

const MahjongTable = preload("res://src/mahjong/presentation/mahjong_table.gd")

signal feedback(message: String)

@export var opponent_id: StringName


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, -14), 12.0, Color("e7c28f"))
	draw_rect(Rect2(-15, -2, 30, 30), Color("4a5571"))
	draw_rect(Rect2(-17, -30, 34, 9), Color("30231e"))


func _on_interacted(_actor: Node2D) -> void:
	if get_tree().get_first_node_in_group(&"mahjong_table_overlay") != null:
		return
	var definition := _load_definition()
	if definition.is_empty():
		feedback.emit("This opponent's table is not ready.")
		return
	var table = MahjongTable.new()
	table.opponent_name = String(definition["display_name"])
	table.opponent_loadout = _as_brand_loadout(definition["brands"])
	table.add_to_group(&"mahjong_table_overlay")
	get_tree().root.add_child(table)
	feedback.emit("%s accepts your Trail Rules challenge." % table.opponent_name)


func _load_definition() -> Dictionary:
	var file := FileAccess.open("res://data/opponents/vertical_slice_opponents.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var opponents_value: Variant = parsed.get("opponents", [])
	if opponents_value is Array:
		for entry_value in opponents_value:
			if entry_value is Dictionary and StringName(entry_value.get("id", "")) == opponent_id:
				return entry_value.duplicate(true)
	return {}


func _as_brand_loadout(values: Array) -> Array[StringName]:
	var loadout: Array[StringName] = []
	for value in values:
		loadout.append(StringName(value))
	return loadout
