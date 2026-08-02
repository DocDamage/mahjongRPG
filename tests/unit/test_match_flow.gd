extends RefCounted

const HighNoonState = preload("res://src/mahjong/domain/high_noon_state.gd")
const MatchFlow = preload("res://src/mahjong/domain/match_flow.gd")
const MahjongTile = preload("res://src/mahjong/domain/mahjong_tile.gd")
const TileIdentity = preload("res://src/mahjong/domain/tile_identity.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var flow = MatchFlow.new(811)
	flow.start_hand(0)
	if flow.current_hand().size() != 11 or flow.phase != MatchFlow.Phase.DISCARD:
		failures.append("the dealer must begin Trail Rules with eleven tiles to discard")
	if flow.discard_at(0) != OK or flow.turn_player != 1 or flow.phase != MatchFlow.Phase.DRAW:
		failures.append("a legal discard should advance the turn")
	if flow.draw() != OK or flow.current_hand().size() != 11:
		failures.append("the next player should draw back to eleven tiles")
	var replay = flow.replay.snapshot()
	if replay["seed"] != 811 or replay["actions"].size() < 3:
		failures.append("match actions must be captured in the deterministic replay log")
	var high_noon = HighNoonState.new()
	if not high_noon.declare(_waiting_hand()):
		failures.append("a ten-tile waiting hand should permit High Noon")
	else:
		high_noon.consume_draw()
		high_noon.consume_draw()
		if not high_noon.active:
			failures.append("High Noon should remain active through two draws")
		high_noon.consume_draw()
		if high_noon.active:
			failures.append("High Noon should expire after its third draw")
	return failures


func _tile(suit: StringName, rank: int) -> RefCounted:
	return MahjongTile.new(TileIdentity.new(suit, rank), &"blue")


func _waiting_hand() -> Array:
	return [
		_tile(&"dots", 1), _tile(&"dots", 2), _tile(&"dots", 3),
		_tile(&"bamboo", 4), _tile(&"bamboo", 5), _tile(&"bamboo", 6),
		_tile(&"east", 0), _tile(&"east", 0), _tile(&"east", 0),
		_tile(&"red", 0),
	]
