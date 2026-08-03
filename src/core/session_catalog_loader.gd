extends RefCounted


static func load_into(path: String, collection_key: String, service, method := "register_definition") -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	var entries: Variant = parsed.get(collection_key, []) if parsed is Dictionary else []
	if not entries is Array:
		return ERR_INVALID_DATA
	for entry in entries:
		if not entry is Dictionary or not service.has_method(method) or service.call(method, entry) != OK:
			return ERR_INVALID_DATA
	return OK
