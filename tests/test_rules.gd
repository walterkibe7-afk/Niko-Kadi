extends SceneTree

# Test helper - creates GameState using the same pattern as bot_sim.gd
func make_game(hands: Array, discard: Array = [], draw: Array = [], 
		current_player: int = 0, current_suit: int = 0,
		awaiting_suit_choice: bool = false, pending_penalty: int = 0,
		pending_jump_rank: int = 0, pending_jump_by: int = -1,
		awaiting_answer: bool = false, question_suit: int = -1,
		awaiting_call: bool = false, call_rank: int = 0, call_suit: int = -1,
		declared: Array = [], unlocked: Array = [],
		pickup_memory: Array = [],
		print_log: bool = false) -> GameState:
	
	# Handle default values
	if hands.size() == 0:
		hands = [[], []]
	if discard.size() == 0:
		discard = []
	if draw.size() == 0:
		draw = []
	if declared.size() == 0:
		declared = [false, false]
	if unlocked.size() == 0:
		unlocked = [false, false]
	if pickup_memory.size() == 0:
		pickup_memory = [[0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0]]
	
	var game := GameState.new()
	game.print_log = print_log
	
	# Create properly typed Array[Array] for hands (bypass default value issue in headless)
	var typed_hands: Array[Array] = [[], []]
	game.set("hands", typed_hands)
	
	# Manually initialize draw pile
	game.draw_pile = Deck.new()
	game.draw_pile.build()
	game.draw_pile.shuffle()
	
	for c in hands[0]:
		game.hands[0].append(c)
	for c in hands[1]:
		game.hands[1].append(c)
	
	# Manually initialize discard pile
	game.discard_pile.clear()
	for c in discard:
		game.discard_pile.append(c)
	if discard.size() > 0:
		game.current_suit = discard[-1].suit
	else:
		game.current_suit = current_suit
	
	# Starter card: if discard is empty, draw a non-special card
	if game.discard_pile.size() == 0:
		var starter := game.draw_pile.draw()
		while starter.is_special():
			game.draw_pile.cards.push_front(starter)
			starter = game.draw_pile.draw()
		game.discard_pile.append(starter)
		game.current_suit = starter.suit
	
	game.current_player = current_player
	game.awaiting_suit_choice = awaiting_suit_choice
	game.pending_penalty = pending_penalty
	game.pending_jump_rank = pending_jump_rank
	game.pending_jump_by = pending_jump_by
	game.awaiting_answer = awaiting_answer
	game.question_suit = question_suit
	game.awaiting_call = awaiting_call
	game.call_rank = call_rank
	game.call_suit = call_suit
	game.declared[0] = declared[0]
	game.declared[1] = declared[1]
	game.unlocked[0] = unlocked[0]
	game.unlocked[1] = unlocked[1]
	game.pickup_memory[0][0] = pickup_memory[0][0]
	game.pickup_memory[0][1] = pickup_memory[0][1]
	game.pickup_memory[0][2] = pickup_memory[0][2]
	game.pickup_memory[0][3] = pickup_memory[0][3]
	game.pickup_memory[1][0] = pickup_memory[1][0]
	game.pickup_memory[1][1] = pickup_memory[1][1]
	game.pickup_memory[1][2] = pickup_memory[1][2]
	game.pickup_memory[1][3] = pickup_memory[1][3]
	
	return game


func c(rank: int, suit: int) -> Card:
	return Card.new(rank, suit)


func run_test(name: String, test_fn: Callable) -> void:
	print("Running: " + name)
	test_fn.call()
	print("  PASS")


# ============================================================
# Rule 4: Turn - play card matching top card's suit or number
# ============================================================

func test_rule4_play_matching_suit_legal() -> void:
	var g := make_game([[c(5, 0)]], [c(7, 0)], [], 0, 0)
	assert(g.can_play(c(5, 0)) == true, "Rule 4: matching suit should be legal")


func test_rule4_play_matching_rank_legal() -> void:
	var g := make_game([[c(7, 1)]], [c(7, 0)], [], 0, 0)
	assert(g.can_play(c(7, 1)) == true, "Rule 4: matching rank should be legal")


