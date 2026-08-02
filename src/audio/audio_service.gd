extends Node

const BUS_NAMES := [&"Master", &"Music", &"Ambience", &"SFX", &"Mahjong", &"UI"]
const AUDIO_CATALOG_PATH := "res://data/audio/vertical_slice_audio.json"

var _events: Dictionary = {}
var _ambience_paths: Dictionary = {}
var _ambience_player: AudioStreamPlayer
var _active_ambience: StringName


func _ready() -> void:
	ensure_buses()
	load_runtime_catalog()
	call_deferred("_sync_weather_ambience")


func _exit_tree() -> void:
	if _ambience_player != null:
		_ambience_player.stop()
		_ambience_player.stream = null
	_ambience_player = null
	_active_ambience = &""


func load_runtime_catalog() -> Error:
	var file := FileAccess.open(AUDIO_CATALOG_PATH, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.get("ambience", {}) is Dictionary:
		return ERR_FILE_UNRECOGNIZED
	_ambience_paths = parsed["ambience"].duplicate(true)
	return OK


func ambience_path(weather_id: StringName) -> String:
	return String(_ambience_paths.get(weather_id, ""))


func set_weather_ambience(weather_id: StringName) -> Error:
	var path := ambience_path(weather_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return ERR_DOES_NOT_EXIST
	if _active_ambience == weather_id and _ambience_player != null:
		return OK
	var stream := load(path) as AudioStream
	if stream == null:
		return ERR_CANT_OPEN
	if _ambience_player == null:
		_ambience_player = AudioStreamPlayer.new()
		_ambience_player.bus = &"Ambience"
		_ambience_player.finished.connect(_restart_ambience)
		add_child(_ambience_player)
	_active_ambience = weather_id
	_ambience_player.stream = stream
	_ambience_player.play()
	return OK


func ensure_buses() -> void:
	for bus_name in BUS_NAMES:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func register_event(event_id: StringName, stream: AudioStream, bus_name: StringName = &"SFX") -> void:
	if AudioServer.get_bus_index(bus_name) < 0:
		push_error("Unknown audio bus: %s" % bus_name)
		return
	_events[event_id] = {"stream": stream, "bus": bus_name}


func play_event(event_id: StringName) -> AudioStreamPlayer:
	if not _events.has(event_id):
		push_error("Unknown audio event: %s" % event_id)
		return null
	var event: Dictionary = _events[event_id]
	var player := AudioStreamPlayer.new()
	player.stream = event["stream"]
	player.bus = event["bus"]
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player


func set_bus_volume(bus_name: StringName, linear_volume: float) -> Error:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return ERR_DOES_NOT_EXIST
	AudioServer.set_bus_volume_db(index, linear_to_db(clamp(linear_volume, 0.0, 1.0)))
	return OK


func bus_volume(bus_name: StringName) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return -1.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


func _sync_weather_ambience() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var session = get_node_or_null("/root/GameSession")
	if session == null:
		return
	session.weather_changed.connect(set_weather_ambience)
	set_weather_ambience(session.weather_id)


func _restart_ambience() -> void:
	if _ambience_player != null and not _active_ambience.is_empty():
		_ambience_player.play()
