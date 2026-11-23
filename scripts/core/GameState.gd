class_name GameState
extends RefCounted

signal log_added(entry: String)

var log_entries: Array[String] = []

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
var winner: int = 0  # 0 = none, 1 = you, 2 = opponent


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

	_log("Game started | Starter: %s | Suit: %s | Hand sizes: You=%d, Opp=%d" % [
		starter, _suit_sym(current_suit), hands[0].size(), hands[1].size()
	])


func top_card() -> Card:
	return discard_pile.back()


func has_declared(player: int) -> bool:
	return declared[player] and hands[player].size() == 1


# Is this card legal for the current player right now?
func can_play(card: Card) -> bool:
	# A plain last card (4-10) is locked until you have declared, the opponent
	# has had a full turn, and the opponent still has cards. Special cards can
	# still be played as a last card, but they never win.
	if hands[current_player].size() == 1 and card.is_plain():
		var opponent_has_cards: bool = not hands[1 - current_player].is_empty()
		if not (declared[current_player] and unlocked[current_player] and opponent_has_cards):
			return false

	if pending_jump_rank != 0:
		return card.rank == pending_jump_rank  # J answers J, K answers K
	if card.rank == 14:
		return true  # an Ace goes on anything and cancels a 2/3 stack
	if pending_penalty > 0:
		var is_pick_card: bool = card.rank == 2 or card.rank == 3
		return is_pick_card and (card.suit == current_suit or card.rank == top_card().rank)
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


func play_card(player: int, card: Card, declare: bool) -> bool:
	var single: Array[Card] = [card]
	return play_cards(player, single, declare)


# cards = the play order. The first must be legal; all must share one rank.
# The last card played sets the suit in play.
func play_cards(player: int, cards: Array[Card], declare: bool) -> bool:
	if player != current_player or awaiting_suit_choice or cards.is_empty():
		return false
	var rank: int = cards[0].rank
	for card in cards:
		if card.rank != rank or cards.count(card) != 1 or not hands[player].has(card):
			return false
	if cards.size() > 1 and cards.size() >= hands[player].size():
		return false  # a chain can never empty your hand
	if not can_play(cards[0]):
		return false

	# Enforce declaration rules here, not only in the UI: callers (including the
	# bot) may pass declare=true for an ineligible last card such as a Q.
	var valid_declare := declare and can_declare_on_play(player, cards)

	for card in cards:
		hands[player].erase(card)
		discard_pile.append(card)
	# Only a plain card played as the very last card wins
	if hands[player].is_empty() and cards[0].is_plain():
		winner = player + 1
	current_suit = cards.back().suit
	awaiting_answer = false

	# A play that leaves exactly 1 card must declare, otherwise the last card stays locked
	declared[player] = hands[player].size() == 1 and valid_declare
	unlocked[player] = false

	var count: int = cards.size()
	var played_str := _cards_str(cards)
	var rem := hands[player].size()
	match rank:
		2, 3:
			pending_penalty += rank * count
			_log("%s played %s (penalty stack=%d, hand=%d)" % [_who(player), played_str, pending_penalty, rem])
			_end_turn(player)
		14:
			if pending_penalty > 0:
				pending_penalty = 0  # the first Ace blocks
				if count >= 2:
					awaiting_suit_choice = true  # the second Ace changes the suit
					_log("%s played %s (blocked penalty, choosing suit, hand=%d)" % [_who(player), played_str, rem])
				else:
					_log("%s played %s (blocked penalty, hand=%d)" % [_who(player), played_str, rem])
					_end_turn(player)
			else:
				awaiting_suit_choice = true
				_log("%s played %s (choosing suit, hand=%d)" % [_who(player), played_str, rem])
		11, 13:
			pending_jump_rank = rank
			pending_jump_by = player
			_log("%s played %s (jump pending, hand=%d)" % [_who(player), played_str, rem])
			current_player = 1 - player  # the other player may counter or accept
		12, 8:
			awaiting_answer = true
			question_suit = current_suit
			_log("%s played %s (awaiting %s answer, hand=%d)" % [_who(player), played_str, _suit_sym(question_suit), rem])
		_:
			_log("%s played %s (hand=%d)" % [_who(player), played_str, rem])
			_end_turn(player)

	if hands[player].is_empty() and winner == 0:
		_log("%s is out of cards without winning" % _who(player))
	if declared[player]:
		_log("%s declared NIKO KADI! (1 card left)" % _who(player))
	return true