func test_rule4_play_non_matching_illegal() -> void:
	var g := make_game([[c(5, 1)]], [c(7, 0)], [], 0, 0)
	assert(g.can_play(c(5, 1)) == false, "Rule 4: non-matching suit/rank should be illegal")


# ============================================================
# Rule 5: 4,5,6,7,9,10 are plain cards
# ============================================================

func test_rule5_plain_cards() -> void:
	for rank in [4, 5, 6, 7, 9, 10]:
		assert(c(rank, 0).is_plain() == true, "Rule 5: rank " + str(rank) + " should be plain")
	for rank in [2, 3, 8, 11, 12, 13, 14]:
		assert(c(rank, 0).is_plain() == false, "Rule 5: rank " + str(rank) + " should be special")


# ============================================================
# Rule 6: 2/3 pick up, penalties stack, 2 can stack on 3
# ============================================================

func test_rule6_play_2_adds_penalty() -> void:
	var g := make_game([[c(2, 0)]], [c(5, 0)], [], 0, 0)
	assert(g.play_cards(0, [c(2, 0)], false) == true, "Rule 6: playing 2 should succeed")
	assert(g.pending_penalty == 2, "Rule 6: penalty should be 2")
	assert(g.current_player == 1, "Rule 6: turn should pass to opponent")


func test_rule6_play_3_adds_penalty() -> void:
	var g := make_game([[c(3, 0)]], [c(5, 0)], [], 0, 0)
	assert(g.play_cards(0, [c(3, 0)], false) == true, "Rule 6: playing 3 should succeed")
	assert(g.pending_penalty == 3, "Rule 6: penalty should be 3")


func test_rule6_penalty_stacks_2_on_2() -> void:
	var g := make_game([[c(2, 1)]], [c(2, 0)], [], 1, 0, false, 2)
	assert(g.play_cards(1, [c(2, 1)], false) == true, "Rule 6: countering 2 with 2 should succeed")
	assert(g.pending_penalty == 4, "Rule 6: penalty should stack to 4")
	assert(g.current_player == 0, "Rule 6: turn should pass back")


func test_rule6_penalty_stacks_3_on_3() -> void:
	var g := make_game([[c(3, 1)]], [c(3, 0)], [], 1, 0, false, 3)
	assert(g.play_cards(1, [c(3, 1)], false) == true, "Rule 6: countering 3 with 3 should succeed")
	assert(g.pending_penalty == 6, "Rule 6: penalty should stack to 6")


func test_rule6_penalty_stacks_2_on_3() -> void:
	var g := make_game([[c(2, 1)]], [c(3, 0)], [], 1, 0, false, 3)
	assert(g.play_cards(1, [c(2, 1)], false) == true, "Rule 6: countering 3 with 2 should succeed (proposed default)")
	assert(g.pending_penalty == 5, "Rule 6: penalty should stack to 5")


func test_rule6_penalty_stacks_3_on_2() -> void:
	var g := make_game([[c(3, 1)]], [c(2, 0)], [], 1, 0, false, 2)
	assert(g.play_cards(1, [c(3, 1)], false) == true, "Rule 6: countering 2 with 3 should succeed (proposed default)")
	assert(g.pending_penalty == 5, "Rule 6: penalty should stack to 5")


func test_rule6_penalty_can_only_be_countered_with_2_or_3() -> void:
	var g := make_game([[c(5, 0)]], [c(2, 0)], [], 1, 0, false, 2)
	assert(g.can_play(c(5, 0)) == false, "Rule 6: plain card cannot counter penalty")
	assert(g.can_play(c(2, 0)) == true, "Rule 6: 2 can counter penalty")
	assert(g.can_play(c(3, 0)) == true, "Rule 6: 3 can counter penalty")


func test_rule6_penalty_must_match_suit_or_rank() -> void:
	var g := make_game([[c(2, 1)]], [c(2, 0)], [], 1, 0, false, 2)
	assert(g.can_play(c(2, 1)) == true, "Rule 6: 2 of different suit but same rank is legal")
	
	var g2 := make_game([[c(2, 2)]], [c(2, 0)], [], 1, 2, false, 2)
	assert(g2.can_play(c(2, 2)) == true, "Rule 6: 2 matching current suit is legal")


# ============================================================
# Rule 7: Ace changes suit, or blocks pick-up penalty (blocks whole stack)
# ============================================================

