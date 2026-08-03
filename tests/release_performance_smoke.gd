extends SceneTree

const SCENES := [
	"res://src/bootstrap/bootstrap.tscn", "res://src/world/wayward_farm.tscn", "res://src/world/dustward.tscn",
	"res://src/world/riverbend.tscn", "res://src/world/bridlewood.tscn", "res://src/world/saints_landing.tscn",
	"res://src/world/ironhook.tscn", "res://src/world/gulls_rest.tscn", "res://src/world/red_testament.tscn", "res://src/world/kings_reach.tscn",
]
const MAX_INITIALIZATION_MILLISECONDS := 10_000.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var started := Time.get_ticks_usec()
	var failures: Array[String] = []
	for scene_path in SCENES:
		var scene := load(scene_path) as PackedScene
		if scene == null:
			failures.append("could not load %s" % scene_path)
			continue
		var instance := scene.instantiate()
		root.add_child(instance)
		root.remove_child(instance)
		instance.free()
	var audio_service: Variant = root.get_node_or_null("AudioService")
	if audio_service != null:
		audio_service.stop_catalog_music()
	await process_frame
	await process_frame
	var elapsed_milliseconds := (Time.get_ticks_usec() - started) / 1000.0
	if elapsed_milliseconds > MAX_INITIALIZATION_MILLISECONDS:
		failures.append("initialization took %.1fms; budget is %.1fms" % [elapsed_milliseconds, MAX_INITIALIZATION_MILLISECONDS])
	if failures.is_empty():
		print("Release performance smoke passed: %d scene initializations in %.1fms." % [SCENES.size(), elapsed_milliseconds])
		quit(0)
		return
	for failure in failures:
		push_error("Release performance smoke: %s" % failure)
	quit(1)
