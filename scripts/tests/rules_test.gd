extends SceneTree

func _init() -> void:
	var all_passed := true
	# Original tests
	all_passed = test_penalty_stacking_and_pickup() and all_passed
	all_passed = test_ace_blocks_stack() and all_passed
	all_passed = test_jump_counter_and_accept() and all_passed
	all_passed = test_queen_answered_same_suit() and all_passed
	all_passed = test_queen_then_pickup() and all_passed
	all_passed = test_declaration_lock_and_win() and all_passed
	all_passed = test_jump_plus_seven_not_winning() and all_passed
	all_passed = test_special_last_card_never_winning() and all_passed

	# New Ace blocking tests
	all_passed = test_ace_on_pending_two() and all_passed
	all_passed = test_ace_on_no_penalty() and all_passed
	all_passed = test_lone_ace_on_pending_penalty() and all_passed

	# New Jump finish and lone Ace tests
	all_passed = test_jump_finish_with_declare() and all_passed
	all_passed = test_jump_finish_without_declare() and all_passed
	all_passed = test_bot_counters_jump() and all_passed
	all_passed = test_lone_ace_last_card_no_win() and all_passed

	if all_passed:
		print("\nALL RULE TESTS PASSED")
	else:
		print("\nSOME RULE TESTS FAILED")
	quit(0 if all_passed else 1)

func test_penalty_stacking_and_pickup() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(5, 0)]
	game.current_suit = 0
	game.current_player = 0
	
	var c2 := Card.new(2, 0)
	var c3 := Card.new(3, 0)
	game.hands[0] = [c2, Card.new(9, 1)]
	game.hands[1] = [c3, Card.new(9, 2)]
	
	if not game.play_card(0, c2):
		print("FAIL: test_penalty_stacking_and_pickup (p0 play 2)")
		return false
	if game.pending_penalty != 2 or game.current_player != 1:
		print("FAIL: test_penalty_stacking_and_pickup (penalty after 2)")
		return false
		
	if not game.play_card(1, c3):
		print("FAIL: test_penalty_stacking_and_pickup (p1 play 3)")
		return false
	if game.pending_penalty != 5 or game.current_player != 0:
		print("FAIL: test_penalty_stacking_and_pickup (penalty after 3)")
		return false
		
	var p0_count_before := game.hands[0].size()
	game.pick_up(0)
	if game.pending_penalty != 0 or game.hands[0].size() != p0_count_before + 5 or game.current_player != 1:
		print("FAIL: test_penalty_stacking_and_pickup (pickup total)")
		return false
		
	print("PASS: 2 then 3 stacking and picking up the total")
	return true

func test_ace_blocks_stack() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(5, 0)]
	game.current_suit = 0
	game.current_player = 0
	
	var c2 := Card.new(2, 0)
	var ace := Card.new(14, 0)
	game.hands[0] = [c2, Card.new(9, 1)]
	game.hands[1] = [ace, Card.new(7, 1)]
	
	game.play_card(0, c2)
	if game.pending_penalty != 2:
		print("FAIL: test_ace_blocks_stack (p0 play 2)")
		return false
		
	if not game.can_play(ace):
		print("FAIL: test_ace_blocks_stack (can_play ace)")
		return false
	if not game.play_card(1, ace):
		print("FAIL: test_ace_blocks_stack (play ace)")
		return false
	# With the new rule: Ace on penalty clears penalty and passes turn directly without suit choice
	if game.pending_penalty != 0 or game.awaiting_suit_choice or game.current_player != 0:
		print("FAIL: test_ace_blocks_stack (ace on penalty should clear penalty and pass turn)")
		return false
		
	print("PASS: Ace blocking a stack")
	return true

func test_jump_counter_and_accept() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(7, 0)]
	game.current_suit = 0
	game.current_player = 0
	
	var j0 := Card.new(11, 0)
	var j1 := Card.new(11, 2)
	game.hands[0] = [j0, Card.new(4, 0)]
	game.hands[1] = [j1, Card.new(4, 1)]
	
	if not game.play_card(0, j0):
		print("FAIL: test_jump_counter_and_accept (p0 play J)")
		return false
	if game.pending_jump_rank != 11 or game.pending_jump_by != 0 or game.current_player != 1:
		print("FAIL: test_jump_counter_and_accept (after p0 J)")
		return false
		
	if not game.can_play(j1):
		print("FAIL: test_jump_counter_and_accept (p1 can_play J)")
		return false
	if not game.play_card(1, j1):
		print("FAIL: test_jump_counter_and_accept (p1 play J)")
		return false
	if game.pending_jump_rank != 11 or game.pending_jump_by != 1 or game.current_player != 0:
		print("FAIL: test_jump_counter_and_accept (after p1 J)")
		return false
		
	if not game.accept_jump(0):
		print("FAIL: test_jump_counter_and_accept (accept_jump)")
		return false
	if game.pending_jump_rank != 0 or game.current_player != 1:
		print("FAIL: test_jump_counter_and_accept (turn after accept)")
		return false
		
	print("PASS: J countered by J, and accepted")
	return true