func test_rule7_ace_on_normal_play_changes_suit() -> void:
	var g := make_game([[c(14, 0)]], [c(5, 0)], [], 0, 0)
	assert(g.can_play(c(14, 0)) == true, "Rule 7: Ace is always playable on normal play")
	assert(g.play_cards(0, [c(14, 0)], false) == true, "Rule 7: playing Ace should succeed")
	assert(g.awaiting_suit_choice == true, "Rule 7: Ace should trigger suit choice")


func test_rule7_ace_blocks_penalty_stack() -> void:
	var g := make_game([[c(14, 0)]], [c(2, 0)], [], 1, 0, false, 2)
	assert(g.can_play(c(14, 0)) == true, "Rule 7: Ace is playable on penalty")
	assert(g.play_cards(1, [c(14, 0)], false) == true, "Rule 7: playing Ace on penalty should succeed")
	assert(g.pending_penalty == 0, "Rule 7: Ace should clear penalty stack")
	assert(g.current_suit == 0, "Rule 7: single blocking Ace keeps suit (transparent)")


func test_rule7_two_aces_on_penalty_blocks_and_changes_suit() -> void:
	var g := make_game([[c(14, 0), c(14, 1)]], [c(2, 0)], [], 1, 0, false, 4)
	assert(g.play_cards(1, [c(14, 0), c(14, 1)], false) == true, "Rule 7: two Aces on penalty should succeed")
	assert(g.pending_penalty == 0, "Rule 7: penalty should be cleared")
	assert(g.awaiting_suit_choice == true, "Rule 7: two Aces should trigger suit choice")


func test_rule7_ace_can_be_played_anytime() -> void:
	var g := make_game([[c(14, 0)]], [c(5, 0)], [], 0, 1)
	assert(g.can_play(c(14, 0)) == true, "Rule 7: Ace can be played regardless of suit")


# ============================================================
# Rule 8: J skips, K reverses (like J in 2p), J answers J, K answers K
# ============================================================

func test_rule8_j_skips_opponent() -> void:
	var g := make_game([[c(11, 0)]], [c(5, 0)], [], 0, 0)
	assert(g.play_cards(0, [c(11, 0)], false) == true, "Rule 8: playing J should succeed")
	assert(g.pending_jump_rank == 11, "Rule 8: jump rank should be J")
	assert(g.pending_jump_by == 0, "Rule 8: jump_by should be player 0")
	assert(g.current_player == 1, "Rule 8: turn should pass to opponent (target of jump)")


func test_rule8_k_reverses_like_j_in_2p() -> void:
	var g := make_game([[c(13, 0)]], [c(5, 0)], [], 0, 0)
	assert(g.play_cards(0, [c(13, 0)], false) == true, "Rule 8: playing K should succeed")
	assert(g.pending_jump_rank == 13, "Rule 8: jump rank should be K")
	assert(g.current_player == 1, "Rule 8: K acts like J in 2p, turn passes to opponent")


func test_rule8_j_can_only_be_answered_with_j() -> void:
	var g := make_game([[c(11, 1), c(13, 1), c(5, 1)]], [c(11, 0)], [], 1, 0, false, 0, 11, 0, true)
	assert(g.can_play(c(11, 1)) == true, "Rule 8: J can be answered with J")
	assert(g.can_play(c(13, 1)) == false, "Rule 8: K cannot answer J")
	assert(g.can_play(c(5, 1)) == false, "Rule 8: plain card cannot answer J")


func test_rule8_k_can_only_be_answered_with_k() -> void:
	var g := make_game([[c(13, 1), c(11, 1), c(5, 1)]], [c(13, 0)], [], 1, 0, false, 0, 13, 0, true)
	assert(g.can_play(c(13, 1)) == true, "Rule 8: K can be answered with K")
	assert(g.can_play(c(11, 1)) == false, "Rule 8: J cannot answer K")
	assert(g.can_play(c(5, 1)) == false, "Rule 8: plain card cannot answer K")


func test_rule8_accept_jump_passes_turn_to_jumper() -> void:
	var g := make_game([[], [c(5, 0)]], [c(11, 0)], [], 1, 0, false, 0, 11, 0)
	assert(g.accept_jump(1) == true, "Rule 8: accepting jump should succeed")
	assert(g.pending_jump_rank == 0, "Rule 8: jump should be cleared")
	assert(g.current_player == 0, "Rule 8: turn should go back to jumper")


