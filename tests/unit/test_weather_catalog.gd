extends RefCounted

const WeatherCatalog = preload("res://src/weather/weather_catalog.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var active := WeatherCatalog.active_ids()
	if active != [&"clear", &"rain"]:
		failures.append("only clear and rain should be active in the vertical slice")
	var first := WeatherCatalog.roll_slice_weather(123, 4)
	if first not in active or first != WeatherCatalog.roll_slice_weather(123, 4):
		failures.append("weather rolls should be deterministic and use active catalog states")
	return failures
