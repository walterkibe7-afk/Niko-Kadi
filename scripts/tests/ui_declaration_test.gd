extends SceneTree

# Headless checks for the declaration banner, the jump-route pause, and the
# final-card reveal. Drives the real Table scene so UI timing is exercised.

var table: Table
var passed := true


func _initialize() -> void:
	await _run()


func _ok(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		passed = false
		print("FAIL: %s" % label)


func _fresh_game() -> GameState:
	var g := GameState.new()
	g.start_game()
	g.discard_pile = [Card.new(9, Card.Suit.CLUBS)]
	g.current_suit = Card.Suit.CLUBS
	g.current_player = 0
	g.declared = [false, false]
	g.unlocked = [false, false]
	g.pending_penalty = 0
	g.pending_jump_rank = 0
	g.pending_jump_by = -1
	g.awaiting_answer = false
	g.awaiting_suit_choice = false
	return g


func _run() -> void:
	var scene := load("res://scenes/table.tscn") as PackedScene
	table = scene.instantiate() as Table
	root.add_child(table)
	await process_frame

	# --- Banner visibility and text ---
	table.game = _fresh_game()
	table.game.hands[1] = [Card.new(6, Card.Suit.CLUBS)]
	table.game.declared[1] = true
	table._process(0.016)
	_ok(table.opponent_banner.visible, "opponent banner appears when declared[1] turns true")
	_ok(table.opponent_banner_label.text == "OPPONENT: NIKO KADI!", "opponent banner text")
	_ok(not table.player_banner.visible, "player banner hidden while only opponent declared")

	table.game.declared[1] = false
	table.game.hands[0] = [Card.new(6, Card.Suit.CLUBS)]
	table.game.declared[0] = true
	table._process(0.016)
	_ok(table.player_banner.visible, "player banner appears for my declaration")
	_ok(table.player_banner_label.text == "YOU: NIKO KADI!", "player banner text")

	table.game.declared[0] = false
	table._process(0.016)
	_ok(not table.player_banner.visible and not table.opponent_banner.visible, "banners hide when declarations clear")

	# --- J/K declaration: 2s pause before auto-accept, no counter held ---
	table.game = _fresh_game()
	table.game.hands[0] = [Card.new(5, Card.Suit.HEARTS), Card.new(6, Card.Suit.DIAMONDS)]
	table.game.hands[1] = [Card.new(4, Card.Suit.CLUBS)]
	table.game.declared[1] = true
	table.game.pending_jump_rank = 11
	table.game.pending_jump_by = 1
	table._jump_state_active = false
	table._show_deal()
	table._update_ui_state()
	var start := Time.get_ticks_msec()
	_ok(table.jump_notice_panel.visible, "jump notice shows during the pause")
	_ok(table.jump_notice_label.text == table.OPP_JUMP_NOTICE, "jump notice text")
	await create_timer(1.0).timeout
	_ok(table.game.pending_jump_rank == 11, "skip not accepted during first second")
	await create_timer(1.3).timeout
	var elapsed := Time.get_ticks_msec() - start
	_ok(table.game.pending_jump_rank == 0, "skip accepted after the pause")
	_ok(elapsed >= 2000, "pause lasted at least 2 seconds (was %d ms)" % elapsed)
	_ok(table.opponent_banner.visible, "opponent banner still visible after the jump declaration")

	# --- J/K declaration with a counter: 3s tap window ---
	table.game = _fresh_game()
	table.game.hands[0] = [Card.new(13, Card.Suit.HEARTS), Card.new(6, Card.Suit.DIAMONDS)]
	table.game.hands[1] = [Card.new(4, Card.Suit.CLUBS)]
	table.game.declared[1] = true
	table.game.pending_jump_rank = 13
	table.game.pending_jump_by = 1
	table._jump_state_active = false
	table._show_deal()
	table._update_ui_state()
	await create_timer(2.2).timeout
	_ok(table.game.pending_jump_rank == 13, "counter held: still waiting after the 2s pause")
	_ok(table.accept_skip_button.visible, "Accept skip button shown while waiting for a tap")
	await create_timer(3.2).timeout
	_ok(table.game.pending_jump_rank == 0, "counter held: auto-accept after the 3s tap window")

	# Use a fresh table so the previous game's reveal coroutine cannot leak in.
	table.queue_free()
	await process_frame
	table = scene.instantiate() as Table
	root.add_child(table)
	await process_frame

	# --- Final card stays on the table before the result label ---
	table.game = _fresh_game()
	table.game.hands[0] = []
	table.game.hands[1] = [Card.new(6, Card.Suit.DIAMONDS)]
	table._game_over_shown = false
	table.game_over_label.visible = false
	table._show_deal()
	table._check_game_over()
	_ok(not table.game_over_label.visible, "result label hidden immediately on win")
	var face_up_views := 0
	for child in table.get_children():
		if child is CardView and child.face_up:
			face_up_views += 1
	_ok(face_up_views >= 1, "final card still on the table")
	await create_timer(1.2).timeout
	_ok(not table.game_over_label.visible, "result still hidden after 1.2s")
	await create_timer(0.5).timeout
	_ok(table.game_over_label.visible and table.game_over_label.text == "You win!", "result label after ~1.5s")

	print("\nUI DECLARATION TESTS %s" % ("PASSED" if passed else "FAILED"))
	quit(0 if passed else 1)
