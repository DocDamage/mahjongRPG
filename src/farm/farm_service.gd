extends RefCounted

const CropDefinition = preload("res://src/crops/crop_definition.gd")
const CropInstance = preload("res://src/crops/crop_instance.gd")
const FarmGrid = preload("res://src/farm/farm_grid.gd")

var grid
var _definitions: Dictionary = {}
var _crops: Dictionary = {}
var _fields: Dictionary = {}
var _construction_definitions: Dictionary = {}
var _constructions: Dictionary = {}


func _init(next_grid) -> void:
	grid = next_grid
	if grid == null or not grid is FarmGrid:
		push_error("Farm service requires a farm grid")


func register_definition(definition) -> Error:
	if definition == null or not definition is CropDefinition or definition.id.is_empty():
		return ERR_INVALID_PARAMETER
	_definitions[definition.id] = definition
	return OK
func register_construction_definition(definition: Dictionary) -> Error:
	var construction_id := StringName(definition.get("id", ""))
	var footprint_value: Variant = definition.get("footprint", [])
	if construction_id.is_empty() or not footprint_value is Array or footprint_value.size() != 2:
		return ERR_INVALID_DATA
	var footprint := Vector2i(int(footprint_value[0]), int(footprint_value[1]))
	if footprint.x < 1 or footprint.y < 1:
		return ERR_INVALID_DATA
	_construction_definitions[construction_id] = {
		"id": construction_id,
		"name": String(definition.get("name", construction_id.capitalize())),
		"footprint": footprint,
		"walkable": bool(definition.get("walkable", false)),
		"color": String(definition.get("color", "ffffff")),
	}
	return OK
func plant(cell: Vector2i, crop_id: StringName, day: int) -> Error:
	if not _definitions.has(crop_id):
		return ERR_DOES_NOT_EXIST
	if not _definitions[crop_id].available_in_slice:
		return ERR_UNAVAILABLE
	if not _fields.has(cell):
		return ERR_UNAVAILABLE
	var placement: int = grid.place(crop_id, [cell])
	if placement != OK:
		return placement
	_crops[cell] = CropInstance.new(_definitions[crop_id], day)
	return OK
func water(cell: Vector2i, day: int) -> Error:
	if not _crops.has(cell):
		return ERR_DOES_NOT_EXIST
	return _crops[cell].water(day)
func advance_to_day(day: int) -> void:
	for crop in _crops.values():
		crop.advance_to_day(day)
func harvest(cell: Vector2i) -> Dictionary:
	if not _crops.has(cell):
		return {"error": ERR_DOES_NOT_EXIST}
	var result: Dictionary = _crops[cell].harvest()
	if result.has("error"):
		return result
	_crops.erase(cell)
	grid.clear([cell])
	return result
func crop_at(cell: Vector2i):
	return _crops.get(cell)
func place_field(cell: Vector2i) -> Error:
	var placement := can_place_field(cell)
	if placement != OK:
		return placement
	_fields[cell] = true
	return OK
func can_place_field(cell: Vector2i) -> Error:
	if _fields.has(cell):
		return ERR_ALREADY_EXISTS
	return grid.validate([cell])
func remove_field(cell: Vector2i) -> Error:
	if not _fields.has(cell):
		return ERR_DOES_NOT_EXIST
	if _crops.has(cell):
		return ERR_BUSY
	_fields.erase(cell)
	return OK
func relocate_field(from_cell: Vector2i, to_cell: Vector2i) -> Error:
	if not _fields.has(from_cell):
		return ERR_DOES_NOT_EXIST
	if _crops.has(from_cell):
		return ERR_BUSY
	var placement := can_place_field(to_cell)
	if placement != OK:
		return placement
	_fields.erase(from_cell)
	_fields[to_cell] = true
	return OK
func has_field(cell: Vector2i) -> bool:
	return _fields.has(cell)
func construction_definition(construction_id: StringName) -> Dictionary:
	return _construction_definitions.get(construction_id, {}).duplicate(true)
func construction_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for construction_id in _construction_definitions:
		ids.append(construction_id)
	ids.sort()
	return ids
func construction_at(cell: Vector2i) -> Dictionary:
	for anchor_value in _constructions:
		var anchor: Vector2i = anchor_value
		var entry: Dictionary = _constructions[anchor]
		if _construction_cells(anchor, StringName(entry["id"])).has(cell):
			return {"anchor": anchor, "id": StringName(entry["id"])}
	return {}
func place_construction(construction_id: StringName, anchor: Vector2i) -> Error:
	var placement := can_place_construction(construction_id, anchor)
	if placement != OK:
		return placement
	var definition := construction_definition(construction_id)
	var cells := _construction_cells(anchor, construction_id)
	if grid.place(_construction_owner(construction_id, anchor), cells, bool(definition["walkable"])) != OK:
		return ERR_INVALID_DATA
	_constructions[anchor] = {"id": construction_id}
	return OK
func remove_construction(anchor: Vector2i) -> Error:
	if not _constructions.has(anchor):
		return ERR_DOES_NOT_EXIST
	var construction_id := StringName(_constructions[anchor]["id"])
	grid.clear(_construction_cells(anchor, construction_id))
	_constructions.erase(anchor)
	return OK
func relocate_construction(from_anchor: Vector2i, to_anchor: Vector2i) -> Error:
	if not _constructions.has(from_anchor):
		return ERR_DOES_NOT_EXIST
	var construction_id := StringName(_constructions[from_anchor]["id"])
	var placement := can_relocate_construction(from_anchor, to_anchor)
	if placement != OK:
		return placement
	var definition := construction_definition(construction_id)
	var previous_cells := _construction_cells(from_anchor, construction_id)
	var next_cells := _construction_cells(to_anchor, construction_id)
	if grid.move(_construction_owner(construction_id, to_anchor), previous_cells, next_cells, bool(definition["walkable"])) != OK:
		return ERR_INVALID_DATA
	_constructions.erase(from_anchor)
	_constructions[to_anchor] = {"id": construction_id}
	return OK
