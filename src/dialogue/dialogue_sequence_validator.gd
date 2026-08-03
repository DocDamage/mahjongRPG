extends RefCounted

const QuestEvent = preload("res://src/quests/quest_event.gd")
const CATALOG_SCHEMA_VERSION := 4
const SEQUENCE_SCHEMA_VERSION := 1
const CATALOG_KEYS := ["schema_version", "default_locale", "release_required_keys", "locales", "sequences"]
const SEQUENCE_KEYS := ["schema_version", "id", "start_node", "nodes"]
const NODE_KEYS := ["id", "speaker_id", "text_key", "portrait_expression", "next"]
const FORBIDDEN_KEYS := ["callable", "command", "expression", "node_path", "script", "script_path"]


static func validate_catalog(value: Variant, source := "<memory>", context: Dictionary = {}) -> Array[Dictionary]:
	var diagnostics: Array[Dictionary] = []
	if not value is Dictionary:
		_add(diagnostics, source, "$", "dialogue catalog must be a dictionary")
		return diagnostics
	var catalog: Dictionary = value
	_check_unknown(catalog, CATALOG_KEYS, source, "$", diagnostics)
	if int(catalog.get("schema_version", -1)) != CATALOG_SCHEMA_VERSION:
		_add(diagnostics, source, "$.schema_version", "unsupported dialogue catalog schema; expected %d" % CATALOG_SCHEMA_VERSION)
	var sequences_value: Variant = catalog.get("sequences", [])
	if not sequences_value is Array:
		_add(diagnostics, source, "$.sequences", "sequences must be an array")
		return diagnostics
	var sequence_ids: Dictionary = {}
	for index in sequences_value.size():
		var path := "$.sequences[%d]" % index
		var sequence_value: Variant = sequences_value[index]
		if sequence_value is Dictionary:
			var sequence_id := String(sequence_value.get("id", ""))
			if sequence_ids.has(sequence_id):
				_add(diagnostics, source, path + ".id", "duplicate sequence ID")
			sequence_ids[sequence_id] = true
		for diagnostic in validate(sequence_value, source, context):
			var nested := diagnostic.duplicate(true)
			nested["path"] = "%s%s" % [path, String(nested.get("path", "$" )).trim_prefix("$")]
			diagnostics.append(nested)
	return diagnostics


static func validate(value: Variant, source := "<memory>", context: Dictionary = {}) -> Array[Dictionary]:
	var diagnostics: Array[Dictionary] = []
	if not value is Dictionary:
		_add(diagnostics, source, "$", "dialogue sequence must be a dictionary")
		return diagnostics
	var sequence: Dictionary = value
	_check_forbidden(sequence, source, "$", diagnostics)
	_check_unknown(sequence, SEQUENCE_KEYS, source, "$", diagnostics)
	if int(sequence.get("schema_version", -1)) != SEQUENCE_SCHEMA_VERSION:
		_add(diagnostics, source, "$.schema_version", "unsupported dialogue sequence schema")
	if not QuestEvent._valid_id(String(sequence.get("id", ""))):
		_add(diagnostics, source, "$.id", "sequence ID must be a stable ID")
	var nodes_value: Variant = sequence.get("nodes", [])
	if not nodes_value is Array or nodes_value.is_empty():
		_add(diagnostics, source, "$.nodes", "sequence must contain at least one node")
		return diagnostics
	var nodes: Dictionary = {}
	for index in nodes_value.size():
		_validate_node(nodes_value[index], index, source, context, nodes, diagnostics)
	var start_id := String(sequence.get("start_node", ""))
	if not QuestEvent._valid_id(start_id) or not nodes.has(start_id):
		_add(diagnostics, source, "$.start_node", "start node does not exist")
		return diagnostics
	_validate_graph(start_id, nodes, source, diagnostics)
	return diagnostics


