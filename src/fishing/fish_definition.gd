extends RefCounted

var id: StringName
var difficulty: float
var hour_start: int
var hour_end: int
var sell_value_cents: int
var weather_ids: Array[StringName] = []


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
	if id.is_empty() or sell_value_cents < 0 or hour_start < 0 or hour_end > 24 or hour_start >= hour_end or weather_ids.is_empty():
		push_error("Invalid fish definition: %s" % id)


func matches(hour: int, weather_id: StringName) -> bool:
	return hour >= hour_start and hour < hour_end and weather_ids.has(weather_id)
