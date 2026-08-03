extends RefCounted

const ClaimResolver = preload("res://src/mahjong/domain/claim_resolver.gd")
const FrontierHandValidator = preload("res://src/mahjong/domain/frontier_hand_validator.gd")
const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")
const MatchFlow = preload("res://src/mahjong/domain/match_flow.gd")
const MatchRuleset = preload("res://src/mahjong/domain/match_ruleset.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")
const WallBuilder = preload("res://src/mahjong/domain/wall_builder.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var wall := WallBuilder.build_frontier_wall(55)
	if wall.size() != WallBuilder.FRONTIER_WALL_SIZE:
		failures.append("Frontier Rules must build a deterministic 136-tile wall")
	for count in WallBuilder.brand_counts(wall).values():
		if int(count) < 22 or int(count) > 23:
			failures.append("Frontier Brand allocation must be balanced at 22 or 23 tiles")
			break
	var flow = MatchFlow.new(56)
	flow.configure_ruleset(MatchRuleset.FRONTIER)
	flow.start_match()
	if flow.current_hand().size() != 14 or flow.wall.size() != 109:
		failures.append("the Frontier dealer must begin with fourteen tiles after two thirteen-tile deals")
	if not FrontierHandValidator.is_winning_hand(_quad_hand()):
		failures.append("a Frontier hand with four groups, a pair, and a quad must be legal")
	var quad_claim := ClaimResolver.resolve(_tile(&"east", 0), [{"player": 0, "kind": "frontier_quad", "equipped": [&"green", &"purple"], "tiles": [_tile(&"east", 0), _tile(&"east", 0), _tile(&"east", 0)]}])
	if quad_claim.get("kind", "") != "frontier_quad":
		failures.append("Frontier Rules must accept a four-of-a-kind public claim")
	return failures


func _tile(suit: StringName, rank: int) -> RefCounted:
	return MahjongTile.new(TileIdentity.new(suit, rank), &"purple")


func _quad_hand() -> Array:
	return [_tile(&"east", 0), _tile(&"east", 0), _tile(&"east", 0), _tile(&"east", 0), _tile(&"dots", 1), _tile(&"dots", 2), _tile(&"dots", 3), _tile(&"red", 0), _tile(&"red", 0), _tile(&"red", 0), _tile(&"bamboo", 4), _tile(&"bamboo", 5), _tile(&"bamboo", 6), _tile(&"white", 0), _tile(&"white", 0)]
