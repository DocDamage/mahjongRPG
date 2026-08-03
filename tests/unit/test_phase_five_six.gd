extends RefCounted

const AnimalCareService = preload("res://src/animals/animal_care_service.gd")
const CropDefinition = preload("res://src/crops/crop_definition.gd")
const FarmGrid = preload("res://src/farm/farm_grid.gd")
const FarmService = preload("res://src/farm/farm_service.gd")
const GameSessionScript = preload("res://src/core/game_session.gd")
const ProcessingService = preload("res://src/farm/processing_service.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_bridlewood_progress_and_migration(failures)
	_test_all_crops_and_dense_routes(failures)
	_test_lineage_capacity_quality_and_retirement(failures)
	_test_processing_and_round_trip(failures)
	return failures


func _test_bridlewood_progress_and_migration(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(505)
	if session.regions.is_unlocked(&"bridlewood"):
		failures.append("Bridlewood must begin locked on a fresh save")
	if session.regions.unlock(&"bridlewood") != OK:
		failures.append("First Lantern's follow-on region should unlock explicitly")
	session.inventory.add_item(&"crop_carrot"); session.inventory.add_item(&"crop_potato")
	if session.regions.fulfill_crop_order(&"bridlewood_first_harvest", session.inventory) != OK or not session.regions.fulfilled_orders.has(&"bridlewood_first_harvest"):
		failures.append("Bridlewood crop order must consume its two crop requirements and persist completion")
	var prior = session.snapshot()
	prior["schema_version"] = 9
	prior.erase("regions")
	prior["farm"]["constructions"] = []
	prior["animals"] = {"animals": {"juniper_hens": {"last_care_day": 0, "last_progress_day": 1, "happiness": 55, "products_ready": 0}}}
	var migrated = GameSessionScript.new()
	if migrated.restore(prior) != OK or migrated.regions.is_unlocked(&"bridlewood") or migrated.farm.construction_at(Vector2i(4, 1)).get("id", "") != "barn" or migrated.regions.has_shortcut(&"bridlewood_wayward_hitch"):
		failures.append("pre-P5 saves must gain a damaged Bridlewood barn, locked region, and safe P6 animal state")
	elif migrated.animals.animal_state(&"juniper_hens").is_empty():
		failures.append("pre-P6 animal groups must migrate to named-capable animal state")
	session.free(); migrated.free()


func _test_all_crops_and_dense_routes(failures: Array[String]) -> void:
	var file := FileAccess.open("res://data/crops/vertical_slice_crops.json", FileAccess.READ)
	var catalog: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	var active := 0
	for entry in catalog.get("crops", []) if catalog is Dictionary else []:
		if entry is Dictionary and bool(entry.get("available_in_slice", false)):
			active += 1
	if active != 21:
		failures.append("P6 must make all twenty supplied crops plus the original Wayward crop usable")
	var animal_file := FileAccess.open("res://data/animals/vertical_slice_animals.json", FileAccess.READ)
	var animal_catalog: Variant = JSON.parse_string(animal_file.get_as_text()) if animal_file != null else {}
	if not animal_catalog is Dictionary or animal_catalog.get("animals", []).size() != 5:
		failures.append("P6 must provide the complete five-species launch ranch roster")
	var grid = FarmGrid.new(Rect2i(0, 0, 4, 2))
	grid.set_route_guards([[Vector2i(0, 0), Vector2i(3, 0)]])
	for x in 4:
		grid.set_blocked(Vector2i(x, 1))
	var farm = FarmService.new(grid)
	farm.register_definition(CropDefinition.new({"id":"carrot","days_to_mature":2,"wilt_after_days":2,"die_after_days":4}))
	farm.register_construction_definition({"id":"fence","footprint":[1,1],"walkable":false})
	for cell in [Vector2i(0, 0), Vector2i(3, 0)]:
		farm.place_field(cell)
	if farm.place_construction(&"fence", Vector2i(1, 0)) != ERR_UNAVAILABLE:
		failures.append("dense placement must reject the final route-sealing construction")
	var snapshot := farm.snapshot()
	var restored = FarmService.new(FarmGrid.new(Rect2i(0, 0, 4, 2)));
	restored.grid.set_route_guards([[Vector2i(0, 0), Vector2i(3, 0)]])
	for x in 4:
		restored.grid.set_blocked(Vector2i(x, 1))
	restored.register_definition(CropDefinition.new({"id":"carrot","days_to_mature":2,"wilt_after_days":2,"die_after_days":4}))
	restored.register_construction_definition({"id":"fence","footprint":[1,1],"walkable":false})
	if restored.restore(snapshot) != OK:
		failures.append("sparse and dense farm layouts must round-trip safely")


func _test_lineage_capacity_quality_and_retirement(failures: Array[String]) -> void:
	var animals = AnimalCareService.new()
	animals.register_definition({"id":"goat","display_name":"Goat","product_id":"animal_goat_milk","product_quantity":1,"building_id":"barn","default_capacity":1,"mature_days":2,"retirement_days":7,"variants":["brown","white"]})
	animals.set_capacity(&"barn", 4)
	var doe: Dictionary = animals.add_animal(&"goat", "Daisy", &"brown", 1)
	var buck: Dictionary = animals.add_animal(&"goat", "Clover", &"white", 1)
	if doe.has("error") or buck.has("error"):
		failures.append("repaired building capacity must allow named animal variants")
	var kid: Dictionary = animals.breed(StringName(doe.get("animal_id", "")), StringName(buck.get("animal_id", "")), "Sprout", 3)
	if kid.has("error") or animals.lineage(StringName(kid.get("animal_id", ""))).size() != 2:
		failures.append("mature same-species parents must create a named lineage")
	animals.feed(StringName(kid.get("animal_id", "")), 4)
	animals.advance_to_day(6)
	if animals.collect(StringName(kid.get("animal_id", "")), 6) < 1:
		failures.append("fed mature animals must produce quality-aware products")
	animals.advance_to_day(10)
	if not bool(animals.animal_state(StringName(kid.get("animal_id", ""))).get("retired", false)):
		failures.append("long calendar advancement must safely retire aged animals")


func _test_processing_and_round_trip(failures: Array[String]) -> void:
	var grid = FarmGrid.new(Rect2i(0, 0, 4, 3))
	var farm = FarmService.new(grid)
	farm.register_construction_definition({"id":"cheese_press","footprint":[1,1],"walkable":false,"starts_damaged":true,"repair_cost":{"crop_wood":1}})
	farm.place_construction(&"cheese_press", Vector2i(1, 1))
	var session = GameSessionScript.new(); session.start_new_game(606)
	session.inventory.add_item(&"crop_wood")
	if farm.repair_construction(&"cheese_press", session.inventory) != OK:
		failures.append("machines must expose a material-backed repair step")
	if farm.relocate_construction(Vector2i(1, 1), Vector2i(2, 1)) != OK or not farm.has_repaired_construction(&"cheese_press"):
		failures.append("relocating a repaired machine must preserve its repair and processing state")
	var processing = ProcessingService.new()
	processing.register_definition({"id":"press_milk","machine_id":"cheese_press","input_id":"animal_milk","input_count":2,"output_id":"artisan_cheese","output_count":1})
	session.inventory.add_item(&"animal_milk", 2)
	if processing.process(&"press_milk", farm, session.inventory).get("output_id", "") != "artisan_cheese" or session.inventory.item_count(&"artisan_cheese") != 1:
		failures.append("repaired machines must process animal output into a persistent product")
	session.free()
