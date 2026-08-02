extends Node

const CropDefinition = preload("res://src/crops/crop_definition.gd")
const AnimalCareService = preload("res://src/animals/animal_care_service.gd")
const ConstructionCatalog = preload("res://src/farm/construction_catalog.gd")
const FarmGrid = preload("res://src/farm/farm_grid.gd")
const FarmService = preload("res://src/farm/farm_service.gd")
const HorseTravelState = preload("res://src/horses/horse_travel_state.gd")
const InventoryService = preload("res://src/inventory/inventory_service.gd")
const QuestService = preload("res://src/quests/quest_service.gd")
const SessionSnapshotMigrator = preload("res://src/save/session_snapshot_migrator.gd")

signal session_started(seed: int)
signal time_advanced(day: int, minute_of_day: int)
signal pause_changed(paused: bool)
signal weather_changed(weather_id: StringName)
signal session_restored()

const SAVE_SCHEMA_VERSION := 7
const MATCH_TIME_COST_MINUTES := 90
const MINUTES_PER_DAY := 24 * 60
const REAL_SECONDS_PER_DAY := 60.0

var seed: int = 0
var day: int = 1
var minute_of_day: int = 8 * 60
var weather_id: StringName = &"clear"
var farm
var horse
var inventory
var quests
var animals
var player_scene := ""
var player_position := Vector2.ZERO
var tutorial_steps: Dictionary = {}
var _pause_reasons: Dictionary = {}
var _time_accumulator := 0.0
func _process(delta: float) -> void:
	if is_paused():
		return
	_time_accumulator += delta * MINUTES_PER_DAY / REAL_SECONDS_PER_DAY
	var whole_minutes := int(_time_accumulator)
	if whole_minutes > 0:
		_time_accumulator -= whole_minutes
		advance_minutes(whole_minutes)
func _ready() -> void:
	_ensure_farm()
	_ensure_horse()
	_ensure_inventory()
	_ensure_quests()
	_ensure_animals()
func start_new_game(new_seed: int) -> void:
	seed = new_seed
	day = 1
	minute_of_day = 8 * 60
	weather_id = &"clear"
	farm = null
	horse = HorseTravelState.new()
	inventory = InventoryService.new()
	quests = null
	animals = null
	player_scene = ""
	player_position = Vector2.ZERO
	tutorial_steps.clear()
	_ensure_quests()
	_ensure_animals()
	_ensure_farm()
	_pause_reasons.clear()
	_time_accumulator = 0.0
	session_started.emit(seed)
	time_advanced.emit(day, minute_of_day)
	weather_changed.emit(weather_id)
func is_paused() -> bool:
	return not _pause_reasons.is_empty()
func request_pause(reason: StringName) -> void:
	var was_paused := is_paused()
	_pause_reasons[reason] = int(_pause_reasons.get(reason, 0)) + 1
	if not was_paused:
		pause_changed.emit(true)
func release_pause(reason: StringName) -> void:
	if not _pause_reasons.has(reason):
		return
	var remaining := int(_pause_reasons[reason]) - 1
	if remaining <= 0:
		_pause_reasons.erase(reason)
	else:
		_pause_reasons[reason] = remaining
	if not is_paused():
		pause_changed.emit(false)
func advance_minutes(minutes: int) -> void:
	if minutes <= 0 or is_paused():
		return
	minute_of_day += minutes
	while minute_of_day >= MINUTES_PER_DAY:
		minute_of_day -= MINUTES_PER_DAY
		day += 1
		set_weather(_weather_for_day(day))
		_ensure_animals().advance_to_day(day)
	time_advanced.emit(day, minute_of_day)
func complete_mahjong_match() -> void:
	advance_minutes(MATCH_TIME_COST_MINUTES)
func set_weather(next_weather_id: StringName) -> void:
	if next_weather_id == weather_id:
		return
	weather_id = next_weather_id
	weather_changed.emit(weather_id)


func make_rng(stream_name: StringName) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _stream_seed(stream_name)
	return rng


func record_player_state(scene_path: String, position: Vector2) -> void:
	if not scene_path.begins_with("res://"):
		return
	player_scene = scene_path
	player_position = position


func tutorial_step(tutorial_id: StringName) -> int:
	return maxi(0, int(tutorial_steps.get(tutorial_id, 0)))


func set_tutorial_step(tutorial_id: StringName, next_step: int) -> void:
	if tutorial_id.is_empty() or next_step < 0:
		return
	tutorial_steps[tutorial_id] = next_step


func snapshot() -> Dictionary:
	return {
		"schema_version": SAVE_SCHEMA_VERSION,
		"seed": seed,
		"day": day,
		"minute_of_day": minute_of_day,
		"weather_id": str(weather_id),
		"farm": _ensure_farm().snapshot(),
		"horse": _ensure_horse().snapshot(),
		"inventory": _ensure_inventory().snapshot(),
		"quests": _ensure_quests().snapshot(),
		"animals": _ensure_animals().snapshot(),
		"player": {"scene": player_scene, "position": [player_position.x, player_position.y]},
		"tutorial_steps": tutorial_steps.duplicate(true),
	}


