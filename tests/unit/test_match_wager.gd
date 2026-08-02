extends RefCounted

const InventoryService = preload("res://src/inventory/inventory_service.gd")
const MatchWager = preload("res://src/mahjong/domain/match_wager.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var inventory = InventoryService.new()
	inventory.add_money(300)
	if not MatchWager.can_start(&"high_stakes", inventory.money_cents) or MatchWager.can_start(&"high_stakes", 299):
		failures.append("high-stakes wagers should require the full cash reserve")
	if MatchWager.settle(inventory, &"serious", 1) != OK or inventory.money_cents != 200:
		failures.append("losing a serious wager should deduct its cash stake")
	if MatchWager.settle(inventory, &"high_stakes", 0) != OK or inventory.money_cents != 500:
		failures.append("winning a high-stakes wager should award its cash stake")
	if MatchWager.settle(inventory, &"friendly", 1) != OK or inventory.money_cents != 500:
		failures.append("friendly wagers should not exchange cash")
	if MatchWager.settle(inventory, &"missing", 0) != ERR_INVALID_PARAMETER:
		failures.append("unknown wager tiers should be rejected")
	return failures
