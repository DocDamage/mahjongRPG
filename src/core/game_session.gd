extends Node

const CropDefinition = preload("res://src/crops/crop_definition.gd")
const FarmGrid = preload("res://src/farm/farm_grid.gd")
const FarmService = preload("res://src/farm/farm_service.gd")
const HorseTravelState = preload("res://src/horses/horse_travel_state.gd")
const InventoryService = preload("res://src/inventory/inventory_service.gd")

signal session_started(seed: int)
signal time_advanced(day: int, minute_of_day: int)
signal pause_changed(paused: bool)
signal weather_changed(weather_id: StringName)

const SAVE_SCHEMA_VERSION := 2
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


func start_new_game(new_seed: int) -> void:
	seed = new_seed
	day = 1
	minute_of_day = 8 * 60
	weather_id = &"clear"
	farm = null
	horse = HorseTravelState.new()
	inventory = InventoryService.new()
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
	}


func restore(snapshot_data: Dictionary) -> Error:
	var migrated := _migrate_snapshot(snapshot_data)
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
	_pause_reasons.clear()
	_time_accumulator = 0.0
	time_advanced.emit(day, minute_of_day)
	weather_changed.emit(weather_id)
	return OK


func _stream_seed(stream_name: StringName) -> int:
	var value := seed
	for byte in String(stream_name).to_utf8_buffer():
		value = int((value * 31) + byte)
	return value


func _ensure_farm():
	if farm != null:
		return farm
	var grid = FarmGrid.new(Rect2i(0, 0, 8, 4))
	farm = FarmService.new(grid)
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
	return farm


func _ensure_horse():
	if horse == null:
		horse = HorseTravelState.new()
	return horse


func _ensure_inventory():
	if inventory == null:
		inventory = InventoryService.new()
	return inventory


func _migrate_snapshot(snapshot_data: Dictionary) -> Dictionary:
	var schema_version := int(snapshot_data.get("schema_version", -1))
	if schema_version == SAVE_SCHEMA_VERSION:
		return snapshot_data.duplicate(true)
	if schema_version != 1:
		return {}
	var migrated := snapshot_data.duplicate(true)
	migrated["schema_version"] = SAVE_SCHEMA_VERSION
	migrated["inventory"] = {"money_cents": 0, "items": {}, "fish_records": {}}
	return migrated