func test_rule8_last_jumper_plays_next_after_chain() -> void:
	var g := make_game([[c(11, 1)], []], [c(11, 0)], [], 1, 0, false, 0, 11, 0)
	assert(g.play_cards(1, [c(11, 1)], false) == true, "Rule 8: countering J with J should succeed")
	assert(g.pending_jump_rank == 11, "Rule 8: jump rank should still be J")
	assert(g.pending_jump_by == 1, "Rule 8: jump_by should now be player 1 (last jumper)")
	assert(g.current_player == 0, "Rule 8: turn passes to opponent (player 0)")


# ============================================================
# Rule 9: Q/8 question cards - must answer with matching suit
# ============================================================

func test_rule9_q_triggers_question() -> void:
	var g := make_game([[c(12, 0)]], [c(5, 0)], [], 0, 0)
	assert(g.play_cards(0, [c(12, 0)], false) == true, "Rule 9: playing Q should succeed")
	assert(g.awaiting_answer == true, "Rule 9: Q should trigger awaiting_answer")
	assert(g.question_suit == 0, "Rule 9: question suit should be current suit")
	assert(g.current_player == 1, "Rule 9: same player must answer (turn passes to opponent)")


func test_rule9_8_triggers_question() -> void:
	var g := make_game([[c(8, 0)]], [c(5, 0)], [], 0, 0)
	assert(g.play_cards(0, [c(8, 0)], false) == true, "Rule 9: playing 8 should succeed")
	assert(g.awaiting_answer == true, "Rule 9: 8 should trigger awaiting_answer")
	assert(g.question_suit == 0, "Rule 9: question suit should be current suit")


func test_rule9_answer_must_match_suit() -> void:
	var g := make_game([[c(5, 0), c(7, 1)]], [c(12, 0)], [], 1, 0, false, 0, 0, 0, true, 0)
	assert(g.can_play(c(5, 0)) == true, "Rule 9: same suit (♥) can answer")
	assert(g.can_play(c(7, 1)) == false, "Rule 9: different suit (♦) cannot answer")


func test_rule9_ace_can_always_answer_question() -> void:
	var g := make_game([[c(14, 1)]], [c(12, 0)], [], 1, 0, false, 0, 0, 0, true, 0)
	assert(g.can_play(c(14, 1)) == true, "Rule 9: Ace can answer any question (always playable)")


func test_rule9_unanswered_question_pickup_one_card() -> void:
	var g := make_game([[c(7, 1)]], [c(12, 0)], [c(5, 0), c(6, 0), c(7, 0), c(8, 0)], 1, 0, false, 0, 0, 0, true, 0)
	var hand_size_before := g.hands[1].size()
	g.pick_up(1)
	assert(g.hands[1].size() == hand_size_before + 1, "Rule 9: unanswered question should pick up 1 card")
	assert(g.awaiting_answer == false, "Rule 9: question should be cleared after pickup")
	assert(g.current_player == 0, "Rule 9: turn should pass to other player")


func test_rule9_picked_card_cannot_be_played_same_turn() -> void:
	var g := make_game([[c(7, 1)], [c(5, 0)]], [c(12, 0)], [c(5, 0), c(6, 0)], 1, 0, false, 0, 0, 0, true, 0)
	g.pick_up(1)
	assert(g.current_player == 0, "Rule 9: after pickup for Q/8, turn passes to opponent")


# ============================================================
# Rule 10: Declaration (Niko Kadi)
# ============================================================

func test_rule10_declare_when_play_leaves_one_card() -> void:
	var g := make_game([[c(5, 0), c(7, 0)]], [c(5, 1)], [], 0, 0)
	assert(g.play_cards(0, [c(5, 0)], true) == true, "Rule 10: declaring with play that leaves 1 card should succeed")
	assert(g.declared[0] == true, "Rule 10: player should be declared")
	assert(g.unlocked[0] == false, "Rule 10: declaration should be locked (opponent hasn't had turn)")


