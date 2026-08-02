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
