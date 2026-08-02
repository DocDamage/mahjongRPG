extends RefCounted

const FishingGearCatalog = preload("res://src/fishing/fishing_gear_catalog.gd")
const FishingSession = preload("res://src/fishing/fishing_session.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var profile := FishingGearCatalog.default_profile()
	for key in ["label", "reel_multiplier", "bite_wait_multiplier", "hook_window_multiplier", "tension_multiplier"]:
		if not profile.has(key):
			failures.append("default fishing gear should include %s" % key)
	var session = FishingSession.new(7)
	if session.configure_gear(profile) != OK or session.configure_gear({"reel_multiplier": 0.0}) != ERR_INVALID_DATA:
		failures.append("fishing gear modifiers should validate before a session starts")
	if float(session.gear_profile.get("reel_multiplier", 1.0)) <= 1.0 or float(session.gear_profile.get("tension_multiplier", 1.0)) >= 1.0:
		failures.append("the starter rod and line should apply their authored fishing modifiers")
	return failures
