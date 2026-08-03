extends Node

const CropDefinition = preload("res://src/crops/crop_definition.gd")
const AnimalCareService = preload("res://src/animals/animal_care_service.gd")
const ConstructionCatalog = preload("res://src/farm/construction_catalog.gd")
const FarmGrid = preload("res://src/farm/farm_grid.gd")
const FarmService = preload("res://src/farm/farm_service.gd")
const HorseTravelState = preload("res://src/horses/horse_travel_state.gd")
const InventoryService = preload("res://src/inventory/inventory_service.gd")
const QuestService = preload("res://src/quests/quest_service.gd")
const BrandLoadoutState = preload("res://src/mahjong/application/brand_loadout_state.gd")
const HelperService = preload("res://src/helpers/helper_service.gd")
const EvidenceService = preload("res://src/story/evidence_service.gd")
const ProcessingService = preload("res://src/farm/processing_service.gd")
const RegionProgressService = preload("res://src/regions/region_progress_service.gd")
const GameSessionSnapshot = preload("res://src/save/game_session_snapshot.gd")
const SessionSnapshotMigrator = preload("res://src/save/session_snapshot_migrator.gd")
const WeatherCatalog = preload("res://src/weather/weather_catalog.gd")
const SessionCatalogLoader = preload("res://src/core/session_catalog_loader.gd")

signal session_started(seed: int)
signal time_advanced(day: int, minute_of_day: int)
signal pause_changed(paused: bool)
signal weather_changed(weather_id: StringName)
signal session_restored()

const SAVE_SCHEMA_VERSION := 11
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
var brands
var helpers
var evidence
var processing
var regions
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
	_ensure_brands()
	_ensure_helpers()
	_ensure_evidence()
	_ensure_processing()
	_ensure_regions()
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
	brands = null
	helpers = null
	evidence = null
	processing = null
	regions = null
	player_scene = ""
	player_position = Vector2.ZERO
	tutorial_steps.clear()
	_ensure_quests()
	_ensure_animals()
	_ensure_brands()
	_ensure_helpers()
	_ensure_evidence()
	_ensure_processing()
	_ensure_regions()
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
		_ensure_farm().advance_to_day(day)
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
	return GameSessionSnapshot.capture(self)

func restore(snapshot_data: Dictionary) -> Error:
	var migrated := SessionSnapshotMigrator.migrate(snapshot_data, SAVE_SCHEMA_VERSION)
	if migrated.is_empty():
		return ERR_FILE_UNRECOGNIZED
	if GameSessionSnapshot.restore(self, migrated) != OK:
		return ERR_INVALID_DATA
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
	return WeatherCatalog.roll_slice_weather(_stream_seed(&"weather"), next_day)
func _ensure_farm():
	if farm != null:
		return farm
	var grid = FarmGrid.new(Rect2i(0, 0, 8, 4))
	grid.set_required_path([Vector2i(7, 1)])
	grid.set_route_guards([[Vector2i(0, 3), Vector2i(7, 0)], [Vector2i(0, 0), Vector2i(7, 3)]])
	grid.set_blocked(Vector2i(7, 2))
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
	if farm.place_construction(&"barn", Vector2i(4, 1)) != OK:
		push_error("Unable to stage the damaged Bridlewood barn")
	_ensure_animals().sync_capacity_from_farm(farm)
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
func _ensure_brands():
	if brands == null:
		brands = BrandLoadoutState.new()
	return brands
func _ensure_helpers():
	if helpers == null:
		helpers = HelperService.new()
		_load_catalog("res://data/helpers/vertical_slice_helpers.json", "helpers", helpers)
	return helpers
func _ensure_evidence():
	if evidence == null:
		evidence = EvidenceService.new()
		_load_catalog("res://data/story/vertical_slice_evidence.json", "evidence", evidence)
	return evidence
func _ensure_processing():
	if processing == null:
		processing = ProcessingService.new()
		_load_catalog("res://data/farm/vertical_slice_processing.json", "recipes", processing)
	return processing
func _ensure_regions():
	if regions == null:
		regions = RegionProgressService.new()
		_load_catalog("res://data/regions/bridlewood/region.json", "regions", regions)
	return regions
func _load_catalog(path: String, collection_key: String, service) -> void:
	if SessionCatalogLoader.load_into(path, collection_key, service) != OK:
		push_error("Invalid service catalog: %s" % path)
func _restore_player_scene() -> void:
	if player_scene.is_empty() or not ResourceLoader.exists(player_scene):
		return
	var current_scene = get_tree().current_scene
	if current_scene != null and current_scene.scene_file_path != player_scene:
		var router = get_node_or_null("/root/SceneRouter")
		if router != null:
			router.change_scene(player_scene)