func restore(snapshot_data: Dictionary) -> Error:
	var migrated := SessionSnapshotMigrator.migrate(snapshot_data, SAVE_SCHEMA_VERSION)
	if migrated.is_empty():
		return ERR_FILE_UNRECOGNIZED
	var next_day := int(migrated.get("day", 0))
	var next_minute := int(migrated.get("minute_of_day", -1))
	if next_day < 1 or next_minute < 0 or next_minute >= MINUTES_PER_DAY:
		return ERR_INVALID_DATA
	seed = int(migrated.get("seed", 0))
	day = next_day
	minute_of_day = next_minute
	weather_id = StringName(migrated.get("weather_id", "clear"))
	var farm_data_value = migrated.get("farm", {})
	if not farm_data_value is Dictionary or _ensure_farm().restore(farm_data_value) != OK:
		return ERR_INVALID_DATA
	var horse_data_value = migrated.get("horse", {})
	if not horse_data_value is Dictionary or _ensure_horse().restore(horse_data_value) != OK:
		return ERR_INVALID_DATA
	var inventory_data_value = migrated.get("inventory", {})
	if not inventory_data_value is Dictionary or _ensure_inventory().restore(inventory_data_value) != OK:
		return ERR_INVALID_DATA
	var quest_data_value = migrated.get("quests", {})
	if not quest_data_value is Dictionary or _ensure_quests().restore(quest_data_value) != OK:
		return ERR_INVALID_DATA
	var animal_data_value = migrated.get("animals", {})
	if not animal_data_value is Dictionary or _ensure_animals().restore(animal_data_value) != OK:
		return ERR_INVALID_DATA
	var player_data_value = migrated.get("player", {})
	if not player_data_value is Dictionary:
		return ERR_INVALID_DATA
	var player_data: Dictionary = player_data_value
	var position_value: Variant = player_data.get("position", [])
	if not position_value is Array or position_value.size() != 2:
		return ERR_INVALID_DATA
	player_scene = String(player_data.get("scene", ""))
	player_position = Vector2(float(position_value[0]), float(position_value[1]))
	var tutorial_steps_value: Variant = migrated.get("tutorial_steps", {})
	if not tutorial_steps_value is Dictionary:
		return ERR_INVALID_DATA
	tutorial_steps = tutorial_steps_value.duplicate(true)
	_pause_reasons.clear()
	_time_accumulator = 0.0
	time_advanced.emit(day, minute_of_day)
	weather_changed.emit(weather_id)
	session_restored.emit()
	if is_inside_tree() and not player_scene.is_empty():
		call_deferred("_restore_player_scene")
	return OK


func _stream_seed(stream_name: StringName) -> int:
	var value := seed
	for byte in String(stream_name).to_utf8_buffer():
		value = int((value * 31) + byte)
	return value


func _weather_for_day(next_day: int) -> StringName:
	var rng := RandomNumberGenerator.new()
	rng.seed = _stream_seed(&"weather") + next_day
	return &"rain" if rng.randi_range(0, 99) < 35 else &"clear"


func _ensure_farm():
	if farm != null:
		return farm
	var grid = FarmGrid.new(Rect2i(0, 0, 5, 3))
	grid.set_required_path([Vector2i(4, 1)])
	grid.set_blocked(Vector2i(4, 2))
	farm = FarmService.new(grid)
	for field_cell in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		farm.place_field(field_cell)
	var file := FileAccess.open("res://data/crops/vertical_slice_crops.json", FileAccess.READ)
	if file == null:
		push_error("Missing vertical-slice crop data")
		return farm
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Invalid vertical-slice crop data")
		return farm
	var crops_value = parsed.get("crops", [])
	if crops_value is Array:
		for crop_data_value in crops_value:
			if crop_data_value is Dictionary:
				farm.register_definition(CropDefinition.new(crop_data_value))
	if ConstructionCatalog.register_definitions(farm) != OK:
		push_error("Invalid vertical-slice construction data")
	return farm


func _ensure_horse():
	if horse == null:
		horse = HorseTravelState.new()
	return horse


func _ensure_inventory():
	if inventory == null:
		inventory = InventoryService.new()
	return inventory


func _ensure_quests():
	if quests != null:
		return quests
	quests = QuestService.new()
	var file := FileAccess.open("res://data/quests/vertical_slice_quests.json", FileAccess.READ)
	if file == null:
		push_error("Missing vertical-slice quest data")
		return quests
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var quest_values: Variant = parsed.get("quests", [])
		if quest_values is Array:
			for quest_value in quest_values:
				if quest_value is Dictionary:
					quests.register_definition(quest_value)
	return quests


func _ensure_animals():
	if animals != null:
		return animals
	animals = AnimalCareService.new()
	var file := FileAccess.open("res://data/animals/vertical_slice_animals.json", FileAccess.READ)
	if file == null:
		push_error("Missing vertical-slice animal data")
		return animals
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var animal_values: Variant = parsed.get("animals", [])
		if animal_values is Array:
			for animal_value in animal_values:
				if animal_value is Dictionary:
					animals.register_definition(animal_value)
	return animals


func _restore_player_scene() -> void:
	if player_scene.is_empty() or not ResourceLoader.exists(player_scene):
		return
	var current_scene = get_tree().current_scene
	if current_scene != null and current_scene.scene_file_path != player_scene:
		var router = get_node_or_null("/root/SceneRouter")
		if router != null:
			router.change_scene(player_scene)
