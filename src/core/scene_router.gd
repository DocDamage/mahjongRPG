extends Node

signal transition_started(scene_path: String)
signal transition_finished(scene_path: String)
signal transition_failed(scene_path: String, error: Error)

var _transitioning := false


func change_scene(scene_path: String) -> Error:
	if _transitioning:
		return ERR_BUSY
	if not ResourceLoader.exists(scene_path):
		transition_failed.emit(scene_path, ERR_FILE_NOT_FOUND)
		return ERR_FILE_NOT_FOUND
	_transitioning = true
	transition_started.emit(scene_path)
	var result := get_tree().change_scene_to_file(scene_path)
	_transitioning = false
	if result == OK:
		transition_finished.emit(scene_path)
		call_deferred("_autosave_after_transition", scene_path)
	else:
		transition_failed.emit(scene_path, result)
	return result


func _autosave_after_transition(_scene_path: String) -> void:
	var save_service = get_node_or_null("/root/SaveService")
	if save_service != null:
		save_service.autosave(&"travel")
