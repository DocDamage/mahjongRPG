extends RefCounted

const BrandLoadoutState = preload("res://src/mahjong/application/brand_loadout_state.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var state = BrandLoadoutState.new()
	if state.unlocked_brands().size() != 2 or state.is_unlocked(&"green"):
		failures.append("only the two starter Brands should be selectable on a fresh save")
	var green := state.record_match_win(&"river_rose", &"trail")
	var pink := state.record_match_win(&"dynamite_bill", &"trail")
	var dark := state.record_match_win(&"mayor_bell", &"trail")
	if green["unlocked"] != &"green" or pink["unlocked"] != &"pink" or dark["unlocked_brands"] != [&"dark", &"purple"]:
		failures.append("named existing-world mastery rematches should unlock Green, Pink, and Hall-awarded Purple")
	if not state.is_unlocked(&"dark") or not state.is_unlocked(&"purple") or not state.can_play_frontier():
		failures.append("the three rematches should unlock Dark and reopen the stage-two Frontier table")
	if state.select([&"green", &"purple"]) != OK:
		failures.append("every earned Brand must become a valid two-Brand loadout")
	if not state.can_upgrade(&"green") or state.upgrade(&"green") != OK or state.upgrade_rank(&"green") != 1:
		failures.append("earned bounded upgrade points should create exactly one functional Brand rank")
	var restored = BrandLoadoutState.new()
	if restored.restore(state.snapshot()) != OK or restored.snapshot() != state.snapshot():
		failures.append("Brand mastery, Hall stage, upgrades, and loadout must round-trip through saves")
	return failures