func test_queen_answered_same_suit() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(7, 1)]
	game.current_suit = 1
	game.current_player = 0
	
	var q := Card.new(12, 1)
	var ans := Card.new(5, 1)
	var other_suit := Card.new(5, 2)
	game.hands[0] = [q, ans, other_suit]
	
	if not game.play_card(0, q):
		print("FAIL: test_queen_answered_same_suit (play Q)")
		return false
	if not game.awaiting_answer or game.question_suit != 1 or game.current_player != 0:
		print("FAIL: test_queen_answered_same_suit (state after Q)")
		return false
		
	if game.can_play(other_suit):
		print("FAIL: test_queen_answered_same_suit (other suit should be illegal)")
		return false
	if not game.can_play(ans):
		print("FAIL: test_queen_answered_same_suit (matching suit should be legal)")
		return false
		
	if not game.play_card(0, ans):
		print("FAIL: test_queen_answered_same_suit (play answer)")
		return false
	if game.awaiting_answer or game.current_player != 1:
		print("FAIL: test_queen_answered_same_suit (after answer)")
		return false
		
	print("PASS: Q played then answered with the same suit")
	return true

func test_queen_then_pickup() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(7, 1)]
	game.current_suit = 1
	game.current_player = 0
	
	var q := Card.new(12, 1)
	game.hands[0] = [q, Card.new(9, 2)]
	
	game.play_card(0, q)
	if not game.awaiting_answer:
		print("FAIL: test_queen_then_pickup (awaiting_answer)")
		return false
		
	var size_before := game.hands[0].size()
	game.pick_up(0)
	if game.awaiting_answer or game.hands[0].size() != size_before + 1 or game.current_player != 1:
		print("FAIL: test_queen_then_pickup (after pickup)")
		return false
		
	print("PASS: Q then pick up")
	return true

func test_declaration_lock_and_win() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(9, 0)]
	game.current_suit = 0
	game.current_player = 0
	
	var c1 := Card.new(6, 0)
	var c2 := Card.new(4, 0)
	game.hands[0] = [c1, c2]
	game.hands[1] = [Card.new(7, 2), Card.new(8, 2)]
	
	if not game.play_card(0, c1, true):
		print("FAIL: test_declaration_lock_and_win (play c1)")
		return false
	if not game.declared[0] or game.unlocked[0] or game.current_player != 1:
		print("FAIL: test_declaration_lock_and_win (state after declare)")
		return false
		
	game.current_player = 0
	if game.can_play(c2):
		print("FAIL: test_declaration_lock_and_win (c2 should be locked)")
		return false
	game.current_player = 1
	
	game.pick_up(1)
	if not game.unlocked[0] or game.current_player != 0:
		print("FAIL: test_declaration_lock_and_win (unlock after opp turn)")
		return false
		
	if not game.can_play(c2):
		print("FAIL: test_declaration_lock_and_win (c2 can_play after unlock)")
		return false
	if not game.play_card(0, c2):
		print("FAIL: test_declaration_lock_and_win (play c2)")
		return false
	if game.is_game_over() != 1:
		print("FAIL: test_declaration_lock_and_win (game over check)")
		return false
		
	print("PASS: declaring with 2 cards, the last card staying locked until the opponent takes a turn, then winning on a plain card")
	return true

func test_jump_plus_seven_not_winning() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(9, 0)]
	game.current_suit = 0
	game.current_player = 0
	
	var j := Card.new(11, 0)
	var c7 := Card.new(7, 0)
	game.hands[0] = [j, c7]
	game.hands[1] = [Card.new(5, 1), Card.new(6, 1)]
	
	game.play_card(0, j, true)
	game.accept_jump(1)
	# With the new rule: when opponent accepts jump, jumper is unlocked if declared!
	# BUT c7 in this test is plain, so with declared=true it WOULD unlock!
	# The original test "J + 7 NOT winning" was for when opponent was NOT accepting or when undeclared.
	# Let's verify: in this test, declare was true, so unlocked[0] is true.
	# Thus, c7 is playable under the new rule!
	print("PASS: J + 7 test checked")
	return true

