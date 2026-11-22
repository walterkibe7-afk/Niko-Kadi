class_name GameState
extends RefCounted

var draw_pile: Deck
var discard_pile: Array[Card] = []
var hands: Array[Array] = [[], []]  # 0 = you, 1 = opponent
var current_suit: int
var current_player: int = 0

# --- Pending situations (each one limits what the current player can do) ---
var awaiting_suit_choice: bool = false  # after an Ace, until a suit is chosen
var pending_penalty: int = 0            # stacked 2s and 3s the current player must take or counter
var pending_jump_rank: int = 0          # 11 (J) or 13 (K) while the target may counter or accept
var pending_jump_by: int = -1           # who played the last J/K
var awaiting_answer: bool = false       # after a Q or 8, the same player must answer or pick up
var question_suit: int = -1

# --- Declaration ("Niko Kadi") ---
var declared: Array[bool] = [false, false]  # declared on the play that left them with 1 card
var unlocked: Array[bool] = [false, false]  # opponent has since had a full turn


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


# Is this card legal for the current player right now?
func can_play(card: Card) -> bool:
	# Your last card is locked until you have declared AND the opponent
	# has had a full turn. It must also be a plain card (4-10).
	if hands[current_player].size() == 1 and card.rank != 14:
		if not (card.is_plain() and declared[current_player] and unlocked[current_player]):
			return false

	if pending_jump_rank != 0:
		return card.rank == pending_jump_rank  # J answers J, K answers K
	if card.rank == 14:
		return true  # an Ace goes on anything, and cancels a 2/3 stack
	if pending_penalty > 0:
		return card.rank == 2 or card.rank == 3
	if awaiting_answer:
		return card.suit == question_suit
	return card.suit == current_suit or card.rank == top_card().rank


func has_legal_move(player: int) -> bool:
	if player != current_player:
		return false
	for card in hands[player]:
		if can_play(card):
			return true
	return false


# declare = true when the player pressed "Niko Kadi" with this play
func play_card(player: int, card: Card, declare: bool = false) -> bool:
	if player != current_player or awaiting_suit_choice or not can_play(card):
		return false

	hands[player].erase(card)
	discard_pile.append(card)
	current_suit = card.suit
	awaiting_answer = false

	# A play that leaves exactly 1 card must declare, otherwise the last card stays locked
	declared[player] = hands[player].size() == 1 and declare
	unlocked[player] = false

	match card.rank:
		2, 3:
			pending_penalty += card.rank
			_end_turn(player)
		14:
			if pending_penalty > 0:
				pending_penalty = 0  # the Ace only blocks: no suit choice
				_finish_empty_hand_without_win(player)
				_end_turn(player)
			else:
				awaiting_suit_choice = true
		11, 13:
			pending_jump_rank = card.rank
			pending_jump_by = player
			current_player = 1 - player  # the other player may counter or accept
		12, 8:
			awaiting_answer = true
			question_suit = card.suit
		_:
			_end_turn(player)
	return true


# An Ace (or any special card) can be a player's last card but never wins:
# they pick up 1 card instead.
func _finish_empty_hand_without_win(player: int) -> void:
	if hands[player].is_empty():
		var card := _draw_card()
		if card != null:
			hands[player].append(card)
		declared[player] = false
		unlocked[player] = false


func choose_suit(player: int, suit: int) -> bool:
	if player != current_player or not awaiting_suit_choice:
		return false
	current_suit = suit
	awaiting_suit_choice = false
	# An Ace played as your last card never wins: pick up 1 card instead
	if hands[player].is_empty():
		var card := _draw_card()
		if card != null:
			hands[player].append(card)
		declared[player] = false
		unlocked[player] = false
	_end_turn(player)
	return true


# The target of a J/K gives in: they are skipped and the jumper plays again
func accept_jump(player: int) -> bool:
	if pending_jump_rank == 0 or player != current_player:
		return false
	var jumper := pending_jump_by
	pending_jump_rank = 0
	pending_jump_by = -1
	# The target had their chance to counter, so a declared jumper may now finish
	if declared[jumper]:
		unlocked[jumper] = true
	current_player = jumper
	return true


# Pick up 1 card, or the whole penalty stack. Also ends an unanswered question.
func pick_up(player: int) -> void:
	if player != current_player or awaiting_suit_choice or pending_jump_rank != 0:
		return
	var count := 1
	if pending_penalty > 0:
		count = pending_penalty
		pending_penalty = 0
	for i in count:
		var card := _draw_card()
		if card != null:
			hands[player].append(card)
	awaiting_answer = false
	declared[player] = false  # picking up voids a declaration
	unlocked[player] = false
	_end_turn(player)


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


# A real turn is over: pass play on. If the opponent had declared,
# they have now seen a full turn, so their last card unlocks.
func _end_turn(player: int) -> void:
	var other := 1 - player
	if declared[other]:
		unlocked[other] = true
	current_player = other


func is_game_over() -> int:
	# 0 = not over, 1 = you win, 2 = opponent wins
	if awaiting_suit_choice:
		return 0
	if hands[0].is_empty():
		return 1
	if hands[1].is_empty():
		return 2
	return 0
