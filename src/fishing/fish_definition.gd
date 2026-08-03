extends RefCounted

var id: StringName
var difficulty: float
var hour_start: int
var hour_end: int
var sell_value_cents: int
var weather_ids: Array[StringName] = []
var shore_conditions: Array[StringName] = []
var rare_conditions: Array[StringName] = []


func _init(data: Dictionary) -> void:
	id = StringName(data.get("id", ""))
	difficulty = clampf(float(data.get("difficulty", -1.0)), 0.0, 1.0)
	sell_value_cents = int(data.get("sell_value_cents", -1))
	var hours_value: Variant = data.get("hours", [])
	if hours_value is Array and hours_value.size() == 2:
		hour_start = int(hours_value[0])
		hour_end = int(hours_value[1])
	var weather_value: Variant = data.get("weather", [])
	if weather_value is Array:
		for weather in weather_value:
			weather_ids.append(StringName(weather))
	var shore_value: Variant = data.get("shore_conditions", ["river"])
	if shore_value is Array:
		for shore in shore_value:
			shore_conditions.append(StringName(shore))
	var rare_value: Variant = data.get("rare_conditions", [])
	if rare_value is Array:
		for condition in rare_value:
			rare_conditions.append(StringName(condition))
	if id.is_empty() or sell_value_cents < 0 or hour_start < 0 or hour_end > 24 or hour_start >= hour_end or weather_ids.is_empty() or shore_conditions.is_empty():
		push_error("Invalid fish definition: %s" % id)


func matches(hour: int, weather_id: StringName) -> bool:
	return matches_conditions(hour, weather_id, &"river", &"")


func matches_conditions(hour: int, weather_id: StringName, shore_condition: StringName, rare_condition: StringName) -> bool:
	if hour < hour_start or hour >= hour_end or not weather_ids.has(weather_id) or not shore_conditions.has(shore_condition):
		return false
	return rare_conditions.is_empty() or rare_conditions.has(rare_condition)
