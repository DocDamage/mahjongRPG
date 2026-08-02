extends RefCounted

var bounds: Rect2i
var _blocked: Dictionary = {}
var _occupied: Dictionary = {}
var _required_path: Dictionary = {}


func _init(next_bounds: Rect2i) -> void:
	bounds = next_bounds


func set_blocked(cell: Vector2i, blocked := true) -> void:
	if blocked:
		_blocked[cell] = true
	else:
		_blocked.erase(cell)


func set_required_path(cells: Array) -> void:
	_required_path.clear()
	for cell_value in cells:
		_required_path[cell_value] = true


func validate(cells: Array) -> Error:
	if cells.is_empty():
		return ERR_INVALID_PARAMETER
	for cell_value in cells:
		var cell: Vector2i = cell_value
		if not bounds.has_point(cell):
			return ERR_PARAMETER_RANGE_ERROR
		if _blocked.has(cell) or _occupied.has(cell):
			return ERR_ALREADY_EXISTS
		if _required_path.has(cell):
			return ERR_UNAVAILABLE
	return OK


func place(owner_id: StringName, cells: Array) -> Error:
	var result := validate(cells)
	if result != OK:
		return result
	for cell_value in cells:
		_occupied[cell_value] = owner_id
	return OK


func clear(cells: Array) -> void:
	for cell_value in cells:
		_occupied.erase(cell_value)


func is_occupied(cell: Vector2i) -> bool:
	return _occupied.has(cell)