static func _validate_node(value: Variant, index: int, source: String, context: Dictionary, nodes: Dictionary, diagnostics: Array[Dictionary]) -> void:
	var path := "$.nodes[%d]" % index
	if not value is Dictionary:
		_add(diagnostics, source, path, "node must be a dictionary")
		return
	var node: Dictionary = value
	_check_unknown(node, NODE_KEYS, source, path, diagnostics)
	var node_id := String(node.get("id", ""))
	if not QuestEvent._valid_id(node_id):
		_add(diagnostics, source, path + ".id", "node ID must be a stable ID")
	elif nodes.has(node_id):
		_add(diagnostics, source, path + ".id", "duplicate node ID")
	else:
		nodes[node_id] = {"data": node, "index": index}
	var speaker_id := String(node.get("speaker_id", ""))
	if not QuestEvent._valid_id(speaker_id) or not _reference_exists(speaker_id, context.get("speaker_ids", [])):
		_add(diagnostics, source, path + ".speaker_id", "speaker does not exist")
	elif not _reference_exists(speaker_id, context.get("portrait_speaker_ids", [])):
		_add(diagnostics, source, path + ".speaker_id", "speaker portrait does not exist")
	var text_key := String(node.get("text_key", ""))
	if not QuestEvent._valid_id(text_key) or not _reference_exists(text_key, context.get("localization_keys", [])):
		_add(diagnostics, source, path + ".text_key", "localization key does not exist")
	var portrait := String(node.get("portrait_expression", ""))
	if not QuestEvent._valid_id(portrait) or not _reference_exists(portrait, context.get("portrait_expressions", [])):
		_add(diagnostics, source, path + ".portrait_expression", "portrait expression is unsupported")
	var next_id := String(node.get("next", ""))
	if not next_id.is_empty() and not QuestEvent._valid_id(next_id):
		_add(diagnostics, source, path + ".next", "next node must be empty or a stable ID")


static func _validate_graph(start_id: String, nodes: Dictionary, source: String, diagnostics: Array[Dictionary]) -> void:
	var visited: Dictionary = {}
	var current := start_id
	while not current.is_empty():
		if visited.has(current):
			_add(diagnostics, source, "$.nodes[%d].next" % int(nodes[current]["index"]), "cycles are unsupported for linear dialogue")
			break
		if not nodes.has(current):
			_add(diagnostics, source, "$", "next node does not exist: %s" % current)
			break
		visited[current] = true
		var node: Dictionary = nodes[current]["data"]
		var next_id := String(node.get("next", ""))
		if not next_id.is_empty() and not nodes.has(next_id):
			_add(diagnostics, source, "$.nodes[%d].next" % int(nodes[current]["index"]), "next node does not exist")
			break
		current = next_id
	for node_id in nodes:
		if not visited.has(node_id):
			_add(diagnostics, source, "$.nodes[%d]" % int(nodes[node_id]["index"]), "unreachable node")


static func _reference_exists(value: String, references: Variant) -> bool:
	if references is Array and not references.is_empty():
		return references.has(value) or references.has(StringName(value))
	if references is Dictionary and not references.is_empty():
		return references.has(value) or references.has(StringName(value))
	return true


static func _check_unknown(value: Dictionary, allowed: Array, source: String, path: String, diagnostics: Array[Dictionary]) -> void:
	for key_value in value:
		if not allowed.has(String(key_value)):
			_add(diagnostics, source, "%s.%s" % [path, key_value], "unknown dialogue field")


static func _check_forbidden(value: Variant, source: String, path: String, diagnostics: Array[Dictionary]) -> void:
	if value is Dictionary:
		for key_value in value:
			var child_path := "%s.%s" % [path, key_value]
			if FORBIDDEN_KEYS.has(String(key_value).to_lower()):
				_add(diagnostics, source, child_path, "runtime command data is prohibited")
			_check_forbidden(value[key_value], source, child_path, diagnostics)
	elif value is Array:
		for index in value.size():
			_check_forbidden(value[index], source, "%s[%d]" % [path, index], diagnostics)


static func _add(diagnostics: Array[Dictionary], source: String, path: String, message: String) -> void:
	diagnostics.append({"source": source, "path": path, "message": message})
