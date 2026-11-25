class_name GameState
extends RefCounted

const MAX_HAND := 10
var over_limit_player: int = -1  # who went over the limit, -1 = nobody

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
var awaiting_call: bool = false  # after two Aces, until an exact card is called
var call_rank: int = 0           # called card's number, 0 = no active call
var call_suit: int = -1          # -1 = no active call
var print_log: bool = true

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


func can_win_with_last_card(player: int) -> bool:
	return declared[player] and unlocked[player] and not hands[1 - player].is_empty()


# Declare on your own turn while holding one plain card. The opponent has already
# had a full turn since you got down to this card, so it unlocks immediately.
func declare_now(player: int) -> void:
	assert(current_player == player, "declare_now is for your own turn")
	assert(not awaiting_answer, "Can't declare in the middle of a Q/8 answer")
	assert(hands[player].size() == 1 and hands[player][0].is_plain(), "Declaring needs exactly one plain card")
	assert(not declared[player], "Already declared")
	declared[player] = true
	unlocked[player] = true
	_log("%s declared NIKO KADI! (1 card left)" % _who(player))


# Declare after the play that left you with 1 plain card, before the opponent moves.
func declare_late(player: int) -> void:
	assert(current_player != player, "Late declaration must happen before the opponent acts")
	assert(hands[player].size() == 1 and hands[player][0].is_plain(), "Late declaration needs exactly one plain card")
	assert(not declared[player], "Already declared")
	declared[player] = true
	_log("%s declared NIKO KADI! (1 card left)" % _who(player))


# Is this card legal for the current player right now?
func can_play(card: Card) -> bool:
	if pending_jump_rank != 0:
		return card.rank == pending_jump_rank  # J answers J, K answers K
	if call_rank != 0:
		return card.rank == 14 or (card.rank == call_rank and card.suit == call_suit)
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
	if player != current_player or awaiting_suit_choice or awaiting_call or cards.is_empty():
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
	var can_win: bool = can_win_with_last_card(player)

	var suit_before: int = current_suit
	var was_calling: bool = call_rank != 0
	for card in cards:
		hands[player].erase(card)
		discard_pile.append(card)
	# Only a plain card played as the very last card wins
	if hands[player].is_empty() and cards[0].is_plain() and can_win:
		winner = player + 1
	current_suit = cards.back().suit
	awaiting_answer = false
	call_rank = 0
	call_suit = -1

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
			if was_calling:
				if count >= 2:
					awaiting_suit_choice = true  # two Aces cancel the call, suit only
					_log("%s countered the call with %s (choosing suit, hand=%d)" % [_who(player), played_str, rem])
				else:
					current_suit = suit_before  # one Ace removes the number, called suit stays
					_log("%s countered the call with %s (number removed, suit stays %s, hand=%d)" % [_who(player), played_str, _suit_sym(current_suit), rem])
					_end_turn(player)
			elif pending_penalty > 0:
				pending_penalty = 0  # the first Ace blocks
				if count >= 2:
					awaiting_suit_choice = true  # the second Ace changes the suit
					_log("%s played %s (blocked penalty, choosing suit, hand=%d)" % [_who(player), played_str, rem])
				else:
					current_suit = suit_before  # a blocking Ace is transparent
					_log("%s played %s (blocked penalty, suit stays %s, hand=%d)" % [_who(player), played_str, _suit_sym(current_suit), rem])
					_end_turn(player)
			elif count >= 2:
				awaiting_call = true  # two Aces call an exact card
				_log("%s played %s (calling an exact card, hand=%d)" % [_who(player), played_str, rem])
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
	_declare_after_choice(player, declare)
	_end_turn(player)
	return true


func _declare_after_choice(player: int, declare: bool) -> void:
	if hands[player].size() == 1 and declare and hands[player][0].is_plain() and not declared[player]:
		declared[player] = true
		_log("%s declared NIKO KADI! (1 card left)" % _who(player))


func choose_call(player: int, rank: int, suit: int, declare: bool) -> bool:
	if player != current_player or not awaiting_call:
		return false
	assert(rank >= 2 and rank <= 13, "Called rank must be 2-13")
	assert(suit >= 0 and suit <= 3, "Called suit must be 0-3")
	_log("%s called %s%s" % [_who(player), rank_str(rank), _suit_sym(suit)])
	call_rank = rank
	call_suit = suit
	current_suit = suit
	awaiting_call = false
	_declare_after_choice(player, declare)
	_end_turn(player)
	return true


func rank_str(rank: int) -> String:
	match rank:
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"
		_: return str(rank)


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
	if player != current_player or awaiting_suit_choice or awaiting_call or pending_jump_rank != 0:
		return
	var count := 1
	var reason := "draw"
	if pending_penalty > 0:
		count = pending_penalty
		pending_penalty = 0
		reason = "penalty"
	elif awaiting_answer:
		reason = "unanswered Q/8"
	elif call_rank != 0:
		reason = "called card"
	for i in count:
		hands[player].append(_draw_card())
	awaiting_answer = false
	call_rank = 0
	call_suit = -1
	declared[player] = false  # picking up voids a declaration
	unlocked[player] = false
	_log("%s picked up %d (%s) -> hand=%d" % [_who(player), count, reason, hands[player].size()])
	if hands[player].size() > MAX_HAND:
		over_limit_player = player
		winner = 2 - player
		_log("%s went over %d cards: %s wins" % [_who(player), MAX_HAND, _who(1 - player)])
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
	if player != current_player or awaiting_suit_choice or awaiting_call or cards.is_empty():
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
	if print_log:
		print("[SYS] " + entry)
	log_added.emit(entry)