func can_place_construction(construction_id: StringName, anchor: Vector2i) -> Error:
	var definition := construction_definition(construction_id)
	if definition.is_empty():
		return ERR_DOES_NOT_EXIST
	return _validate_construction_cells(_construction_cells(anchor, construction_id), bool(definition["walkable"]))
func can_relocate_construction(from_anchor: Vector2i, to_anchor: Vector2i) -> Error:
	if not _constructions.has(from_anchor):
		return ERR_DOES_NOT_EXIST
	var construction_id := StringName(_constructions[from_anchor]["id"])
	var definition := construction_definition(construction_id)
	return _validate_construction_cells(_construction_cells(to_anchor, construction_id), bool(definition["walkable"]), _construction_cells(from_anchor, construction_id))
func construction_anchors() -> Array[Vector2i]:
	var anchors: Array[Vector2i] = []
	for anchor_value in _constructions:
		anchors.append(anchor_value)
	anchors.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
		return first.y < second.y or (first.y == second.y and first.x < second.x)
	)
	return anchors
func field_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell_value in _fields:
		cells.append(cell_value)
	cells.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
		return first.y < second.y or (first.y == second.y and first.x < second.x)
	)
	return cells
func snapshot() -> Dictionary:
	var crops: Array = []
	for cell_value in _crops.keys():
		var cell: Vector2i = cell_value
		crops.append({"cell": [cell.x, cell.y], "crop": _crops[cell].snapshot()})
	var fields: Array = []
	for cell in field_cells():
		fields.append([cell.x, cell.y])
	var constructions: Array = []
	for anchor in construction_anchors():
		constructions.append({"id": String(_constructions[anchor]["id"]), "anchor": [anchor.x, anchor.y]})
	return {"crops": crops, "fields": fields, "constructions": constructions}
func restore(snapshot_data: Dictionary) -> Error:
	var entries_value = snapshot_data.get("crops", [])
	if not entries_value is Array:
		return ERR_INVALID_DATA
	var fields_value: Variant = snapshot_data.get("fields", null)
	if fields_value != null and not fields_value is Array:
		return ERR_INVALID_DATA
	var constructions_value: Variant = snapshot_data.get("constructions", [])
	if not constructions_value is Array:
		return ERR_INVALID_DATA
	grid.clear(_crops.keys())
	for anchor in construction_anchors():
		grid.clear(_construction_cells(anchor, StringName(_constructions[anchor]["id"])))
	_crops.clear()
	_constructions.clear()
	if fields_value is Array:
		_fields.clear()
		for field_value in fields_value:
			if not field_value is Array or field_value.size() != 2:
				return ERR_INVALID_DATA
			var field_cell := Vector2i(int(field_value[0]), int(field_value[1]))
			if place_field(field_cell) != OK:
				return ERR_INVALID_DATA
	for construction_value in constructions_value:
		if not construction_value is Dictionary:
			return ERR_INVALID_DATA
		var construction: Dictionary = construction_value
		var anchor_value: Variant = construction.get("anchor", [])
		if not anchor_value is Array or anchor_value.size() != 2:
			return ERR_INVALID_DATA
		var anchor := Vector2i(int(anchor_value[0]), int(anchor_value[1]))
		if place_construction(StringName(construction.get("id", "")), anchor) != OK:
			return ERR_INVALID_DATA
	for entry_value in entries_value:
		if not entry_value is Dictionary:
			return ERR_INVALID_DATA
		var entry: Dictionary = entry_value
		var coordinates_value = entry.get("cell", [])
		var crop_data_value = entry.get("crop", {})
		if not coordinates_value is Array or coordinates_value.size() != 2 or not crop_data_value is Dictionary:
			return ERR_INVALID_DATA
		var crop_data: Dictionary = crop_data_value
		var crop_id := StringName(crop_data.get("crop_id", ""))
		if not _definitions.has(crop_id):
			return ERR_DOES_NOT_EXIST
		var cell := Vector2i(int(coordinates_value[0]), int(coordinates_value[1]))
		if grid.place(crop_id, [cell]) != OK:
			return ERR_INVALID_DATA
		var crop = CropInstance.new(_definitions[crop_id], int(crop_data.get("last_processed_day", 0)))
		crop.state = int(crop_data.get("state", CropInstance.State.PLANTED))
		crop.age_days = int(crop_data.get("age_days", 0))
		crop.days_without_water = int(crop_data.get("days_without_water", 0))
		crop.last_watered_day = int(crop_data.get("last_watered_day", -1))
		_crops[cell] = crop
	return OK
func _construction_cells(anchor: Vector2i, construction_id: StringName) -> Array[Vector2i]:
	var definition := construction_definition(construction_id)
	if definition.is_empty():
		return []
	var footprint: Vector2i = definition["footprint"]
	var cells: Array[Vector2i] = []
	for y in footprint.y:
		for x in footprint.x:
			cells.append(anchor + Vector2i(x, y))
	return cells
func _validate_construction_cells(cells: Array, walkable: bool, ignored_cells: Array = []) -> Error:
	for cell_value in cells:
		var cell: Vector2i = cell_value
		if _fields.has(cell):
			return ERR_ALREADY_EXISTS
	return grid.validate(cells, walkable, ignored_cells)
func _construction_owner(construction_id: StringName, anchor: Vector2i) -> StringName:
	return StringName("construction:%s:%d:%d" % [construction_id, anchor.x, anchor.y])
