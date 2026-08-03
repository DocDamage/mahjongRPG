extends RefCounted

const OpponentSchedule = preload("res://src/npcs/opponent_schedule.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var mayor_clear := OpponentSchedule.state(&"mayor_bell", &"clear", 9)
	if not bool(mayor_clear.get("available", false)) or mayor_clear.get("position") != Vector2(190, 270):
		failures.append("Mayor Bell should occupy the courthouse table during clear morning hours")
	var mayor_rain := OpponentSchedule.state(&"mayor_bell", &"rain", 9)
	if bool(mayor_rain.get("available", true)) or mayor_rain.get("position") != Vector2(255, 330):
		failures.append("Mayor Bell should relocate and observe the rain schedule")
	for opponent_id in [&"mayor_bell", &"river_rose", &"dynamite_bill"]:
		if OpponentSchedule.state(opponent_id, &"clear", 12).is_empty() or OpponentSchedule.state(opponent_id, &"rain", 15).is_empty():
			failures.append("every slice opponent should have clear and rain schedule data")
		if OpponentSchedule.state(opponent_id, &"dust_wind", 12).is_empty() or OpponentSchedule.state(opponent_id, &"supernatural_fog", 12).is_empty():
			failures.append("P10 weather must fall back to an authored schedule instead of removing earlier opponents")
	return failures
