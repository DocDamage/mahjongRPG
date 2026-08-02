extends RefCounted

const CropDefinition = preload("res://src/crops/crop_definition.gd")
const CropInstance = preload("res://src/crops/crop_instance.gd")
const FarmGrid = preload("res://src/farm/farm_grid.gd")

var grid
var _definitions: Dictionary = {}
var _crops: Dictionary = {}


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


func snapshot() -> Dictionary:
	var crops: Array = []
	for cell_value in _crops.keys():
		var cell: Vector2i = cell_value
		crops.append({"cell": [cell.x, cell.y], "crop": _crops[cell].snapshot()})
	return {"crops": crops}


func restore(snapshot_data: Dictionary) -> Error:
	var entries_value = snapshot_data.get("crops", [])
	if not entries_value is Array:
		return ERR_INVALID_DATA
	grid.clear(_crops.keys())
	_crops.clear()
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
