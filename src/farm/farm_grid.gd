extends RefCounted

var bounds: Rect2i
var _blocked: Dictionary = {}
var _occupied: Dictionary = {}
var _walkable_occupied: Dictionary = {}
var _required_path: Dictionary = {}
var _route_guards: Array[Dictionary] = []


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


func set_route_guards(routes: Array) -> Error:
	_route_guards.clear()
	for route_value in routes:
		if not route_value is Array or route_value.size() != 2:
			return ERR_INVALID_DATA
		var start: Vector2i = route_value[0]
		var finish: Vector2i = route_value[1]
		if not bounds.has_point(start) or not bounds.has_point(finish):
			return ERR_PARAMETER_RANGE_ERROR
		_route_guards.append({"start": start, "finish": finish})
	return OK


func validate(cells: Array, allow_required_path := false, ignored_cells: Array = [], walkable := false) -> Error:
	if cells.is_empty():
		return ERR_INVALID_PARAMETER
	var ignored: Dictionary = {}
	for ignored_cell in ignored_cells:
		ignored[ignored_cell] = true
	for cell_value in cells:
		var cell: Vector2i = cell_value
		if not bounds.has_point(cell):
			return ERR_PARAMETER_RANGE_ERROR
		if _blocked.has(cell) or (_occupied.has(cell) and not ignored.has(cell)):
			return ERR_ALREADY_EXISTS
		if _required_path.has(cell) and not allow_required_path:
			return ERR_UNAVAILABLE
	if not walkable and not _routes_remain_open(cells, ignored):
		return ERR_UNAVAILABLE
	return OK


func place(owner_id: StringName, cells: Array, allow_required_path := false, walkable := false) -> Error:
	var result := validate(cells, allow_required_path, [], walkable)
	if result != OK:
		return result
	for cell_value in cells:
		_occupied[cell_value] = owner_id
		if walkable:
			_walkable_occupied[cell_value] = true
	return OK


func clear(cells: Array) -> void:
	for cell_value in cells:
		_occupied.erase(cell_value)
		_walkable_occupied.erase(cell_value)


func move(owner_id: StringName, previous_cells: Array, next_cells: Array, allow_required_path := false, walkable := false) -> Error:
	var result := validate(next_cells, allow_required_path, previous_cells, walkable)
	if result != OK:
		return result
	clear(previous_cells)
	for cell_value in next_cells:
		_occupied[cell_value] = owner_id
		if walkable:
			_walkable_occupied[cell_value] = true
	return OK


func is_occupied(cell: Vector2i) -> bool:
	return _occupied.has(cell)


func _routes_remain_open(next_cells: Array, ignored: Dictionary) -> bool:
	for route in _route_guards:
		if not _has_route(Vector2i(route["start"]), Vector2i(route["finish"]), next_cells, ignored):
			return false
	return true


func _has_route(start: Vector2i, finish: Vector2i, blocked_next: Array, ignored: Dictionary) -> bool:
	var planned: Dictionary = {}
	for cell_value in blocked_next:
		planned[cell_value] = true
	var pending: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}
	var offsets: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		if cell == finish:
			return true
		for offset: Vector2i in offsets:
			var candidate: Vector2i = cell + offset
			if visited.has(candidate) or not _is_walkable(candidate, planned, ignored):
				continue
			visited[candidate] = true
			pending.append(candidate)
	return false


func _is_walkable(cell: Vector2i, planned: Dictionary, ignored: Dictionary) -> bool:
	if not bounds.has_point(cell) or _blocked.has(cell) or planned.has(cell):
		return false
	return not _occupied.has(cell) or ignored.has(cell) or _walkable_occupied.has(cell)
