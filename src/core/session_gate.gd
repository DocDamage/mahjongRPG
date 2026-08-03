extends RefCounted

var _restrictions: Dictionary = {}


func request(reason: StringName) -> void:
	if reason.is_empty():
		return
	_restrictions[reason] = int(_restrictions.get(reason, 0)) + 1


func release(reason: StringName) -> void:
	if not _restrictions.has(reason):
		return
	var remaining := int(_restrictions[reason]) - 1
	if remaining <= 0:
		_restrictions.erase(reason)
	else:
		_restrictions[reason] = remaining


func can_replace_session() -> bool:
	return _restrictions.is_empty()