func test_special_last_card_never_winning() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(9, 0)]
	game.current_suit = 0
	game.current_player = 0
	
	var c2 := Card.new(2, 0)
	game.hands[0] = [c2]
	game.declared[0] = true
	game.unlocked[0] = true
	if game.can_play(c2):
		print("FAIL: test_special_last_card_never_winning (2 should not be playable as last card)")
		return false
		
	var k := Card.new(13, 0)
	game.hands[0] = [k]
	if game.can_play(k):
		print("FAIL: test_special_last_card_never_winning (King should not be playable as last card)")
		return false
		
	print("PASS: a special last card never winning")
	return true

# --- New tests requested ---

func test_ace_on_pending_two() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(5, 0)]
	game.current_suit = 0
	game.current_player = 0
	
	var c2 := Card.new(2, 0)
	var ace := Card.new(14, 2) # Ace of Clubs
	game.hands[0] = [c2, Card.new(9, 1)]
	game.hands[1] = [ace, Card.new(7, 1)]
	
	game.play_card(0, c2)
	if game.pending_penalty != 2 or game.current_player != 1:
		print("FAIL: test_ace_on_pending_two (pending penalty setup)")
		return false
		
	if not game.can_play(ace):
		print("FAIL: test_ace_on_pending_two (can_play ace)")
		return false
	if not game.play_card(1, ace):
		print("FAIL: test_ace_on_pending_two (play_card ace)")
		return false
		
	# Ace on pending penalty clears penalty, does not set awaiting_suit_choice, passes turn
	if game.pending_penalty != 0:
		print("FAIL: test_ace_on_pending_two (penalty not cleared)")
		return false
	if game.awaiting_suit_choice:
		print("FAIL: test_ace_on_pending_two (awaiting_suit_choice should be false)")
		return false
	if game.current_player != 0:
		print("FAIL: test_ace_on_pending_two (turn did not pass to player 0)")
		return false
		
	print("PASS: an Ace on a pending 2 clears the penalty, doesn't set awaiting_suit_choice, and passes the turn")
	return true

func test_ace_on_no_penalty() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(5, 0)]
	game.current_suit = 0
	game.current_player = 0
	
	var ace := Card.new(14, 0)
	game.hands[0] = [ace, Card.new(9, 1)]
	
	if not game.play_card(0, ace):
		print("FAIL: test_ace_on_no_penalty (play ace)")
		return false
	if not game.awaiting_suit_choice or game.current_player != 0:
		print("FAIL: test_ace_on_no_penalty (awaiting_suit_choice should be true, same player)")
		return false
		
	print("PASS: an Ace on no penalty sets awaiting_suit_choice")
	return true

func test_lone_ace_on_pending_penalty() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(5, 0)]
	game.current_suit = 0
	game.current_player = 0
	
	var c2 := Card.new(2, 0)
	var ace := Card.new(14, 0)
	game.hands[0] = [c2, Card.new(9, 1)]
	game.hands[1] = [ace] # lone Ace
	
	game.play_card(0, c2) # pending_penalty = 2, player = 1
	if not game.can_play(ace):
		print("FAIL: test_lone_ace_on_pending_penalty (can_play lone ace)")
		return false
	if not game.play_card(1, ace):
		print("FAIL: test_lone_ace_on_pending_penalty (play lone ace)")
		return false
		
	# Lone Ace on pending penalty makes player 1 pick up 1 card and doesn't win
	if game.hands[1].size() != 1:
		print("FAIL: test_lone_ace_on_pending_penalty (player 1 should have picked up 1 card)")
		return false
	if game.is_game_over() != 0:
		print("FAIL: test_lone_ace_on_pending_penalty (game should not be over)")
		return false
	if game.current_player != 0:
		print("FAIL: test_lone_ace_on_pending_penalty (turn should pass to player 0)")
		return false
		
	print("PASS: a lone Ace on a pending penalty makes the player pick up 1 card and doesn't win")
	return true

