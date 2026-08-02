extends "res://src/interaction/world_interactable.gd"

const MahjongTable = preload("res://src/mahjong/presentation/mahjong_table.gd")
const OpponentSchedule = preload("res://src/npcs/opponent_schedule.gd")

signal feedback(message: String)

@export var opponent_id: StringName

var _definition: Dictionary = {}
var _available := true
var _activity := ""


func _ready() -> void:
	interacted.connect(_on_interacted)
	_definition = _load_definition()
	GameSession.time_advanced.connect(_on_schedule_changed)
	GameSession.weather_changed.connect(_on_weather_changed)
	_update_availability()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, -14), 12.0, Color("e7c28f"))
	draw_rect(Rect2(-15, -2, 30, 30), Color("4a5571"))
	draw_rect(Rect2(-17, -30, 34, 9), Color("30231e"))


func _on_interacted(_actor: Node2D) -> void:
	if not _available:
		feedback.emit("%s is %s. Check back during the %s schedule." % [_definition.get("display_name", "This opponent"), _activity, GameSession.weather_id])
		return
	if get_tree().get_first_node_in_group(&"mahjong_table_overlay") != null:
		return
	if _definition.is_empty():
		feedback.emit("This opponent's table is not ready.")
		return
	var table = MahjongTable.new()
	table.opponent_id = opponent_id
	table.opponent_name = String(_definition["display_name"])
	table.opponent_loadout = _as_brand_loadout(_definition["brands"])
	var profile_value: Variant = _definition.get("ai", {})
	table.opponent_ai_profile = profile_value.duplicate(true) if profile_value is Dictionary else {}
	table.add_to_group(&"mahjong_table_overlay")
	get_tree().root.add_child(table)
	feedback.emit("%s accepts your Trail Rules challenge." % table.opponent_name)


func _on_schedule_changed(_day: int, _minute: int) -> void:
	_update_availability()


func _on_weather_changed(_weather_id: StringName) -> void:
	_update_availability()


func _update_availability() -> void:
	if _definition.is_empty():
		return
	var schedule := OpponentSchedule.state(opponent_id, GameSession.weather_id, GameSession.minute_of_day / 60)
	_available = bool(schedule.get("available", false))
	_activity = String(schedule.get("activity", "away"))
	var position_value: Variant = schedule.get("position")
	if position_value is Vector2:
		position = position_value
	visible = true
	monitorable = true
	monitoring = true
	prompt_text = "Challenge %s" % String(_definition.get("display_name", "opponent")) if _available else "Inspect %s's schedule" % String(_definition.get("display_name", "opponent"))


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
