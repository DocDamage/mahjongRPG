extends RefCounted

var definitions: Dictionary = {}
var active_effects: Dictionary = {}
var last_used_day: Dictionary = {}


func register_definition(data: Dictionary) -> Error:
	var item_id := StringName(data.get("output_id", ""))
	var effect: Variant = data.get("effect", {})
	if item_id.is_empty() or not effect is Dictionary or StringName(effect.get("id", "")).is_empty() or int(effect.get("max_uses_per_day", 0)) < 1:
		return ERR_INVALID_DATA
	definitions[item_id] = effect.duplicate(true)
	return OK


func consume(item_id: StringName, inventory, day: int) -> Error:
	var effect: Dictionary = definitions.get(item_id, {})
	if inventory == null or effect.is_empty() or int(last_used_day.get(item_id, 0)) == day or inventory.remove_item(item_id) != OK:
		return ERR_UNAVAILABLE
	active_effects[StringName(effect["id"])] = int(effect.get("value", 1))
	last_used_day[item_id] = day
	return OK


func consume_for_match(effect_id: StringName) -> int:
	var value := int(active_effects.get(effect_id, 0))
	active_effects.erase(effect_id)
	return value


func snapshot() -> Dictionary:
	return {"active_effects": active_effects.duplicate(true), "last_used_day": last_used_day.duplicate(true)}


func restore(data: Dictionary) -> Error:
	var effects: Variant = data.get("active_effects", {})
	var usage: Variant = data.get("last_used_day", {})
	if not effects is Dictionary or not usage is Dictionary:
		return ERR_INVALID_DATA
	for effect_id_value in effects:
		if int(effects[effect_id_value]) < 1:
			return ERR_INVALID_DATA
	for item_id_value in usage:
		if not definitions.has(StringName(item_id_value)) or int(usage[item_id_value]) < 1:
			return ERR_INVALID_DATA
	active_effects = effects.duplicate(true)
	last_used_day = usage.duplicate(true)
	return OK