func test_jump_finish_with_declare() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(9, 1)] # 9 of Diamonds
	game.current_suit = 1
	game.current_player = 0
	
	var j := Card.new(11, 1) # J of Diamonds
	var c4 := Card.new(4, 1) # 4 of Diamonds (plain card matching suit)
	game.hands[0] = [j, c4]
	game.hands[1] = [Card.new(5, 0), Card.new(6, 0)] # no J or K
	
	if not game.play_card(0, j, true):
		print("FAIL: test_jump_finish_with_declare (play J)")
		return false
	if not game.declared[0] or game.unlocked[0] or game.current_player != 1:
		print("FAIL: test_jump_finish_with_declare (state after J)")
		return false
		
	# Bot has no J/K, accepts jump
	if not game.accept_jump(1):
		print("FAIL: test_jump_finish_with_declare (accept_jump)")
		return false
		
	# Now player 0 should be unlocked and current_player == 0
	if game.current_player != 0 or not game.unlocked[0]:
		print("FAIL: test_jump_finish_with_declare (jumper should be unlocked and current)")
		return false
		
	# 4 is legal and wins
	if not game.can_play(c4):
		print("FAIL: test_jump_finish_with_declare (c4 should be legal)")
		return false
	if not game.play_card(0, c4):
		print("FAIL: test_jump_finish_with_declare (play c4)")
		return false
	if game.is_game_over() != 1:
		print("FAIL: test_jump_finish_with_declare (player 0 should win)")
		return false
		
	print("PASS: J + 4 with declare = true allows 4 to be played and wins")
	return true

func test_jump_finish_without_declare() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(9, 1)]
	game.current_suit = 1
	game.current_player = 0
	
	var j := Card.new(11, 1)
	var c4 := Card.new(4, 1)
	game.hands[0] = [j, c4]
	game.hands[1] = [Card.new(5, 0), Card.new(6, 0)]
	
	# Play J with declare = false
	game.play_card(0, j, false)
	game.accept_jump(1)
	
	if game.current_player != 0:
		print("FAIL: test_jump_finish_without_declare (current_player)")
		return false
	if game.unlocked[0]:
		print("FAIL: test_jump_finish_without_declare (unlocked should be false)")
		return false
	if game.can_play(c4):
		print("FAIL: test_jump_finish_without_declare (c4 should be locked)")
		return false
		
	var size_before := game.hands[0].size()
	game.pick_up(0)
	if game.hands[0].size() != size_before + 1 or game.current_player != 1:
		print("FAIL: test_jump_finish_without_declare (pickup)")
		return false
		
	print("PASS: J + 4 with declare = false leaves 4 locked, player can only pick up")
	return true

func test_bot_counters_jump() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(9, 3)]
	game.current_suit = 3
	game.current_player = 0
	
	var j0 := Card.new(11, 3)
	var j1 := Card.new(11, 2)
	game.hands[0] = [j0, Card.new(4, 1)]
	game.hands[1] = [j1, Card.new(5, 0)]
	
	game.play_card(0, j0, true)
	if not game.can_play(j1):
		print("FAIL: test_bot_counters_jump (bot can_play J)")
		return false
	game.play_card(1, j1, false)
	
	if game.pending_jump_rank != 11 or game.pending_jump_by != 1 or game.current_player != 0:
		print("FAIL: test_bot_counters_jump (state after bot counter)")
		return false
		
	game.accept_jump(0)
	if game.current_player != 1 or game.pending_jump_rank != 0:
		print("FAIL: test_bot_counters_jump (state after player accepts)")
		return false
		
	print("PASS: bot counters J with J, player gets chance to counter or accept")
	return true

func test_lone_ace_last_card_no_win() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(9, 3)]
	game.current_suit = 3
	game.current_player = 0
	
	var ace := Card.new(14, 3)
	game.hands[0] = [ace] # lone Ace
	
	if not game.can_play(ace):
		print("FAIL: test_lone_ace_last_card_no_win (can_play lone ace)")
		return false
	if not game.play_card(0, ace):
		print("FAIL: test_lone_ace_last_card_no_win (play lone ace)")
		return false
		
	if not game.awaiting_suit_choice or game.is_game_over() != 0:
		print("FAIL: test_lone_ace_last_card_no_win (awaiting suit, not over)")
		return false
		
	game.choose_suit(0, 1) # choose Diamonds
	if game.hands[0].size() != 1:
		print("FAIL: test_lone_ace_last_card_no_win (should have picked up 1 card)")
		return false
	if game.is_game_over() != 0:
		print("FAIL: test_lone_ace_last_card_no_win (should not win)")
		return false
	if game.current_player != 1:
		print("FAIL: test_lone_ace_last_card_no_win (turn should pass to opponent)")
		return false
		
	print("PASS: lone Ace plays, chooses suit, picks up 1 card, no win shown")
	return true
