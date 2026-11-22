class_name GameState
extends RefCounted

var draw_pile: Deck
var discard_pile: Array[Card] = []
var hands: Array[Array] = [[], []]  # 0 = you, 1 = opponent
var current_suit: int
var current_player: int = 0  # 0 = you, 1 = opponent
var awaiting_suit_choice: bool = false  # true after an Ace, until a suit is chosen

func start_game() -> void:
	draw_pile = Deck.new()
	draw_pile.build()
	draw_pile.shuffle()

	for i in 4:
		for p in 2:
			hands[p].append(draw_pile.draw())

	# Starter card: if it's special, tuck it at the bottom and redraw
	var starter := draw_pile.draw()
	while starter.is_special():
		draw_pile.cards.push_front(starter)
		starter = draw_pile.draw()

	discard_pile.append(starter)
	current_suit = starter.suit
	current_player = 0

func top_card() -> Card:
	return discard_pile.back()

# Basic rule: match the suit in play, or the number of the top card
func can_play(card: Card) -> bool:
	return card.suit == current_suit or card.rank == top_card().rank

func play_card(player: int, card: Card) -> bool:
	if player != current_player or awaiting_suit_choice or not can_play(card):
		return false
	hands[player].erase(card)
	discard_pile.append(card)
	current_suit = card.suit
	if card.rank == 14:
		awaiting_suit_choice = true  # same player must now choose a suit
	else:
		_next_turn()
	return true

func choose_suit(player: int, suit: int) -> bool:
	if player != current_player or not awaiting_suit_choice:
		return false
	current_suit = suit
	awaiting_suit_choice = false
	_next_turn()
	return true

func pick_up(player: int) -> void:
	if player != current_player or awaiting_suit_choice:
		return
	var card := _draw_card()
	if card != null:
		hands[player].append(card)
	_next_turn()

func _draw_card() -> Card:
	if draw_pile.cards.is_empty():
		_reshuffle()
	return draw_pile.draw()

# Keep the top card in play, shuffle the rest back into the draw pile
func _reshuffle() -> void:
	var top: Card = discard_pile.pop_back()
	draw_pile.cards.append_array(discard_pile)
	discard_pile.clear()
	discard_pile.append(top)
	draw_pile.shuffle()

func _next_turn() -> void:
	current_player = 1 - current_player

func is_game_over() -> int:
	# Returns 0 if not over, 1 if player 0 wins, 2 if player 1 wins
	if hands[0].is_empty():
		return 1
	if hands[1].is_empty():
		return 2
	return 0