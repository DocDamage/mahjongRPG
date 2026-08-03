extends RefCounted

signal property_resolved(property_id: StringName, method: StringName)

var definitions: Dictionary = {}
var outcomes: Dictionary = {}
var open_routes: Dictionary = {}


func register_definition(data: Dictionary) -> Error:
	var property_id := StringName(data.get("id", ""))
	var methods: Variant = data.get("resolution_methods", [])
	if property_id.is_empty() or definitions.has(property_id) or not methods is Array or methods.is_empty():
		return ERR_INVALID_DATA
	definitions[property_id] = data.duplicate(true)
	return OK


func resolve(property_id: StringName, method: StringName, inventory = null) -> Error:
	if outcomes.has(property_id):
		return ERR_ALREADY_IN_USE
	var definition: Dictionary = definitions.get(property_id, {})
	if definition.is_empty() or not _allows_method(definition, method) or (method == &"quest" and not _consume_requirements(definition, inventory)):
		return ERR_UNAVAILABLE
	outcomes[property_id] = method
	var route_id := StringName(definition.get("opens_route", ""))
	if not route_id.is_empty():
		open_routes[route_id] = true
	property_resolved.emit(property_id, method)
	return OK


func is_resolved(property_id: StringName) -> bool:
	return outcomes.has(property_id)


func outcome(property_id: StringName) -> StringName:
	return StringName(outcomes.get(property_id, ""))


func route_is_open(route_id: StringName) -> bool:
	return open_routes.has(route_id)


func snapshot() -> Dictionary:
	return {"outcomes": outcomes.duplicate(true), "open_routes": open_routes.duplicate(true)}


func restore(data: Dictionary) -> Error:
	var next_outcomes: Variant = data.get("outcomes", {})
	var next_routes: Variant = data.get("open_routes", {})
	if not next_outcomes is Dictionary or not next_routes is Dictionary:
		return ERR_INVALID_DATA
	for property_id_value in next_outcomes:
		var property_id := StringName(property_id_value)
		if not definitions.has(property_id) or not _allows_method(definitions[property_id], StringName(next_outcomes[property_id_value])):
			return ERR_INVALID_DATA
	for route_id_value in next_routes:
		var has_route := false
		for definition in definitions.values():
			if StringName(definition.get("opens_route", "")) == StringName(route_id_value):
				has_route = true
				break
		if not has_route:
			return ERR_INVALID_DATA
	outcomes = next_outcomes.duplicate(true)
	open_routes = next_routes.duplicate(true)
	return OK


func _allows_method(definition: Dictionary, method: StringName) -> bool:
	for method_value in definition.get("resolution_methods", []):
		if StringName(method_value) == method:
			return true
	return false


func _consume_requirements(definition: Dictionary, inventory) -> bool:
	var requirements: Variant = definition.get("requirements", [])
	if not requirements is Array:
		return false
	if requirements.is_empty():
		return true
	if inventory == null:
		return false
	for requirement_value in requirements:
		if not requirement_value is Dictionary or inventory.item_count(StringName(requirement_value.get("item_id", ""))) < int(requirement_value.get("count", 0)):
			return false
	for requirement_value in requirements:
		inventory.remove_item(StringName(requirement_value["item_id"]), int(requirement_value["count"]))
	return true
