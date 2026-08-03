extends RefCounted

const DeedEvaluator = preload("res://src/mahjong/domain/deed_evaluator.gd")

const WIN_RENOWN := 1


static func calculate(tiles: Array, context: Dictionary = {}) -> Dictionary:
	var deeds := DeedEvaluator.evaluate(tiles, context)
	var total := WIN_RENOWN
	for deed in deeds:
		total += int(deed.get("renown", 0))
	return {"base": WIN_RENOWN, "deeds": deeds, "total": total}
