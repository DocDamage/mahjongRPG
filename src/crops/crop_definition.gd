extends RefCounted

var id: StringName
var days_to_mature: int
var wilt_after_days: int
var die_after_days: int
var available_in_slice := true
var seed_cost_cents: int
var quality_explanation := "Water every day to improve quality."


func _init(data: Dictionary) -> void:
	id = StringName(data.get("id", ""))
	days_to_mature = int(data.get("days_to_mature", 0))
	wilt_after_days = int(data.get("wilt_after_days", 0))
	die_after_days = int(data.get("die_after_days", 0))
	available_in_slice = bool(data.get("available_in_slice", true))
	seed_cost_cents = int(data.get("seed_cost_cents", 0))
	quality_explanation = String(data.get("quality_explanation", quality_explanation))
	if id.is_empty() or days_to_mature < 1 or wilt_after_days < 1 or die_after_days <= wilt_after_days:
		push_error("Invalid crop definition: %s" % id)
