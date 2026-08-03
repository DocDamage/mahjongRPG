extends RefCounted

const TRAIL := &"trail"
const FRONTIER := &"frontier"


static func is_valid(ruleset: StringName) -> bool:
	return ruleset in [TRAIL, FRONTIER]


static func copies_per_identity(ruleset: StringName) -> int:
	return 4 if ruleset == FRONTIER else 3


static func concealed_hand_size(ruleset: StringName) -> int:
	return 13 if ruleset == FRONTIER else 10


static func winning_hand_size(ruleset: StringName) -> int:
	return 14 if ruleset == FRONTIER else 11


static func group_count(ruleset: StringName) -> int:
	return 4 if ruleset == FRONTIER else 3


static func display_name(ruleset: StringName) -> String:
	return "Frontier Rules" if ruleset == FRONTIER else "Trail Rules"
