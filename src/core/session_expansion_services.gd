extends RefCounted

const RelationshipService = preload("res://src/relationships/relationship_service.gd")
const PropertyService = preload("res://src/property/property_service.gd")
const TradeService = preload("res://src/economy/trade_service.gd")
const CraftingService = preload("res://src/economy/crafting_service.gd")
const FoodEffectService = preload("res://src/economy/food_effect_service.gd")


func reset(session) -> void:
	session.relationships = null; session.properties = null; session.trade = null
	session.crafting = null; session.effects = null


func ensure_relationships(session):
	if session.relationships == null:
		session.relationships = RelationshipService.new()
		session._load_catalog("res://data/civic/relationships.json", "relationships", session.relationships)
	return session.relationships


func ensure_properties(session):
	if session.properties == null:
		session.properties = PropertyService.new()
		session._load_catalog("res://data/civic/properties.json", "properties", session.properties)
	return session.properties


func ensure_trade(session):
	if session.trade == null:
		session.trade = TradeService.new()
		session._load_catalog("res://data/economy/ironhook_trade.json", "orders", session.trade, "register_order")
		session._load_catalog("res://data/economy/ironhook_trade.json", "shops", session.trade, "register_shop")
	return session.trade


func ensure_crafting(session):
	if session.crafting == null:
		session.crafting = CraftingService.new()
		session._load_catalog("res://data/economy/ironhook_recipes.json", "recipes", session.crafting)
	return session.crafting


func ensure_effects(session):
	if session.effects == null:
		session.effects = FoodEffectService.new()
		session._load_catalog("res://data/economy/ironhook_recipes.json", "recipes", session.effects)
	return session.effects
