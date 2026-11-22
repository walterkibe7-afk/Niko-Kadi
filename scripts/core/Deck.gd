class_name Deck
extends RefCounted

var cards: Array[Card] = []

func build() -> void:
	cards.clear()
	for suit in Card.Suit.values():
		for rank in range(2, 15):
			cards.append(Card.new(rank, suit))

func shuffle() -> void:
	cards.shuffle()

# Draws from the top (the end of the array)
func draw() -> Card:
	return cards.pop_back()
