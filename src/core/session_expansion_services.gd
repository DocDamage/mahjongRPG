extends RefCounted

const RelationshipService = preload("res://src/relationships/relationship_service.gd")
const PropertyService = preload("res://src/property/property_service.gd")
const TradeService = preload("res://src/economy/trade_service.gd")
const CraftingService = preload("res://src/economy/crafting_service.gd")
const FoodEffectService = preload("res://src/economy/food_effect_service.gd")
const FishingProgressService = preload("res://src/fishing/fishing_progress_service.gd")
const DesertProgressService = preload("res://src/desert/desert_progress_service.gd")
const CommunityArcService = preload("res://src/community/community_arc_service.gd")
const PublicLifeService = preload("res://src/public_life/public_life_service.gd")
const ActThreeService = preload("res://src/story/act_three_service.gd")


func reset(session) -> void:
	session.relationships = null; session.properties = null; session.trade = null
	session.crafting = null; session.effects = null; session.angler = null; session.desert = null; session.community = null
	session.public_life = null; session.story = null


func ensure_all(session) -> void:
	ensure_angler(session); ensure_desert(session); ensure_relationships(session); ensure_properties(session)
	ensure_trade(session); ensure_crafting(session); ensure_effects(session); ensure_community(session)
	ensure_public_life(session); ensure_story(session)


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


func ensure_angler(session):
	if session.angler == null:
		session.angler = FishingProgressService.new()
	return session.angler


func ensure_desert(session):
	if session.desert == null:
		session.desert = DesertProgressService.new()
	return session.desert


func ensure_community(session):
	if session.community == null:
		session.community = CommunityArcService.new()
		session._load_catalog("res://data/community/community_arcs.json", "arcs", session.community)
	return session.community


func ensure_public_life(session):
	if session.public_life == null:
		session.public_life = PublicLifeService.new()
		session._load_catalog("res://data/civic/public_events.json", "events", session.public_life)
	session.public_life.sync_property_contributions(ensure_properties(session))
	return session.public_life


func ensure_story(session):
	if session.story == null:
		session.story = ActThreeService.new()
		session._load_catalog("res://data/story/act_three.json", "story", session.story)
	return session.story
