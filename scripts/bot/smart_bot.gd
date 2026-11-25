class_name SmartBot
extends SimpleBot

# At this hand size, dumping cards starts to matter more than keeping specials back.
const NEAR_LIMIT := 8
const NEAR_LIMIT_DUMP := 12.0
const NORMAL_DUMP := 4.0

# With this many cards, a stack of this size is no longer worth countering.
const BLOCK_HAND := 7
const BLOCK_STACK := 4


func step(game: GameState, player: int) -> void:
	assert(game.current_player == player and game.is_game_over() == 0, "step called out of turn")
	var hand: Array = game.hands[player]

	if game.awaiting_call:
		# Call a card the opponent cannot hold: one of ours, else one already discarded.
		# The called suit becomes the suit in play, so call one we can follow ourselves.
		var candidates: Array = _call_candidates(game, player)
		assert(not candidates.is_empty(), "Bot has no card to call")
		var pick: Card = null
		var scores := _suit_scores(game, player, hand)
		var best := -INF
		for c in candidates:
			var value: float = scores[c.suit] + (0.2 if c.is_plain() else 0.0)
			if value > best:
				best = value
				pick = c
		assert(pick != null, "no call candidate scored")
		assert(game.choose_call(player, pick.rank, pick.suit, hand.size() == 1), "choose_call rejected")

	elif game.awaiting_suit_choice:
		assert(game.choose_suit(player, _best_suit(game, player, hand), hand.size() == 1), "choose_suit rejected")

	elif game.pending_jump_rank != 0:
		# Answering a jump: shed a lot only when the hand is already big, otherwise
		# spend the single J/K and keep the rest for the next one.
		var plays := _legal_plays(game, player)
		if plays.is_empty():
			assert(game.accept_jump(player), "accept_jump rejected")
		else:
			_commit(game, player, _best_play(game, player, plays, _score_response))

	elif game.call_rank != 0:
		_answer_call(game, player)

	else:
		var plays := _legal_plays(game, player)
		if plays.is_empty():
			game.pick_up(player)
		else:
			_commit(game, player, _best_play(game, player, plays, _score_play))


func _call_candidates(game: GameState, player: int) -> Array:
	var candidates: Array = []
	for c in game.hands[player]:
		if c.rank >= 2 and c.rank <= 13:
			candidates.append(c)
	if candidates.is_empty():
		for c in game.discard_pile:
			if c.rank >= 2 and c.rank <= 13:
				candidates.append(c)
	return candidates


func _answer_call(game: GameState, player: int) -> void:
	var hand: Array = game.hands[player]
	var legal := _legal_plays(game, player)

	var exact := legal.filter(func(p): return p[0].rank == game.call_rank and p[0].suit == game.call_suit)
	if not exact.is_empty():
		_commit(game, player, _best_play(game, player, exact, _score_response))
		return

	var ace_plays := legal.filter(func(p): return p[0].rank == 14)
	if ace_plays.is_empty():
		game.pick_up(player)
		return

	# Two Aces cancel the call outright and hand us the suit to choose;
	# one Ace removes the number and the called suit stays in play.
	var pairs := ace_plays.filter(func(p): return p.size() == 2)
	var singles := ace_plays.filter(func(p): return p.size() == 1)
	if not pairs.is_empty() and hand.size() >= 3:
		_commit(game, player, pairs[0])
	else:
		assert(not singles.is_empty(), "Ace answer: no single Ace play")
		_commit(game, player, singles[0])


# Cards of `hand` that are not in `cards`
func _remaining(hand: Array, cards: Array) -> Array:
	var rem: Array = []
	for c in hand:
		if not (c in cards):
			rem.append(c)
	return rem


# Every legal play: one card, or a chain of same-rank cards. A chain only has to be
# legal as its first card, and only its last card sets the suit, so those two choices
# are what makes one chain different from another.
func _legal_plays(game: GameState, player: int) -> Array:
	var hand: Array = game.hands[player]
	var by_rank := {}
	for c in hand:
		if not by_rank.has(c.rank):
			by_rank[c.rank] = []
		by_rank[c.rank].append(c)

	var plays: Array = []
	for rank in by_rank:
		var group: Array = by_rank[rank]
		for c in group:
			if game.can_play(c):
				# Don't play a non-winning last card (empties hand without winning).
				if hand.size() == 1 and not (c.is_plain() and game.can_win_with_last_card(player)):
					continue
				var single: Array[Card] = [c]
				plays.append(single)
		var longest: int = mini(group.size(), hand.size() - 1)
		if longest < 2:
			continue
		var n := group.size()
		for mask in range(1, 1 << n):
			var subset: Array = []
			for i in n:
				if mask & (1 << i):
					subset.append(group[i])
			if subset.size() < 2 or subset.size() > longest:
				continue
			for first in subset:
				if not game.can_play(first):
					continue
				for last in subset:
					if last == first:
						continue
					var chain: Array[Card] = [first]
					for c in subset:
						if c != first and c != last:
							chain.append(c)
					chain.append(last)
					plays.append(chain)
	return plays


func _best_play(game: GameState, player: int, plays: Array, scorer: Callable) -> Array:
	assert(not plays.is_empty(), "_best_play called with no plays")
	var best: Array = plays[0]
	var best_key: Array = scorer.call(game, player, best)
	for p in plays.slice(1):
		var key: Array = scorer.call(game, player, p)
		if _key_beats(key, best_key):
			best = p
			best_key = key
	return best