func test_rule10_declare_requires_plain_card_remaining() -> void:
	var g := make_game([[c(11, 0), c(7, 0)]], [c(5, 1)], [], 0, 0)
	assert(g.can_declare_on_play(0, [c(11, 0)]) == true, "Rule 10: J play leaving plain card can declare")
	
	var g2 := make_game([[c(12, 0), c(7, 0)]], [c(5, 1)], [], 0, 0)
	assert(g2.can_declare_on_play(0, [c(12, 0)]) == false, "Rule 10: Q cannot carry declaration")
	assert(g2.can_declare_on_play(0, [c(12, 0)]) == false, "Rule 10: Q cannot carry declaration")


func test_rule10_declare_voids_on_pickup() -> void:
	var g := make_game([[c(7, 0)], []], [c(5, 1)], [], 1, 0, false, 0, 0, 0, false, -1, false, 0, -1, [true, false], [false, false])
	g.pick_up(1)
	assert(g.declared[1] == false, "Rule 10: opponent's pickup shouldn't affect our declaration")
	
	var g2 := make_game([[c(7, 0)], []], [c(5, 1)], [], 0, 0, false, 0, 0, 0, true, 0, false, 0, -1, [true, false], [false, false])
	g2.pick_up(0)
	assert(g2.declared[0] == false, "Rule 10: picking up voids declaration")
	assert(g2.unlocked[0] == false, "Rule 10: unlocked also voided")


func test_rule10_card_locked_until_declared_and_opponent_turn() -> void:
	var g := make_game([[c(7, 0)], []], [c(5, 1)], [], 1, 0, false, 0, 0, 0, false, -1, false, 0, -1, [true, false], [false, false])
	g._end_turn(1)
	assert(g.unlocked[0] == true, "Rule 10: after opponent's turn, declaration unlocks")
	
	var g2 := make_game([[c(7, 0)], []], [c(5, 1)], [], 1, 0, false, 0, 0, 0, false, -1, false, 0, -1, [false, false], [false, false])
	g2._end_turn(1)
	assert(g2.unlocked[0] == false, "Rule 10: without declaration, card stays locked")


func test_rule10_can_declare_now_with_one_plain_card() -> void:
	var g := make_game([[c(7, 0)], []], [c(5, 1)], [], 0, 0, false, 0, 0, 0, false, -1, false, 0, -1, [false, false], [false, false])
	g.declare_now(0)
	assert(g.declared[0] == true, "Rule 10: declare_now should work with 1 plain card")
	assert(g.unlocked[0] == true, "Rule 10: declare_now unlocks immediately (opponent already had turn)")


func test_rule10_declare_late_after_opponent_turn() -> void:
	var g := make_game([[c(7, 0)], []], [c(5, 1)], [], 1, 0, false, 0, 0, 0, false, -1, false, 0, -1, [false, false], [false, false])
	g.declare_late(0)
	assert(g.declared[0] == true, "Rule 10: declare_late should work")


# ============================================================
# Rule 11: Winning - last card must be plain 4-10
# ============================================================

func test_rule11_win_with_plain_last_card() -> void:
	var g := make_game([[c(7, 0)], [c(5, 0)]], [c(5, 1)], [], 0, 0, false, 0, 0, 0, false, -1, false, 0, -1, [true, false], [true, false])
	assert(g.play_cards(0, [c(7, 0)], false) == true, "Rule 11: playing last plain card should succeed")
	assert(g.is_game_over() == 1, "Rule 11: player 0 should win")
	assert(g.winner == 1, "Rule 11: winner should be player 0 (index 1)")


func test_rule11_cannot_win_with_special_last_card() -> void:
	var g := make_game([[c(11, 0)], [c(5, 0)]], [c(5, 1)], [], 0, 0, false, 0, 0, 0, false, -1, false, 0, -1, [true, false], [true, false])
	assert(g.play_cards(0, [c(11, 0)], false) == true, "Rule 11: playing J as last card is legal play")
	assert(g.is_game_over() == 0, "Rule 11: game should NOT end (special card can't win)")
	assert(g.winner == 0, "Rule 11: no winner yet")
	assert(g.hands[0].is_empty(), "Rule 11: hand is empty but didn't win")


func test_rule11_j_plus_plain_not_a_win() -> void:
	var g2 := make_game([[c(11, 0)], [c(5, 0)]], [c(11, 1)], [], 0, 0, false, 0, 0, 0, false, -1, false, 0, -1, [true, false], [true, false])
	assert(g2.play_cards(0, [c(11, 0)], false) == true, "Rule 11: playing J as only card")
	assert(g2.is_game_over() == 0, "Rule 11: J as last card should NOT win")


