extends RefCounted

const MatchFlow = preload("res://src/mahjong/domain/match_flow.gd")
const MatchRuleset = preload("res://src/mahjong/domain/match_ruleset.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_green_and_pink(failures)
	_test_dark_and_purple(failures)
	return failures


func _test_green_and_pink(failures: Array[String]) -> void:
	var green = _flow([&"green", &"pink"])
	_charge(green, &"green")
	var before: int = green.hands[0].size()
	if green.activate_green(0) != OK or green.corrals[0].size() != 1 or green.hands[0].size() != before:
		failures.append("Green must store one tile in the Corral while preserving a legal discard hand")
	green.discard_at(0); green.draw(); green.discard_at(0)
	if green.release_green() != OK or not green.corrals[0].is_empty() or green.phase != MatchFlow.Phase.DISCARD:
		failures.append("Green must recover its Corral tile on a later draw phase")
	var pink = _flow([&"pink", &"green"])
	pink.configure_upgrades({&"pink": 1}, {})
	_charge(pink, &"pink")
	if pink.activate_pink(0) != OK or pink.neutral_tiles.size() != 1:
		failures.append("Pink must offer a tile to the visible neutral exchange")
	_charge(pink, &"pink")
	if pink.activate_pink(0) != OK or pink.neutral_tiles.size() != 2:
		failures.append("Pink's rank-one upgrade must expand the neutral exchange to two offers")
	if not _has_action(pink, "pink_offered"):
		failures.append("Pink's public exchange must be preserved as deterministic replay evidence")


func _test_dark_and_purple(failures: Array[String]) -> void:
	var dark = _flow([&"dark", &"purple"])
	dark.configure_upgrades({&"dark": 1}, {})
	dark.discard_at(0); dark.draw(); dark.discard_at(0)
	_charge(dark, &"dark")
	if dark.activate_dark() != OK or not bool(dark.discard_river.back().get("unclaimable", false)) or dark.hands[0].size() != 11 or dark.phase != MatchFlow.Phase.DISCARD:
		failures.append("Dark must visibly deny the latest opposing discard before claims resolve")
	var purple = MatchFlow.new(1300)
	purple.configure_loadouts([&"purple", &"dark"], [&"orange", &"blue"])
	purple.configure_upgrades({&"purple": 1}, {})
	purple.configure_ruleset(MatchRuleset.FRONTIER)
	purple.start_match()
	_charge(purple, &"purple")
	var first = purple.wall.back().key()
	var fourth = purple.wall[purple.wall.size() - 4].key()
	if purple.activate_purple([3, 2, 1, 0]) != OK or purple.wall.back().key() != fourth or not _has_action(purple, "purple_activated"):
		failures.append("Purple must visibly reorder the next three wall tiles and log the effect")
	if first == fourth:
		failures.append("Purple test setup needs distinct deterministic wall tiles")


func _flow(loadout: Array[StringName]):
	var flow = MatchFlow.new(1200 + loadout.size())
	flow.configure_loadouts(loadout, [&"orange", &"blue"])
	flow.start_match()
	return flow


func _charge(flow, brand: StringName) -> void:
	for ignored in 3:
		flow.brand_state(flow.turn_player).grant_charge(brand)


func _has_action(flow, action_type: String) -> bool:
	for action in flow.replay.actions:
		if String(action.get("type", "")) == action_type:
			return true
	return false
