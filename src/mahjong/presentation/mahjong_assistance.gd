extends RefCounted

const TENDERFOOT := &"tenderfoot"
const TRAILHAND := &"trailhand"
const GUNSLINGER := &"gunslinger"


static func is_valid(mode: StringName) -> bool:
	return mode in [TENDERFOOT, TRAILHAND, GUNSLINGER]


static func show_recommendation(mode: StringName) -> bool:
	return mode != GUNSLINGER


static func show_danger_warning(mode: StringName) -> bool:
	return mode == TENDERFOOT


static func label(mode: StringName) -> String:
	return String(mode).capitalize()
