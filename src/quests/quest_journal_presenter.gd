extends RefCounted

signal changed(projections: Array[Dictionary])

var _quests


func bind(quests) -> Error:
	if quests == null:
		return ERR_INVALID_PARAMETER
	if _quests == quests:
		refresh()
		return OK
	unbind()
	_quests = quests
	_quests.projection_refreshed.connect(refresh)
	refresh()
	return OK


func unbind() -> void:
	if _quests != null and _quests.projection_refreshed.is_connected(refresh):
		_quests.projection_refreshed.disconnect(refresh)
	_quests = null


func projections() -> Array[Dictionary]:
	return _quests.projections().duplicate(true) if _quests != null else []


func refresh() -> void:
	changed.emit(projections())
