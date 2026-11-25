class_name SimpleBot
extends RefCounted

# How often the easy bot ignores its own rules below. At 0.0 it plays exactly as
# written; the game raises it for a gentler opponent.
var mistake_rate: float = 0.0

# One action for `player`. The live game calls this through take_turn (with delays),
# and headless simulations call it directly for both seats.
func step(game: GameState, player: int) -> void:
	assert(game.current_player == player and game.is_game_over() == 0, "step called out of turn")
	var hand: Array = game.hands[player]

	if game.awaiting_call:
		# Call a card this bot can't have: from its own hand, else from the discard pile
		var candidates: Array[Card] = []
		for c in hand:
			if c.rank >= 2 and c.rank <= 13:
				candidates.append(c)
		if candidates.is_empty():
			for c in game.discard_pile:
				if c.rank >= 2 and c.rank <= 13:
					candidates.append(c)
		assert(not candidates.is_empty(), "Bot has no card to call")
		var pick: Card = candidates[randi() % candidates.size()] if _slip() else candidates[0]
		var ok: bool = game.choose_call(player, pick.rank, pick.suit, hand.size() == 1)
		assert(ok, "choose_call rejected")

	elif game.awaiting_suit_choice:
		var counts := [0, 0, 0, 0]
		for c in hand:
			counts[c.suit] += 1
		var best_suit := 0
		var max_count := -1
		for s in 4:
			if counts[s] > max_count:
				max_count = counts[s]
				best_suit = s
		if _slip():
			best_suit = randi() % 4
		var ok := game.choose_suit(player, best_suit, hand.size() == 1)
		assert(ok, "choose_suit rejected")

	elif game.pending_jump_rank != 0:
		var card: Card = _first_legal(game, player)
		if card == null:
			var ok := game.accept_jump(player)
			assert(ok, "accept_jump rejected")
		else:
			_play(game, player, card, false)

	elif game.call_rank != 0:
		var exact: Card = null
		var aces: Array[Card] = []
		for c in hand:
			if c.rank == game.call_rank and c.suit == game.call_suit:
				exact = c
			elif c.rank == 14:
				aces.append(c)
		if exact != null and game.can_play(exact):
			_play(game, player, exact, false)
		elif not aces.is_empty() and game.can_play(aces[0]):
			# With 2+ Aces, half the time cancel the call (suit only), else remove the number
			_play(game, player, aces[0], randi() % 2 == 0)
		else:
			game.pick_up(player)

	else:
		var card: Card = _pick_card(game, player)
		if card == null:
			game.pick_up(player)
		else:
			_play(game, player, card, true)


func take_turn(game: GameState, tree: SceneTree, on_step: Callable) -> void:
	assert(on_step.is_valid(), "take_turn requires a step callback")
	while game.current_player == 1 and game.is_game_over() == 0:
		await tree.create_timer(1.0).timeout
		if game.current_player != 1 or game.is_game_over() != 0:
			break
		step(game, 1)
		on_step.call()


func _first_legal(game: GameState, player: int) -> Card:
	for card in game.hands[player]:
		if game.can_play(card):
			return card
	return null


# The first legal card the hand offers, unless the easy bot slips and takes another
func _pick_card(game: GameState, player: int) -> Card:
	var card := _first_legal(game, player)
	if card == null or not _slip():
		return card
	var legal: Array[Card] = []
	for c in game.hands[player]:
		if game.can_play(c):
			legal.append(c)
	return legal[randi() % legal.size()]


func _slip() -> bool:
	return mistake_rate > 0.0 and randf() < mistake_rate


# Play `card`, optionally together with every other card of the same rank
func _play(game: GameState, player: int, card: Card, chain: bool) -> void:
	var hand: Array = game.hands[player]
	var cards: Array[Card] = [card]
	if chain:
		for c in hand:
			if c != card and c.rank == card.rank:
				cards.append(c)
		while cards.size() > 1 and cards.size() >= hand.size():
			cards.pop_back()  # a chain can never empty the hand
	var declare: bool = hand.size() - cards.size() == 1
	var ok := game.play_cards(player, cards, declare)
	assert(ok, "Bot play was rejected by GameState")
