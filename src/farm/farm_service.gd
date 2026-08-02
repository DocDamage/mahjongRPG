extends RefCounted

const CropDefinition = preload("res://src/crops/crop_definition.gd")
const CropInstance = preload("res://src/crops/crop_instance.gd")
const FarmGrid = preload("res://src/farm/farm_grid.gd")

var grid
var _definitions: Dictionary = {}
var _crops: Dictionary = {}
var _fields: Dictionary = {}


func _init(next_grid) -> void:
	grid = next_grid
	if grid == null or not grid is FarmGrid:
		push_error("Farm service requires a farm grid")


func register_definition(definition) -> Error:
	if definition == null or not definition is CropDefinition or definition.id.is_empty():
		return ERR_INVALID_PARAMETER
	_definitions[definition.id] = definition
	return OK


func plant(cell: Vector2i, crop_id: StringName, day: int) -> Error:
	if not _definitions.has(crop_id):
		return ERR_DOES_NOT_EXIST
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


func has_field(cell: Vector2i) -> bool:
	return _fields.has(cell)


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
	return {"crops": crops, "fields": fields}


func restore(snapshot_data: Dictionary) -> Error:
	var entries_value = snapshot_data.get("crops", [])
	if not entries_value is Array:
		return ERR_INVALID_DATA
	var fields_value: Variant = snapshot_data.get("fields", null)
	if fields_value != null and not fields_value is Array:
		return ERR_INVALID_DATA
	grid.clear(_crops.keys())
	_crops.clear()
	if fields_value is Array:
		_fields.clear()
		for field_value in fields_value:
			if not field_value is Array or field_value.size() != 2:
				return ERR_INVALID_DATA
			var field_cell := Vector2i(int(field_value[0]), int(field_value[1]))
			if place_field(field_cell) != OK:
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
