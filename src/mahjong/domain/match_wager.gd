extends RefCounted

const TERMS := {
	&"friendly": {"label": "Friendly", "stake_cents": 0},
	&"serious": {"label": "Serious", "stake_cents": 100},
	&"high_stakes": {"label": "High Stakes", "stake_cents": 300},
}


static func is_valid(tier: StringName) -> bool:
	return TERMS.has(tier)


static func stake_cents(tier: StringName) -> int:
	if not is_valid(tier):
		return -1
	return int(TERMS[tier]["stake_cents"])


static func label(tier: StringName) -> String:
	if not is_valid(tier):
		return "Unknown"
	return String(TERMS[tier]["label"])


static func can_start(tier: StringName, available_cents: int) -> bool:
	return stake_cents(tier) >= 0 and available_cents >= stake_cents(tier)


static func settle(inventory, tier: StringName, winner: int) -> Error:
	var stake := stake_cents(tier)
	if stake < 0 or inventory == null:
		return ERR_INVALID_PARAMETER
	if stake == 0 or winner < 0:
		return OK
	if winner == 0:
		return inventory.add_money(stake)
	return inventory.spend_money(stake)
