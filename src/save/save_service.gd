extends Node

signal saved(slot_id: StringName)
signal loaded(slot_id: StringName)
signal save_status(message: String)

const SAVE_SCHEMA_VERSION := 1
const MANUAL_SLOT_COUNT := 6
const SLOT_AUTOSAVE := &"autosave"
const SLOT_EMERGENCY := &"emergency"
const SLOT_PRE_FINALE := &"pre_finale"
const SAVE_DIRECTORY := "user://saves"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"save_game"):
		var save_result := save_current_session(SLOT_AUTOSAVE)
		save_status.emit("Game saved." if save_result == OK else "Save failed.")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"load_game"):
		var load_result := load_current_session(SLOT_AUTOSAVE)
		save_status.emit("Game loaded." if load_result == OK else "No valid autosave found.")
		get_viewport().set_input_as_handled()


func save_current_session(slot_id: StringName) -> Error:
	if not is_inside_tree():
		return ERR_UNAVAILABLE
	var session = get_node_or_null("/root/GameSession")
	if session == null:
		return ERR_UNAVAILABLE
	return save(slot_id, session.snapshot())


func load_current_session(slot_id: StringName) -> Error:
	if not is_inside_tree():
		return ERR_UNAVAILABLE
	var session = get_node_or_null("/root/GameSession")
	if session == null:
		return ERR_UNAVAILABLE
	var document := load_save(slot_id)
	var payload_value: Variant = document.get("payload")
	if not payload_value is Dictionary:
		return int(document.get("error", ERR_FILE_NOT_FOUND))
	return session.restore(payload_value)


func autosave(reason: StringName) -> Error:
	var result := save_current_session(SLOT_AUTOSAVE)
	if result == OK:
		save_status.emit("Autosaved after %s." % String(reason).replace("_", " "))
	return result


func save(slot_id: StringName, payload: Dictionary) -> Error:
	if not is_valid_slot(slot_id):
		return ERR_INVALID_PARAMETER
	var result := DirAccess.make_dir_recursive_absolute(SAVE_DIRECTORY)
	if result != OK:
		return result
	var serialized_payload := _serialize_payload(payload)
	var document := {
		"schema_version": SAVE_SCHEMA_VERSION,
		"payload": payload,
		"checksum": _checksum(serialized_payload),
	}
	var target := _slot_path(slot_id)
	var temporary := "%s.tmp" % target
	var backup := "%s.backup" % target
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(document))
	file.flush()
	file.close()
	if FileAccess.file_exists(target):
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(backup)
		DirAccess.rename_absolute(target, backup)
	var rename_result := DirAccess.rename_absolute(temporary, target)
	if rename_result != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, target)
		return rename_result
	saved.emit(slot_id)
	return OK


func load_save(slot_id: StringName) -> Dictionary:
	if not is_valid_slot(slot_id):
		return {"error": ERR_INVALID_PARAMETER}
	var primary := _read_document(_slot_path(slot_id))
	if primary.has("payload"):
		loaded.emit(slot_id)
		return primary
	var backup := _read_document("%s.backup" % _slot_path(slot_id))
	if backup.has("payload"):
		backup["recovered_from_backup"] = true
		loaded.emit(slot_id)
		return backup
	return primary


func is_valid_slot(slot_id: StringName) -> bool:
	if slot_id in [SLOT_AUTOSAVE, SLOT_EMERGENCY, SLOT_PRE_FINALE]:
		return true
	if not String(slot_id).begins_with("manual_"):
		return false
	var suffix := String(slot_id).trim_prefix("manual_")
	return suffix.is_valid_int() and int(suffix) >= 1 and int(suffix) <= MANUAL_SLOT_COUNT


func _read_document(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"error": ERR_FILE_NOT_FOUND}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": FileAccess.get_open_error()}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"error": ERR_FILE_CORRUPT}
	var document: Variant = parser.data
	if not document is Dictionary or int(document.get("schema_version", -1)) != SAVE_SCHEMA_VERSION:
		return {"error": ERR_FILE_UNRECOGNIZED}
	var payload: Variant = document.get("payload")
	if not payload is Dictionary:
		return {"error": ERR_INVALID_DATA}
	var actual_checksum := _checksum(_serialize_payload(payload))
	if document.get("checksum", "") != actual_checksum:
		return {"error": ERR_FILE_CORRUPT, "expected": document.get("checksum", ""), "actual": actual_checksum}
	return {"payload": _canonicalize(payload)}


func _checksum(serialized_payload: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(serialized_payload.to_utf8_buffer())
	return context.finish().hex_encode()


func _serialize_payload(payload: Dictionary) -> String:
	return JSON.stringify(_canonicalize(payload), "", true)


func _canonicalize(value: Variant) -> Variant:
	if value is Dictionary:
		var normalized: Dictionary = {}
		for key in value:
			normalized[key] = _canonicalize(value[key])
		return normalized
	if value is Array:
		var normalized: Array = []
		for item in value:
			normalized.append(_canonicalize(item))
		return normalized
	if value is float and is_equal_approx(value, round(value)):
		return int(value)
	return value


func _slot_path(slot_id: StringName) -> String:
	return "%s/%s.json" % [SAVE_DIRECTORY, slot_id]