func choose_suit(player: int, suit: int, declare: bool) -> bool:
	if player != current_player or not awaiting_suit_choice:
		return false
	_log("%s chose suit %s" % [_who(player), _suit_sym(suit)])
	current_suit = suit
	awaiting_suit_choice = false
	# Declaring here counts as declaring on the Ace play, but only if the remaining
	# card is a plain finishing card (special cards never win). Skip the log if the
	# Ace play already declared, so one declaration is not announced twice.
	if hands[player].size() == 1 and declare and hands[player][0].is_plain() and not declared[player]:
		declared[player] = true
		_log("%s declared NIKO KADI! (1 card left)" % _who(player))
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
	_log("%s accepted skip -> %s plays again" % [_who(player), _who(jumper)])
	return true


# Pick up 1 card, or the whole penalty stack. Also ends an unanswered question.
func pick_up(player: int) -> void:
	if player != current_player or awaiting_suit_choice or pending_jump_rank != 0:
		return
	var count := 1
	var reason := "draw"
	if pending_penalty > 0:
		count = pending_penalty
		pending_penalty = 0
		reason = "penalty"
	elif awaiting_answer:
		reason = "unanswered Q/8"
	for i in count:
		hands[player].append(_draw_card())
	awaiting_answer = false
	declared[player] = false  # picking up voids a declaration
	unlocked[player] = false
	_log("%s picked up %d (%s) -> hand=%d" % [_who(player), count, reason, hands[player].size()])
	_end_turn(player)


func _draw_card() -> Card:
	if draw_pile.cards.is_empty():
		_reshuffle()
	var card: Card = draw_pile.draw()
	assert(card != null, "No cards left to draw")
	return card


# Keep the top card in play, shuffle the rest back into the draw pile
func _reshuffle() -> void:
	var recycled: int = maxi(0, discard_pile.size() - 1)
	var top: Card = discard_pile.pop_back()
	draw_pile.cards.append_array(discard_pile)
	discard_pile.clear()
	discard_pile.append(top)
	draw_pile.shuffle()
	_log("Reshuffled %d discard cards into draw pile" % recycled)


# A real turn is over: pass play on. If the opponent had declared,
# they have now seen a full turn, so their last card unlocks.
func _end_turn(player: int) -> void:
	var other := 1 - player
	if declared[other]:
		unlocked[other] = true
		_log("%s's Niko Kadi unlocked!" % _who(other))
	current_player = other


func is_game_over() -> int:
	return winner


# Checks if playing `cards` is a valid Niko Kadi declaration:
# - Must be current player's turn, no pending suit choice
# - Must leave exactly 1 card in hand
# - That 1 card must be a plain card (4-10), not a special that triggers awaiting_answer
# - All cards must be same rank, legal to play, and not empty the hand
func can_declare_on_play(player: int, cards: Array[Card]) -> bool:
	if player != current_player or awaiting_suit_choice or cards.is_empty():
		return false
	if hands[player].size() - cards.size() != 1:
		return false
	var rank: int = cards[0].rank
	# Q (12) and 8 never win and keep the turn in awaiting_answer, so they cannot carry a declaration
	if rank == 12 or rank == 8:
		return false
	for card in cards:
		if card.rank != rank or cards.count(card) != 1 or not hands[player].has(card):
			return false
	if cards.size() > 1 and cards.size() >= hands[player].size():
		return false
	if not can_play(cards[0]):
		return false
	for c in hands[player]:
		if not (c in cards):
			return c.is_plain()
	return false


# --- Sys log helpers ---
# Public wrapper so UI code can log the final result without calling a private helper.
func log_event(msg: String) -> void:
	_log(msg)


func _who(player: int) -> String:
	return "You" if player == 0 else "Opp"


func _suit_sym(suit: int) -> String:
	return ["♥", "♦", "♣", "♠"][suit]


func _cards_str(cards: Array[Card]) -> String:
	var parts: Array[String] = []
	for c in cards:
		parts.append(str(c))
	return ", ".join(PackedStringArray(parts))


func _log(msg: String) -> void:
	var entry := "[%02d] %s" % [log_entries.size() + 1, msg]
	log_entries.append(entry)
	print("[SYS] " + entry)
	log_added.emit(entry)