# Lexicographic compare: an earlier entry always outranks any later one.
func _key_beats(a: Array, b: Array) -> bool:
	assert(a.size() == b.size(), "score keys must be the same length")
	for i in a.size():
		if a[i] != b[i]:
			return a[i] > b[i]
	return false  # equal keys: first play found wins


func _commit(game: GameState, player: int, cards: Array) -> void:
	var declare: bool = game.hands[player].size() - cards.size() == 1
	assert(game.play_cards(player, cards, declare), "Bot play was rejected by GameState")


# Jump answers and called cards: declaring Niko Kadi first, then how much is shed.
func _score_response(game: GameState, player: int, cards: Array) -> Array:
	var hand: Array = game.hands[player]
	var rem := _remaining(hand, cards)
	var key := 0.0
	if game.can_declare_on_play(player, cards):
		key += 1.0
	var shed: float = cards.size() if hand.size() >= NEAR_LIMIT else -cards.size()
	return [key, shed, _suit_scores(game, player, rem)[cards.back().suit]]


func _score_play(game: GameState, player: int, cards: Array) -> Array:
	var hand: Array = game.hands[player]
	var rank: int = cards[0].rank
	var rem := _remaining(hand, cards)
	var end_suit: int = cards.back().suit
	var rem_scores := _suit_scores(game, player, rem)
	var near_limit: bool = hand.size() >= NEAR_LIMIT

	if rem.is_empty():
		if cards[0].is_plain() and game.can_win_with_last_card(player):
			return [1000.0, 0.0, 0.0]
		return [-900.0, 0.0, 0.0]  # emptying the hand without winning loses nothing but is never a plan

	var key := 0.0
	if game.can_declare_on_play(player, cards):
		key += 200.0
		match rank:
			14: key += 20.0
			11, 13: key += 15.0
			2, 3: key += 10.0

	# A 2/3 stack: counter to pass it back, unless a hand this full facing a stack this
	# big would rather end it with an Ace than risk having to pick it up.
	if game.pending_penalty > 0:
		var take_the_risk: bool = hand.size() >= BLOCK_HAND and game.pending_penalty >= BLOCK_STACK
		if rank == 2 or rank == 3:
			key += 10.0 if take_the_risk else 50.0 + cards.size() * 5.0
		else:
			key += 50.0 if take_the_risk else 20.0
			if cards.size() > 1 and not near_limit:
				key -= 15.0  # one Ace is enough to block
		return [key, rem_scores[end_suit], float(cards.size())]

	# Answering a Q/8 question: everything is better than an unanswered Q/8.
	if game.awaiting_answer:
		match rank:
			14: key += 10.0 if cards.size() == 1 else 2.0
			11, 13: key += 50.0
			2, 3: key += 40.0
			12, 8: key += 30.0 if _has_answer_for(rem, end_suit) else 5.0
			_: key += 80.0
		return [key, cards.size() * 2.0, rem_scores[end_suit]]

	var opp_low: bool = game.hands[1 - player].size() <= 2
	if cards[0].is_plain():
		key += 80.0
	elif rank == 12 or rank == 8:
		key += 75.0 if _has_answer_for(rem, end_suit) else 15.0
	elif rank == 11 or rank == 13:
		key += 45.0 if (opp_low or near_limit) else 35.0
		if cards.size() > 1 and not near_limit:
			key -= 5.0
	elif rank == 2 or rank == 3:
		key += 40.0 if (opp_low or near_limit) else 25.0
	elif cards.size() >= 2:
		# Two Aces call an exact card, which is worth it only when it can hurt someone.
		key += 22.0 if (opp_low or near_limit) else 4.0
	else:
		key += 8.0  # a lone Ace is the best answer to almost anything: keep it

	# Only a plain card can win, so don't spend our last one while we still hold one.
	if rank != 14 and not _has_plain(rem) and _has_plain(hand):
		key -= 45.0
	# ...but never end up holding a lone special, since it cannot be declared.
	if rem.size() == 1 and not rem[0].is_plain():
		key -= 20.0

	key += cards.size() * (NEAR_LIMIT_DUMP if near_limit else NORMAL_DUMP)
	return [key, rem_scores[end_suit], -float(rem.size())]


func _has_plain(cards: Array) -> bool:
	for c in cards:
		if c.is_plain():
			return true
	return false


# After a Q/8 we need a card of that suit that does not ask another question.
func _has_answer_for(cards: Array, suit: int) -> bool:
	for c in cards:
		if c.suit == suit and c.rank != 14 and c.rank != 12 and c.rank != 8:
			return true
	return false


func _suit_scores(game: GameState, player: int, cards: Array) -> Array:
	var scores := [0.0, 0.0, 0.0, 0.0]
	for c in cards:
		if c.rank == 14:
			scores[c.suit] += 0.25  # an Ace is playable whatever the suit
		else:
			scores[c.suit] += 1.0
			if c.is_plain():
				scores[c.suit] += 0.15
	# A suit we just picked up in is the one we are least able to follow again.
	for s in 4:
		scores[s] -= 0.7 * game.pickup_memory[player][s]
	return scores


func _best_suit(game: GameState, player: int, cards: Array) -> int:
	if cards.size() == 1:
		return cards[0].suit  # our last card has to be reachable
	var scores := _suit_scores(game, player, cards)
	var best_suit := 0
	var best := -999.0
	for s in 4:
		if scores[s] > best:
			best = scores[s]
			best_suit = s
	return best_suit
