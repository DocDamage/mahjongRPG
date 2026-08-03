extends RefCounted

var set_weight := 1.0
var run_weight := 1.0
var seen_tile_weight := 0.25


func _init(data: Dictionary = {}) -> void:
	set_weight = _weight(data.get("set_weight", set_weight), set_weight)
	run_weight = _weight(data.get("run_weight", run_weight), run_weight)
	seen_tile_weight = _weight(data.get("seen_tile_weight", seen_tile_weight), seen_tile_weight)


func _weight(value: Variant, fallback: float) -> float:
	var next := float(value)
	return clampf(next, 0.0, 3.0) if is_finite(next) else fallback
