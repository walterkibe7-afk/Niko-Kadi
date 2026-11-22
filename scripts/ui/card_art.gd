class_name CardArt
extends RefCounted

# The only place card-art filenames are handled.
# Kenney playing cards PNG pack layout:
#   Cards (large)/card_<suit>_<rank>.png   suit: hearts/diamonds/clubs/spades
#                                            rank: 02-10, J, Q, K, A
#   Cards (large)/card_back.png
const ASSET_DIR := "res://assets/cards/kenney-playing-cards/PNG/Cards (large)"
const SUIT_NAMES := ["hearts", "diamonds", "clubs", "spades"]

# rank: 2-10 -> "02"-"10", 11 -> "J", 12 -> "Q", 13 -> "K", 14 -> "A"
static func _rank_name(rank: int) -> String:
	match rank:
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"
		_: return str(rank).pad_zeros(2)

# Returns the texture path for a Card face (rank 2-14, suit 0-3 = hearts, diamonds, clubs, spades).
static func card_path(card: Card) -> String:
	return "%s/card_%s_%s.png" % [
		ASSET_DIR,
		SUIT_NAMES[card.suit],
		_rank_name(card.rank),
	]

# Returns the texture path for the card back.
static func back_path() -> String:
	return "%s/card_back.png" % ASSET_DIR