func test_rule11_cannot_win_with_q_or_8() -> void:
	for rank in [12, 8]:
		var g := make_game([[c(rank, 0)], [c(5, 0)]], [c(rank, 1)], [], 0, 0, false, 0, 0, 0, false, -1, false, 0, -1, [true, false], [true, false])
		assert(g.play_cards(0, [c(rank, 0)], false) == true, "Rule 11: playing Q/8 as only card")
		assert(g.is_game_over() == 0, "Rule 11: Q/8 as last card should NOT win")


func test_rule11_cannot_win_with_ace() -> void:
	var g := make_game([[c(14, 0)], [c(5, 0)]], [c(14, 1)], [], 0, 0, false, 0, 0, 0, false, -1, false, 0, -1, [true, false], [true, false])
	assert(g.play_cards(0, [c(14, 0)], false) == true, "Rule 11: playing Ace as only card")
	assert(g.is_game_over() == 0, "Rule 11: Ace as last card should NOT win")


func test_rule11_cannot_win_with_2_or_3() -> void:
	for rank in [2, 3]:
		var g := make_game([[c(rank, 0)], [c(5, 0)]], [c(rank, 1)], [], 0, 0, false, 0, 0, 0, false, -1, false, 0, -1, [true, false], [true, false])
		assert(g.play_cards(0, [c(rank, 0)], false) == true, "Rule 11: playing " + str(rank) + " as only card")
		assert(g.is_game_over() == 0, "Rule 11: " + str(rank) + " as last card should NOT win")


# ============================================================
# Additional: Two Aces calling exact card (GameState feature not in rules.md)
# ============================================================

func test_two_aces_call_exact_card() -> void:
	var g := make_game([[c(14, 0), c(14, 1)]], [c(5, 0)], [], 0, 0)
	assert(g.play_cards(0, [c(14, 0), c(14, 1)], false) == true, "Two Aces should trigger awaiting_call")
	assert(g.awaiting_call == true, "Two Aces should set awaiting_call")
	assert(g.call_rank == 0, "Call rank should be 0 until chosen")
	assert(g.call_suit == -1, "Call suit should be -1 until chosen")


func test_choose_call_sets_call_rank_and_suit() -> void:
	var g := make_game([[c(14, 0), c(14, 1)], []], [c(14, 0), c(14, 1)], [], 0, 0, false, 0, 0, 0, false, -1, true, 0, -1)
	assert(g.choose_call(0, 7, 2, false) == true, "choose_call should succeed")
	assert(g.call_rank == 7, "Call rank should be 7")
	assert(g.call_suit == 2, "Call suit should be 2 (♣)")
	assert(g.current_suit == 2, "Current suit should become called suit")
	assert(g.awaiting_call == false, "awaiting_call should be cleared")


func test_answer_call_with_exact_card() -> void:
	var g := make_game([[c(7, 2)]], [c(14, 0), c(14, 1)], [], 1, 2, false, 0, 0, 0, false, -1, false, 7, 2)
	assert(g.can_play(c(7, 2)) == true, "Exact called card should be playable")
	assert(g.play_cards(1, [c(7, 2)], false) == true, "Playing exact called card should succeed")
	assert(g.call_rank == 0, "Call should be cleared")


func test_answer_call_with_ace() -> void:
	var g := make_game([[c(14, 0)]], [c(14, 1), c(14, 2)], [], 1, 0, false, 0, 0, 0, false, -1, false, 7, 2)
	assert(g.can_play(c(14, 0)) == true, "Ace should be playable to answer call")
	assert(g.play_cards(1, [c(14, 0)], false) == true, "Playing Ace to answer call should succeed")
	assert(g.call_rank == 0, "Call should be cleared")
	assert(g.current_suit == 0, "One Ace removes number, suit stays")


func test_answer_call_with_two_aces_cancels_call_and_chooses_suit() -> void:
	var g := make_game([[c(14, 0), c(14, 1)]], [c(14, 2), c(14, 3)], [], 1, 0, false, 0, 0, 0, false, -1, false, 7, 2)
	assert(g.play_cards(1, [c(14, 0), c(14, 1)], false) == true, "Two Aces should cancel call")
	assert(g.awaiting_suit_choice == true, "Two Aces should trigger suit choice")
	assert(g.call_rank == 0, "Call should be cleared")


