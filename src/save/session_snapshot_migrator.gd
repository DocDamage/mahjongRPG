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
	return migrated
