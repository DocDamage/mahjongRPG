extends RefCounted

const TERMS := {
	&"friendly": {"label": "Friendly", "stake_cents": 0},
	&"serious": {"label": "Serious", "stake_cents": 100},
	&"high_stakes": {"label": "High Stakes", "stake_cents": 300},
	&"angler_catch": {"label": "Tarpon Catch", "stake_cents": 520, "stake_item": "fish_tarpon"},
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


static func can_start(tier: StringName, available_cents: int, inventory = null) -> bool:
	if not is_valid(tier):
		return false
	var stake_item := StringName(TERMS[tier].get("stake_item", ""))
	return inventory != null and inventory.item_count(stake_item) > 0 if not stake_item.is_empty() else available_cents >= stake_cents(tier)


static func settle(inventory, tier: StringName, winner: int) -> Error:
	var stake := stake_cents(tier)
	if stake < 0 or inventory == null:
		return ERR_INVALID_PARAMETER
	var stake_item := StringName(TERMS[tier].get("stake_item", ""))
	if not stake_item.is_empty():
		if winner < 0:
			return OK
		if winner == 0:
			return inventory.add_money(stake)
		return inventory.remove_item(stake_item)
	if stake == 0 or winner < 0:
		return OK
	if winner == 0:
		return inventory.add_money(stake)
	return inventory.spend_money(stake)
