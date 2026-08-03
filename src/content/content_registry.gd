extends Node

signal table_loaded(table_id: StringName)

var _tables: Dictionary = {}


func load_table(table_id: StringName, resource_path: String) -> Error:
	if not FileAccess.file_exists(resource_path):
		return ERR_FILE_NOT_FOUND
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ERR_FILE_UNRECOGNIZED
	_tables[table_id] = parsed
	table_loaded.emit(table_id)
	return OK


func register_table(table_id: StringName, contents: Dictionary) -> void:
	_tables[table_id] = contents.duplicate(true)
	table_loaded.emit(table_id)


func table(table_id: StringName) -> Dictionary:
	return _tables.get(table_id, {}).duplicate(true)


func has_table(table_id: StringName) -> bool:
	return _tables.has(table_id)
