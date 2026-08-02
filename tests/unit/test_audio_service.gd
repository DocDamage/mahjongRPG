extends RefCounted

const AudioService = preload("res://src/audio/audio_service.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var service = AudioService.new()
	service.ensure_buses()
	if service.load_runtime_catalog() != OK or not ResourceLoader.exists(service.ambience_path(&"clear")) or not ResourceLoader.exists(service.ambience_path(&"rain")):
		failures.append("runtime audio catalog should resolve clear and rain ambience assets")
	for event_id in [&"footstep_grass", &"footstep_gravel", &"footstep_wood"]:
		if not ResourceLoader.exists(service.event_path(event_id)):
			failures.append("runtime audio catalog should resolve %s" % event_id)
	if service.set_bus_volume(&"Music", 0.5) != OK or not is_equal_approx(service.bus_volume(&"Music"), 0.5):
		failures.append("audio bus volume should round-trip in linear space")
	if service.set_bus_volume(&"Missing", 0.5) != ERR_DOES_NOT_EXIST or service.bus_volume(&"Missing") >= 0.0:
		failures.append("unknown audio buses should be rejected")
	service.free()
	return failures
