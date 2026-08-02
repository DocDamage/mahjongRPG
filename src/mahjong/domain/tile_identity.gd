extends RefCounted

const NUMBERED_SUITS := [&"bamboo", &"characters", &"dots"]
const HONORS := [&"east", &"south", &"west", &"north", &"red", &"green", &"white"]

var suit: StringName
var rank: int


func _init(next_suit: StringName, next_rank: int = 0) -> void:
	suit = next_suit
	rank = next_rank
	if not is_valid():
		push_error("Invalid tile identity: %s" % key())


func is_valid() -> bool:
	if suit in NUMBERED_SUITS:
		return rank >= 1 and rank <= 9
	return suit in HONORS and rank == 0


func is_numbered() -> bool:
	return suit in NUMBERED_SUITS


func key() -> String:
	return "%s:%d" % [suit, rank]


func equals(other) -> bool:
	return other != null and suit == other.suit and rank == other.rank


static func all_identities() -> Array:
	var identities: Array = []
	for numbered_suit in NUMBERED_SUITS:
		for numbered_rank in range(1, 10):
			identities.append(new(numbered_suit, numbered_rank))
	for honor in HONORS:
		identities.append(new(honor))
	return identities
