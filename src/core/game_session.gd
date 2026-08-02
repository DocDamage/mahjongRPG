extends Node

signal session_started(seed: int)
signal time_advanced(day: int, minute_of_day: int)
signal pause_changed(paused: bool)
signal weather_changed(weather_id: StringName)

const SAVE_SCHEMA_VERSION := 1
const MATCH_TIME_COST_MINUTES := 90
const MINUTES_PER_DAY := 24 * 60

var seed: int = 0
var day: int = 1
var minute_of_day: int = 8 * 60
var weather_id: StringName = &"clear"
var _pause_reasons: Dictionary = {}


func start_new_game(new_seed: int) -> void:
	seed = new_seed
	day = 1
	minute_of_day = 8 * 60
	weather_id = &"clear"
	_pause_reasons.clear()
	session_started.emit(seed)
	time_advanced.emit(day, minute_of_day)
	weather_changed.emit(weather_id)


func is_paused() -> bool:
	return not _pause_reasons.is_empty()


func request_pause(reason: StringName) -> void:
	var was_paused := is_paused()
	_pause_reasons[reason] = int(_pause_reasons.get(reason, 0)) + 1
	if not was_paused:
		pause_changed.emit(true)


func release_pause(reason: StringName) -> void:
	if not _pause_reasons.has(reason):
		return
	var remaining := int(_pause_reasons[reason]) - 1
	if remaining <= 0:
		_pause_reasons.erase(reason)
	else:
		_pause_reasons[reason] = remaining
	if not is_paused():
		pause_changed.emit(false)


func advance_minutes(minutes: int) -> void:
	if minutes <= 0 or is_paused():
		return
	minute_of_day += minutes
	while minute_of_day >= MINUTES_PER_DAY:
		minute_of_day -= MINUTES_PER_DAY
		day += 1
	time_advanced.emit(day, minute_of_day)


func complete_mahjong_match() -> void:
	advance_minutes(MATCH_TIME_COST_MINUTES)


func set_weather(next_weather_id: StringName) -> void:
	if next_weather_id == weather_id:
		return
	weather_id = next_weather_id
	weather_changed.emit(weather_id)


func make_rng(stream_name: StringName) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _stream_seed(stream_name)
	return rng


func snapshot() -> Dictionary:
	return {
		"schema_version": SAVE_SCHEMA_VERSION,
		"seed": seed,
		"day": day,
		"minute_of_day": minute_of_day,
		"weather_id": str(weather_id),
	}


func restore(snapshot_data: Dictionary) -> Error:
	if int(snapshot_data.get("schema_version", -1)) != SAVE_SCHEMA_VERSION:
		return ERR_FILE_UNRECOGNIZED
	var next_day := int(snapshot_data.get("day", 0))
	var next_minute := int(snapshot_data.get("minute_of_day", -1))
	if next_day < 1 or next_minute < 0 or next_minute >= MINUTES_PER_DAY:
		return ERR_INVALID_DATA
	seed = int(snapshot_data.get("seed", 0))
	day = next_day
	minute_of_day = next_minute
	weather_id = StringName(snapshot_data.get("weather_id", "clear"))
	_pause_reasons.clear()
	time_advanced.emit(day, minute_of_day)
	weather_changed.emit(weather_id)
	return OK


func _stream_seed(stream_name: StringName) -> int:
	var value := seed
	for byte in String(stream_name).to_utf8_buffer():
		value = int((value * 31) + byte)
	return value