# ============================================================
# Run all tests
# ============================================================

func _init() -> void:
	# Rule 4
	run_test("Rule 4: matching suit legal", test_rule4_play_matching_suit_legal)
	run_test("Rule 4: matching rank legal", test_rule4_play_matching_rank_legal)
	run_test("Rule 4: non-matching illegal", test_rule4_play_non_matching_illegal)
	
	# Rule 5
	run_test("Rule 5: plain cards identified correctly", test_rule5_plain_cards)
	
	# Rule 6
	run_test("Rule 6: 2 adds penalty", test_rule6_play_2_adds_penalty)
	run_test("Rule 6: 3 adds penalty", test_rule6_play_3_adds_penalty)
	run_test("Rule 6: 2 on 2 stacks", test_rule6_penalty_stacks_2_on_2)
	run_test("Rule 6: 3 on 3 stacks", test_rule6_penalty_stacks_3_on_3)
	run_test("Rule 6: 2 on 3 stacks (proposed)", test_rule6_penalty_stacks_2_on_3)
	run_test("Rule 6: 3 on 2 stacks (proposed)", test_rule6_penalty_stacks_3_on_2)
	run_test("Rule 6: only 2/3 can counter penalty", test_rule6_penalty_can_only_be_countered_with_2_or_3)
	run_test("Rule 6: penalty counter matches suit or rank", test_rule6_penalty_must_match_suit_or_rank)
	
	# Rule 7
	run_test("Rule 7: Ace on normal play changes suit", test_rule7_ace_on_normal_play_changes_suit)
	run_test("Rule 7: Ace blocks penalty stack", test_rule7_ace_blocks_penalty_stack)
	run_test("Rule 7: two Aces on penalty block and change suit", test_rule7_two_aces_on_penalty_blocks_and_changes_suit)
	run_test("Rule 7: Ace always playable", test_rule7_ace_can_be_played_anytime)
	
	# Rule 8
	run_test("Rule 8: J skips opponent", test_rule8_j_skips_opponent)
	run_test("Rule 8: K reverses like J in 2p", test_rule8_k_reverses_like_j_in_2p)
	run_test("Rule 8: J answered only by J", test_rule8_j_can_only_be_answered_with_j)
	run_test("Rule 8: K answered only by K", test_rule8_k_can_only_be_answered_with_k)
	run_test("Rule 8: accept jump passes to jumper", test_rule8_accept_jump_passes_turn_to_jumper)
	run_test("Rule 8: last jumper plays next", test_rule8_last_jumper_plays_next_after_chain)
	
	# Rule 9
	run_test("Rule 9: Q triggers question", test_rule9_q_triggers_question)
	run_test("Rule 9: 8 triggers question", test_rule9_8_triggers_question)
	run_test("Rule 9: answer must match suit", test_rule9_answer_must_match_suit)
	run_test("Rule 9: Ace always answers question", test_rule9_ace_can_always_answer_question)
	run_test("Rule 9: unanswered question picks up 1", test_rule9_unanswered_question_pickup_one_card)
	run_test("Rule 9: picked card not played same turn", test_rule9_picked_card_cannot_be_played_same_turn)
	
	# Rule 10
	run_test("Rule 10: declare when play leaves 1 card", test_rule10_declare_when_play_leaves_one_card)
	run_test("Rule 10: declare requires plain card remaining", test_rule10_declare_requires_plain_card_remaining)
	run_test("Rule 10: pickup voids declaration", test_rule10_declare_voids_on_pickup)
	run_test("Rule 10: card locked until declared + opponent turn", test_rule10_card_locked_until_declared_and_opponent_turn)
	run_test("Rule 10: declare_now with 1 plain card", test_rule10_can_declare_now_with_one_plain_card)
	run_test("Rule 10: declare_late after opponent turn", test_rule10_declare_late_after_opponent_turn)
	
	# Rule 11
	run_test("Rule 11: win with plain last card", test_rule11_win_with_plain_last_card)
	run_test("Rule 11: cannot win with special last card", test_rule11_cannot_win_with_special_last_card)
	run_test("Rule 11: J + plain not a win", test_rule11_j_plus_plain_not_a_win)
	run_test("Rule 11: cannot win with Q/8", test_rule11_cannot_win_with_q_or_8)
	run_test("Rule 11: cannot win with Ace", test_rule11_cannot_win_with_ace)
	run_test("Rule 11: cannot win with 2/3", test_rule11_cannot_win_with_2_or_3)
	
	# Two Aces calling (GameState feature)
	run_test("Two Aces: call exact card", test_two_aces_call_exact_card)
	run_test("Two Aces: choose_call sets call", test_choose_call_sets_call_rank_and_suit)
	run_test("Two Aces: answer with exact card", test_answer_call_with_exact_card)
	run_test("Two Aces: answer with single Ace", test_answer_call_with_ace)
	run_test("Two Aces: two Aces cancel call", test_answer_call_with_two_aces_cancels_call_and_chooses_suit)
	
	print("\n=== ALL TESTS PASSED ===")
	
	# ============================================================
	# Ambiguities / Disagreements between rules.md and GameState.gd
	# ============================================================
	print("\n=== AMBIGUITIES / DISAGREEMENTS ===")
	print("1. Rule 6: 'Whether a 2 can stack on a 3 is undecided; proposed default is yes.'")
	print("   GameState allows both 2-on-3 and 3-on-2 stacking. Rule.md leaves it undecided.")
	print("")
	print("2. Rule 9: 'If unanswered, the player picks 1 card in the same turn and cannot play")
	print("   that picked card back during that turn.'")
	print("   GameState's pick_up() ends the turn (passes to opponent). The player who picked")
	print("   up cannot play the card immediately because it's now opponent's turn. Consistent?")
	print("   But 'in the same turn' phrasing is ambiguous - does it mean the picker's turn?")
	print("")
	print("3. Two Aces calling an exact card (awaiting_call, choose_call, etc.)")
	print("   This is a significant GameState feature NOT mentioned in rules.md at all.")
	print("   - Two Aces on normal play: call exact card (rank 2-13, any suit)")
	print("   - Two Aces on penalty: block penalty AND change suit")
	print("   - Two Aces answering a call: cancel call, choose suit")
	print("   - One Ace answering a call: remove number, called suit stays")
	print("   - One Ace on penalty: block penalty, suit stays (transparent)")
	print("")
	print("4. Rule 7: 'Ace changes the suit in play, OR blocks a pick-up penalty'")
	print("   GameState has nuanced behavior: single Ace on penalty = blocks, suit stays;")
	print("   two Aces on penalty = blocks AND changes suit; two Aces normally = call card.")
	print("   Rules.md doesn't distinguish single vs double Ace on penalty.")
	print("")
	print("5. Declaration timing: rules.md says 'when a play leaves you with exactly 1 card,")
	print("   you must declare WITH THAT PLAY.' GameState has:")
	print("   - can_declare_on_play: checked during play_cards (declare with the play)")
	print("   - declare_late: after play, before opponent moves (for when you forget?)")
	print("   - declare_now: on your turn when you already have 1 card (opponent had turn)")
	print("   The distinction between declare_late and can_declare_on_play is not in rules.md.")
	print("")
	print("6. Rule 11: 'Playing J + a plain card to go cardless is NOT a win.'")
	print("   GameState enforces this via: chains can't empty hand (line 139), and win")
	print("   requires first card to be plain (line 155). Since chains require same rank,")
	print("   J + plain is impossible anyway. The rule seems redundant given chain rules.")
	print("")
	print("7. Rule 10: 'Your last card is locked until you have declared AND the opponent")
	print("   has had a full turn.' GameState unlocks in _end_turn when opponent takes a turn.")
	print("   But if opponent picks up (not a 'full turn' of playing), it still unlocks.")
	print("   Is 'full turn' = any turn completion, or only playing cards?")
	print("")
	print("8. Can you declare on a play that leaves 1 card if that 1 card is a special?")
	print("   rules.md: 'must declare with that play' (no exception)")
	print("   GameState can_declare_on_play: requires remaining card to be plain (line 365)")
	print("   This is a DISAGREEMENT: GameState prevents declaring with special remaining.")
	
	quit()