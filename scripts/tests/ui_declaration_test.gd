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
	_ok(table.jump_notice_label.text == table.OPP_JUMP_DECLARED_NOTICE, "jump notice text")
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
	table.game.winner = 1
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

	# --- Niko Kadi toggle is reachable before, and stays armed through, a chain ---
	table.queue_free()
	await process_frame
	table = scene.instantiate() as Table
	root.add_child(table)
	await process_frame
	table.game = _fresh_game()
	table.game.discard_pile = [Card.new(7, Card.Suit.SPADES)]
	table.game.current_suit = Card.Suit.SPADES
	var ten_s := Card.new(10, Card.Suit.SPADES)
	var ten_h := Card.new(10, Card.Suit.HEARTS)
	table.game.hands[0] = [ten_s, ten_h, Card.new(5, Card.Suit.CLUBS)]
	table.game.hands[1] = [Card.new(4, Card.Suit.CLUBS), Card.new(6, Card.Suit.CLUBS)]
	table.is_niko_kadi_declared = false
	table._niko_offer_seen = false
	table.staged_chain.clear()
	table._show_deal()
	table._update_ui_state()
	_ok(table.niko_kadi_button.visible, "Niko Kadi toggle shown for a 3-card chain finish")
	_ok(table.notice_banner.text == "Niko Kadi available: switch ON, then play to declare",
		"Niko Kadi availability prompt shown")
	table._on_niko_kadi_toggled()
	_ok(table.is_niko_kadi_declared, "Niko Kadi can be armed before staging the chain")
	table._on_card_clicked(ten_s)
	_ok(table.niko_kadi_button.visible and table.is_niko_kadi_declared,
		"toggle stays visible and armed after staging the first card")
	table._on_card_clicked(ten_h)
	_ok(table.niko_kadi_button.visible and table.is_niko_kadi_declared,
		"toggle stays visible and armed after staging the full chain")
	var staged: Array[Card] = table.staged_chain.duplicate()
	table.staged_chain.clear()
	table._commit_cards(staged)
	_ok(table.game.declared[0] and table.game.hands[0].size() == 1,
		"chain play declares Niko Kadi when armed")

	# --- Empty hand: prompt and draw pile tappable ---
	table.queue_free()
	await process_frame
	table = scene.instantiate() as Table
	root.add_child(table)
	await process_frame
	table.game = _fresh_game()
	table.game.hands[0] = []
	table.game.hands[1] = [Card.new(6, Card.Suit.CLUBS)]
	table._show_deal()
	table._update_turn_label()
	_ok(table.turn_label.text == "You have no cards: tap the draw pile",
		"empty hand shows the draw-pile prompt")
	var draw_rect := Rect2(table.draw_pile_view.position - Table.CARD_SIZE / 2.0, Table.CARD_SIZE)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = draw_rect.position + draw_rect.size / 2.0
	table._input(click)
	_ok(table.game.hands[0].size() == 1, "draw pile tappable with 0 cards")

	# --- Locked hint when the opponent has no cards ---
	table.queue_free()
	await process_frame
	table = scene.instantiate() as Table
	root.add_child(table)
	await process_frame
	table.game = _fresh_game()
	table.game.hands[0] = [Card.new(4, Card.Suit.CLUBS)]
	table.game.hands[1] = []
	table.game.declared[0] = true
	table.game.unlocked[0] = true
	table._show_deal()
	table._process(0.016)
	_ok(table.locked_hint.visible and table.locked_hint.text == "You can't finish while the opponent has no cards",
		"locked hint explains the opponent has no cards")
	table.game.declared[0] = false
	table._process(0.016)
	_ok(table.locked_hint.text.begins_with("Last card locked"), "normal locked hint text restored")

	# --- Bot with 0 cards picks up ---
	var bot_game := _fresh_game()
	bot_game.current_player = 1
	bot_game.hands[0] = [Card.new(6, Card.Suit.CLUBS)]
	bot_game.hands[1] = []
	var bot := SimpleBot.new()
	var step_cb := func() -> void: pass
	await bot.take_turn(bot_game, self, step_cb)
	_ok(bot_game.hands[1].size() == 1, "bot with 0 cards picks up 1")

	print("\nUI DECLARATION TESTS %s" % ("PASSED" if passed else "FAILED"))
	quit(0 if passed else 1)
