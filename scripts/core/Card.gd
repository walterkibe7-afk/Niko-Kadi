class_name Card
extends RefCounted

enum Suit { HEARTS, DIAMONDS, CLUBS, SPADES }

# rank: 2-10, 11 = J, 12 = Q, 13 = K, 14 = A
var rank: int
var suit: int

func _init(p_rank: int, p_suit: int) -> void:
	rank = p_rank
	suit = p_suit

# Plain finishing cards are 4, 5, 6, 7, 9, 10
func is_plain() -> bool:
	return rank in [4, 5, 6, 7, 9, 10]

func is_special() -> bool:
	return not is_plain()

func _to_string() -> String:
	var names := {11: "J", 12: "Q", 13: "K", 14: "A"}
	var suits := ["♥", "♦", "♣", "♠"]
	return str(names.get(rank, rank)) + suits[suit]
