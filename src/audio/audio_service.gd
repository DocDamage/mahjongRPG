extends Node

const BUS_NAMES := [&"Master", &"Music", &"Ambience", &"SFX", &"Mahjong", &"UI"]

var _events: Dictionary = {}


func _ready() -> void:
	ensure_buses()


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
