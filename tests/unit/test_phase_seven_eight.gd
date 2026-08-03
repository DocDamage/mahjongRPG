extends RefCounted

const GameSessionScript = preload("res://src/core/game_session.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_phase_catalogs_and_schedules(failures)
	_test_civic_case_and_schema_migration(failures)
	_test_trade_order_crafting_and_effects(failures)
	_test_full_inventory_and_duplicate_delivery(failures)
	return failures


func _test_phase_catalogs_and_schedules(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(706)
	if session.regions.definitions.size() < 5 or session.regions.is_unlocked(&"saints_landing") or session.regions.is_unlocked(&"ironhook"):
		failures.append("P7/P8 regions must be registered but safely locked on a new save")
	if session.crafting.definitions.size() < 7 or session.effects.definitions.size() < 7:
		failures.append("P8 must register cooking, preserves, flour, dairy, smoked fish, feed, and tonic recipes with bounded effects")
	if session.trade.shop_definitions.size() != 3:
		failures.append("P7/P8 civic and dock shop inventories must be data-backed")
	var schedule = preload("res://src/npcs/opponent_schedule.gd")
	for opponent_id in [&"registrar_elise", &"constable_mara", &"mariner_ves"]:
		if schedule.state(opponent_id, &"clear", 14).is_empty() or schedule.state(opponent_id, &"rain", 14).is_empty():
			failures.append("P7/P8 opponents must have inspectable clear and rain schedules")
	session.free()


func _test_civic_case_and_schema_migration(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(707)
	if session.regions.unlock(&"saints_landing") != OK or session.relationships.record_choice(&"elise_welcome", &"registrar_elise", 1) != OK:
		failures.append("P7 must register an unlockable civic region and persistent relationship dialogue choice")
	session.inventory.add_item(&"artisan_cheese")
	if session.properties.resolve(&"saints_landing_depot", &"quest", session.inventory) != OK or not session.properties.route_is_open(&"saints_to_ironhook"):
		failures.append("P7 property disputes must consume their explicit quest proof and open the linked route")
	if session.brands.unlock_hall_stage(3) != OK or session.brands.hall_stage != 3:
		failures.append("P7 must expose the third Hall stage after a civic case")
	var match_case = GameSessionScript.new()
	match_case.start_new_game(708)
	if match_case.properties.resolve(&"saints_landing_depot", &"match") != OK or match_case.properties.outcome(&"saints_landing_depot") != &"match":
		failures.append("P7 property cases must preserve the legal Mahjong-resolution outcome without quest-item consumption")
	var pre_phase_seven := session.snapshot()
	pre_phase_seven["schema_version"] = 11
	pre_phase_seven.erase("relationships"); pre_phase_seven.erase("properties"); pre_phase_seven.erase("trade"); pre_phase_seven.erase("crafting"); pre_phase_seven.erase("effects")
	var restored = GameSessionScript.new()
	if restored.restore(pre_phase_seven) != OK or not restored.relationships.values.is_empty() or not restored.properties.outcomes.is_empty() or restored.trade.table_tokens != 0:
		failures.append("pre-P7 saves must migrate stable empty civic and P8 economy records")
	var pre_phase_eight := session.snapshot()
	pre_phase_eight["schema_version"] = 12
	pre_phase_eight.erase("trade"); pre_phase_eight.erase("crafting"); pre_phase_eight.erase("effects")
	var p8_restored = GameSessionScript.new()
	if p8_restored.restore(pre_phase_eight) != OK or p8_restored.trade.table_tokens != 0 or not p8_restored.crafting.crafted.is_empty():
		failures.append("pre-P8 saves must migrate stable empty trade, recipe, and effect records")
	session.free(); restored.free(); match_case.free(); p8_restored.free()


func _test_trade_order_crafting_and_effects(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(808)
	for item_id in [&"crop_wheat", &"animal_milk", &"fish_catfish"]:
		session.inventory.add_item(item_id)
	if session.trade.post_order(&"ironhook_smokehouse_run") != OK:
		failures.append("P8 posted orders must become active exactly once")
	var delivered: Dictionary = session.trade.fulfill_order(&"ironhook_smokehouse_run", session.inventory)
	if delivered.has("error") or session.trade.table_tokens != 1 or session.trade.fulfill_order(&"ironhook_smokehouse_run", session.inventory).get("error", OK) == OK:
		failures.append("P8 delivery must be atomic, grant its table token, and reject duplicate delivery")
	if session.properties.resolve(&"ironhook_customs_warehouse", &"order") != OK or not session.properties.route_is_open(&"ironhook_warehouse_access"):
		failures.append("a completed dock order must resolve the dock property arc")
	session.inventory.add_item(&"crop_beetroot"); session.inventory.add_item(&"crop_radish")
	var crafted: Dictionary = session.crafting.craft(&"brew_tonic", session.inventory)
	if crafted.get("output_id", "") != "dock_tonic" or session.effects.consume(&"dock_tonic", session.inventory, session.day) != OK:
		failures.append("P8 tonic recipes must create a bounded, consumable Mahjong effect")
	var round_trip := session.snapshot()
	var restored = GameSessionScript.new()
	if restored.restore(round_trip) != OK or not restored.trade.completed_orders.has(&"ironhook_smokehouse_run") or not restored.properties.is_resolved(&"ironhook_customs_warehouse") or int(restored.effects.active_effects.get(&"mahjong_charge", 0)) != 1 or restored.effects.consume_for_match(&"mahjong_charge") != 1:
		failures.append("active economy, property, and recipe state must round-trip through schema thirteen saves")
	session.free(); restored.free()


func _test_full_inventory_and_duplicate_delivery(failures: Array[String]) -> void:
	var session = GameSessionScript.new()
	session.start_new_game(809)
	for index in 48:
		session.inventory.add_item(StringName("cargo_%d" % index), 9)
	if session.trade.post_order(&"ironhook_pantry_run") != OK or session.trade.fulfill_order(&"ironhook_pantry_run", session.inventory).get("error", OK) == OK:
		failures.append("an active P8 order with missing goods must preserve a full inventory without partial delivery")
	session.inventory.add_item(&"crop_tomato", 2); session.inventory.add_item(&"crop_potato")
	if session.trade.fulfill_order(&"ironhook_pantry_run", session.inventory).has("error"):
		failures.append("P8 orders must still resolve correctly with a large inventory")
	var active = GameSessionScript.new()
	active.start_new_game(810)
	active.trade.post_order(&"ironhook_pantry_run")
	var restored = GameSessionScript.new()
	if restored.restore(active.snapshot()) != OK or not restored.trade.active_orders.has(&"ironhook_pantry_run"):
		failures.append("active P8 order records must survive save/load without accidental completion")
	active.free(); restored.free()
	session.free()
