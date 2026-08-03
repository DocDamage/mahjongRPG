extends RefCounted


static func capture(session) -> Dictionary:
	return {
		"schema_version": session.SAVE_SCHEMA_VERSION,
		"seed": session.seed,
		"day": session.day,
		"minute_of_day": session.minute_of_day,
		"weather_id": str(session.weather_id),
		"farm": session._ensure_farm().snapshot(),
		"horse": session._ensure_horse().snapshot(),
		"inventory": session._ensure_inventory().snapshot(),
		"quests": session._ensure_quests().snapshot(),
		"animals": session._ensure_animals().snapshot(),
		"brands": session._ensure_brands().snapshot(),
		"helpers": session._ensure_helpers().snapshot(),
		"evidence": session._ensure_evidence().snapshot(),
		"regions": session._ensure_regions().snapshot(),
		"relationships": session.expansion_services.ensure_relationships(session).snapshot(),
		"properties": session.expansion_services.ensure_properties(session).snapshot(),
		"trade": session.expansion_services.ensure_trade(session).snapshot(),
		"crafting": session.expansion_services.ensure_crafting(session).snapshot(),
		"effects": session.expansion_services.ensure_effects(session).snapshot(),
		"angler": session.expansion_services.ensure_angler(session).snapshot(),
		"desert": session.expansion_services.ensure_desert(session).snapshot(),
		"player": {"scene": session.player_scene, "position": [session.player_position.x, session.player_position.y]},
		"tutorial_steps": session.tutorial_steps.duplicate(true),
	}


static func restore(session, migrated: Dictionary) -> Error:
	var next_day := int(migrated.get("day", 0))
	var next_minute := int(migrated.get("minute_of_day", -1))
	if next_day < 1 or next_minute < 0 or next_minute >= session.MINUTES_PER_DAY:
		return ERR_INVALID_DATA
	if not _restore_services(session, migrated):
		return ERR_INVALID_DATA
	var player_data_value: Variant = migrated.get("player", {})
	var tutorial_steps_value: Variant = migrated.get("tutorial_steps", {})
	if not player_data_value is Dictionary or not tutorial_steps_value is Dictionary:
		return ERR_INVALID_DATA
	var position_value: Variant = player_data_value.get("position", [])
	if not position_value is Array or position_value.size() != 2:
		return ERR_INVALID_DATA
	session.seed = int(migrated.get("seed", 0))
	session.day = next_day
	session.minute_of_day = next_minute
	session.weather_id = StringName(migrated.get("weather_id", "clear"))
	session.player_scene = String(player_data_value.get("scene", ""))
	session.player_position = Vector2(float(position_value[0]), float(position_value[1]))
	session.tutorial_steps = tutorial_steps_value.duplicate(true)
	return OK


static func _restore_services(session, data: Dictionary) -> bool:
	var services := [
		["farm", session._ensure_farm()],
		["horse", session._ensure_horse()],
		["inventory", session._ensure_inventory()],
		["quests", session._ensure_quests()],
		["animals", session._ensure_animals()],
		["brands", session._ensure_brands()],
		["helpers", session._ensure_helpers()],
		["evidence", session._ensure_evidence()],
		["regions", session._ensure_regions()],
		["relationships", session.expansion_services.ensure_relationships(session)],
		["properties", session.expansion_services.ensure_properties(session)],
		["trade", session.expansion_services.ensure_trade(session)],
		["crafting", session.expansion_services.ensure_crafting(session)],
		["effects", session.expansion_services.ensure_effects(session)],
		["angler", session.expansion_services.ensure_angler(session)],
		["desert", session.expansion_services.ensure_desert(session)],
	]
	for service_entry in services:
		var service_data: Variant = data.get(String(service_entry[0]), {})
		if not service_data is Dictionary or service_entry[1].restore(service_data) != OK:
			return false
	return true
