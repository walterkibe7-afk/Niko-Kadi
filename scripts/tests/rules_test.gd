extends SceneTree

func _init() -> void:
	var all_passed := true
	all_passed = test_penalty_stacking_and_pickup() and all_passed
	all_passed = test_ace_blocks_stack() and all_passed
	all_passed = test_jump_counter_and_accept() and all_passed
	all_passed = test_queen_answered_same_suit() and all_passed
	all_passed = test_queen_then_pickup() and all_passed
	all_passed = test_declaration_lock_and_win() and all_passed
	all_passed = test_jump_plus_seven_not_winning() and all_passed
	all_passed = test_special_last_card_never_winning() and all_passed

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
	if game.pending_penalty != 0 or not game.awaiting_suit_choice or game.current_player != 1:
		print("FAIL: test_ace_blocks_stack (ace did not block or await suit)")
		return false
		
	game.choose_suit(1, 2)
	if game.current_suit != 2 or game.current_player != 0 or game.awaiting_suit_choice:
		print("FAIL: test_ace_blocks_stack (choose suit)")
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
	if game.current_player != 0:
		print("FAIL: test_jump_plus_seven_not_winning (current_player after skip)")
		return false
	if game.unlocked[0]:
		print("FAIL: test_jump_plus_seven_not_winning (unlocked should be false)")
		return false
	if game.can_play(c7):
		print("FAIL: test_jump_plus_seven_not_winning (c7 should not be playable)")
		return false
		
	print("PASS: J + 7 NOT winning")
	return true

func test_special_last_card_never_winning() -> bool:
	var game := GameState.new()
	game.start_game()
	game.discard_pile = [Card.new(9, 0)]
	game.current_suit = 0
	game.current_player = 0
	
	var ace := Card.new(14, 0)
	game.hands[0] = [ace]
	game.declared[0] = true
	game.unlocked[0] = true
	
	if game.can_play(ace):
		print("FAIL: test_special_last_card_never_winning (Ace should not be playable as last card)")
		return false
		
	var c2 := Card.new(2, 0)
	game.hands[0] = [c2]
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
