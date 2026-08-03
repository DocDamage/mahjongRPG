extends RefCounted


static func migrate(snapshot_data: Dictionary, current_version: int) -> Dictionary:
	var schema_version := int(snapshot_data.get("schema_version", -1))
	if schema_version == current_version:
		return snapshot_data.duplicate(true)
	if schema_version < 1 or schema_version >= current_version:
		return {}
	var migrated := snapshot_data.duplicate(true)
	migrated["schema_version"] = current_version
	if schema_version <= 1:
		migrated["inventory"] = {"money_cents": 0, "items": {}, "fish_records": {}}
	if schema_version <= 2:
		migrated["quests"] = {"active": {}, "completed": {}, "unlocked_helpers": {}, "hall_milestones": {}}
	if schema_version <= 3:
		migrated["player"] = {"scene": "", "position": [0, 0]}
	if schema_version <= 4:
		migrated["tutorial_steps"] = {}
	if schema_version <= 5:
		var migration_day := maxi(1, int(migrated.get("day", 1)))
		migrated["animals"] = {"animals": {"juniper_hens": {"last_care_day": 0, "last_progress_day": migration_day, "happiness": 55, "products_ready": 0}}}
	if schema_version <= 6:
		var farm_data: Dictionary = migrated.get("farm", {})
		farm_data["constructions"] = []
		migrated["farm"] = farm_data
	if schema_version <= 7:
		migrated["brands"] = {"unlocked": {"orange": true, "blue": true}, "last_selected": ["orange", "blue"]}
		migrated["helpers"] = {"assignments": {}, "last_used_day": {}}
		migrated["evidence"] = {"discovered": {}}
		var horse_data: Dictionary = migrated.get("horse", {})
		horse_data["mounted"] = false
		horse_data["mounted_scene"] = ""
		horse_data["mounted_position"] = []
		migrated["horse"] = horse_data
	if schema_version <= 8:
		var brand_data: Dictionary = migrated.get("brands", {})
		brand_data["upgrades"] = {}
		brand_data["upgrade_points"] = 0
		brand_data["match_wins"] = {}
		brand_data["hall_stage"] = 1
		brand_data["unlocked_rulesets"] = {"trail": true}
		brand_data["discovered_deeds"] = {}
		migrated["brands"] = brand_data
	if schema_version <= 9:
		migrated["regions"] = {"unlocked_regions": {}, "fulfilled_orders": {}, "table_wins": {}, "repaired_structures": {}, "shortcuts": {}}
		var phase_five_farm: Dictionary = migrated.get("farm", {})
		var phase_five_constructions: Array = phase_five_farm.get("constructions", [])
		var has_barn := false
		for construction_value in phase_five_constructions:
			if construction_value is Dictionary and String(construction_value.get("id", "")) == "barn":
				has_barn = true
		if not has_barn:
			phase_five_constructions.append({"id": "barn", "anchor": [4, 1], "repaired": false})
		phase_five_farm["constructions"] = phase_five_constructions
		migrated["farm"] = phase_five_farm
		var phase_five_horse: Dictionary = migrated.get("horse", {})
		phase_five_horse["horse_name"] = "Saddle"
		migrated["horse"] = phase_five_horse
	if schema_version <= 10:
		var animals_data: Dictionary = migrated.get("animals", {})
		var old_animals: Dictionary = animals_data.get("animals", {})
		var upgraded_animals := {}
		for animal_id_value in old_animals:
			var animal_id := String(animal_id_value)
			var old_state: Dictionary = old_animals[animal_id_value] if old_animals[animal_id_value] is Dictionary else {}
			upgraded_animals[animal_id] = {
				"species_id": animal_id,
				"name": animal_id.capitalize(),
				"variant": "classic",
				"birth_day": 1,
				"last_care_day": int(old_state.get("last_care_day", 0)),
				"last_progress_day": int(old_state.get("last_progress_day", 1)),
				"happiness": int(old_state.get("happiness", 55)),
				"quality": 0,
				"products_ready": int(old_state.get("products_ready", 0)),
				"parents": [],
				"retired": false,
			}
		animals_data["animals"] = upgraded_animals
		migrated["animals"] = animals_data
	if schema_version <= 11:
		migrated["relationships"] = {"values": {}, "choices": {}}
		migrated["properties"] = {"outcomes": {}, "open_routes": {}}
	if schema_version <= 12:
		migrated["trade"] = {"table_tokens": 0, "active_orders": {}, "completed_orders": {}, "shop_stock": {}}
		migrated["crafting"] = {"crafted": {}}
		migrated["effects"] = {"active_effects": {}, "last_used_day": {}}
	if schema_version <= 13:
		migrated["angler"] = {"owned_gear": {"frontier_rod": true, "mealworm_bait": true, "river_spinner": true, "barbless_hook": true, "braided_line": true, "cork_bobber": true}, "loadout": {"rod": "frontier_rod", "bait": "mealworm_bait", "lure": "river_spinner", "hook": "barbless_hook", "line": "braided_line", "bobber": "cork_bobber"}, "discovered_conditions": {}, "records": {}, "contests": {}}
	if schema_version <= 14:
		migrated["desert"] = {"route_states": {}, "supernatural_records": {}, "recovered_clues": {}, "region_secrets": {}}
	if schema_version <= 15:
		migrated["community"] = {"active": {}, "completed": {}, "progress": {}, "discovered_secrets": {}, "finale_support": {}}
	if schema_version <= 16:
		var community_data: Dictionary = migrated.get("community", {})
		community_data["finale_support"] = community_data.get("finale_support", {})
		migrated["community"] = community_data
	if schema_version <= 17:
		migrated["public_life"] = {"rank_points": 0, "rank_id": "tenderfoot", "event_states": {}, "contributions": {}, "hall_milestones": {}}
	if schema_version <= 18:
		migrated["story"] = {"chain_validated": false, "bargain_discovered": false, "choices": {}, "explained_rules": {}, "silas_alive_proven": false, "kings_reach_sites": {}, "final_warning_accepted": false}
	if schema_version <= 19:
		migrated["finale"] = {"phase": "unstarted", "pre_finale_checkpoint_required": false, "pre_finale_checkpoint_captured": false, "championship_losses": 0, "opponent_defeated": false, "standoff_failures": 0, "ending_id": "", "standoff_response": "", "credits_seen": false}
	if schema_version <= 20:
		migrated["postgame"] = {"active": false, "ending_provenance": ""}
	return migrated
