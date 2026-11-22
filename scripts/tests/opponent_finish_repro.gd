extends SceneTree

# Headless reproduction of the opponent's finish.
# Every rule action is traced through TracedGame so the log shows the exact
# declare flag, declared[1]/unlocked[1], and the action that ended the game.

const SUITS := ["H", "D", "C", "S"]

var _failed := false


func _bot_step() -> void:
	pass


class TracedGame extends GameState:
	var trace: Array[String] = []
	var ended_by: String = ""
	var winner: int = 0

	var _hands_declared: Array[bool] = [false, false]

	func _state_line(prefix: String) -> void:
		var top := "none"
		if not discard_pile.is_empty():
			top = str(top_card())
		trace.append("%s | declared[1]=%s unlocked[1]=%s declared[0]=%s unlocked[0]=%s cur=%d jump=%d top=%s hands=%d/%d" % [
			prefix,
			str(declared[1]), str(unlocked[1]), str(declared[0]), str(unlocked[0]),
			current_player, pending_jump_rank, top,
			hands[0].size(), hands[1].size(),
		])
		if winner == 0 and is_game_over() != 0:
			winner = is_game_over()
			ended_by = prefix
			trace.append(">>> GAME ENDED by: %s (winner=%d: %s)" % [
				prefix, winner, ("you" if winner == 1 else "opponent")
			])

	func hand_text(player: int) -> String:
		var parts: Array[String] = []
		for c in hands[player]:
			parts.append(str(c))
		return "[" + ", ".join(parts) + "]"

	func play_card(player: int, card: Card, declare: bool) -> bool:
		var before := hands[player].size()
		var ok := super.play_card(player, card, declare)
		if ok:
			_state_line("ACTION p%d PLAY %s declare=%s hand %d->%d" % [
				player, str(card), str(declare), before, hands[player].size()
			])
		else:
			trace.append("ACTION p%d ILLEGAL PLAY %s declare=%s" % [player, str(card), str(declare)])
		return ok

	func pick_up(player: int) -> void:
		super.pick_up(player)
		_state_line("ACTION p%d PICKUP" % player)

	func accept_jump(player: int) -> bool:
		var ok := super.accept_jump(player)
		if ok:
			_state_line("ACTION p%d ACCEPT_JUMP" % player)
		else:
			trace.append("ACTION p%d ACCEPT_JUMP REJECTED" % player)
		return ok

	func choose_suit(player: int, suit: int, declare: bool) -> bool:
		var ok := super.choose_suit(player, suit, declare)
		if ok:
			_state_line("ACTION p%d CHOOSE_SUIT %s" % [player, SUITS[suit]])
		return ok


func _initialize() -> void:
	# SimpleBot uses 1-second SceneTree timers; scale time so a full game is quick.
	Engine.time_scale = 100.0
	await _run()


func _run() -> void:
	print("=== OPPONENT FINISH REPRODUCTION (headless) ===")
	var normal := await _scenario_normal_route()
	var jump := await _scenario_jump_route()
	var random_game := await _scenario_random_game()
	_failed = not (normal and jump and random_game)
	Engine.time_scale = 1.0
	if _failed:
		print("\nREPRO FAILED")
	else:
		print("\nREPRO COMPLETE")
	quit(1 if _failed else 0)


func _dump(game: TracedGame, title: String) -> void:
	print("\n--- %s ---" % title)
	for line in game.trace:
		print(line)


func _report(game: TracedGame, heading: String) -> void:
	_dump(game, heading)
	var declared_by_bot := false
	var declaration_card := ""
	for line in game.trace:
		if line.begins_with("ACTION p1 PLAY ") and "declare=true" in line:
			declared_by_bot = true
			declaration_card = line
	var route := "NONE / no finish"
	if game.winner == 2:
		route = "J/K (jump) route" if declaration_card != "" and ("PLAY J" in declaration_card or "PLAY K" in declaration_card) else "NORMAL route"
	print("SUMMARY %s: bot_declared=%s | %s | ended_by=%s" % [
		heading, str(declared_by_bot), route,
		("none" if game.ended_by == "" else game.ended_by)
	])


func _scenario_normal_route() -> bool:
	var game := TracedGame.new()
	game.start_game()
	game.discard_pile = [Card.new(9, Card.Suit.CLUBS)]
	game.current_suit = Card.Suit.CLUBS
	game.current_player = 1
	game.hands[0] = [Card.new(2, Card.Suit.HEARTS), Card.new(3, Card.Suit.DIAMONDS)]
	game.hands[1] = [Card.new(6, Card.Suit.CLUBS), Card.new(4, Card.Suit.CLUBS)]

	game.trace.append("BOT TURN START hand=%s declared[1]=%s unlocked[1]=%s" % [
		game.hand_text(1), str(game.declared[1]), str(game.unlocked[1])
	])
	var bot := SimpleBot.new()
	await bot.take_turn(game, self, _bot_step)

	game.trace.append("PLAYER ACTION: pick up 1 card (gives opponent a full turn)")
	game.pick_up(0)

	game.trace.append("BOT TURN START hand=%s declared[1]=%s unlocked[1]=%s" % [
		game.hand_text(1), str(game.declared[1]), str(game.unlocked[1])
	])
	await bot.take_turn(game, self, _bot_step)

	_report(game, "Scenario 1: normal finishing card")
	if game.winner != 2:
		print("FAIL: expected opponent win in normal route, got winner=%d" % game.winner)
		return false
	return true


func _scenario_jump_route() -> bool:
	var game := TracedGame.new()
	game.start_game()
	game.discard_pile = [Card.new(9, Card.Suit.CLUBS)]
	game.current_suit = Card.Suit.CLUBS
	game.current_player = 1
	# No J/K counter in my hand, so the skip must be accepted on my behalf.
	game.hands[0] = [Card.new(5, Card.Suit.HEARTS), Card.new(6, Card.Suit.DIAMONDS)]
	game.hands[1] = [Card.new(11, Card.Suit.CLUBS), Card.new(4, Card.Suit.CLUBS)]

	game.trace.append("BOT TURN START hand=%s declared[1]=%s unlocked[1]=%s" % [
		game.hand_text(1), str(game.declared[1]), str(game.unlocked[1])
	])
	var bot := SimpleBot.new()
	await bot.take_turn(game, self, _bot_step)

	game.trace.append("JUMP STATE: pending_jump_rank=%d current_player=%d declared[1]=%s unlocked[1]=%s" % [
		game.pending_jump_rank, game.current_player, str(game.declared[1]), str(game.unlocked[1])
	])
	game.trace.append("PLAYER ACTION: accept skip (no J/K counter held)")
	if not game.accept_jump(0):
		print("FAIL: accept_jump(0) rejected in jump route")
		return false

	game.trace.append("BOT TURN START hand=%s declared[1]=%s unlocked[1]=%s" % [
		game.hand_text(1), str(game.declared[1]), str(game.unlocked[1])
	])
	await bot.take_turn(game, self, _bot_step)

	_report(game, "Scenario 2: J/K jump declaration")
	if game.winner != 2:
		print("FAIL: expected opponent win in jump route, got winner=%d" % game.winner)
		return false
	return true


func _scenario_random_game() -> bool:
	for seed_value in range(1, 41):
		seed(seed_value)
		var game := TracedGame.new()
		game.start_game()
		var bot := SimpleBot.new()
		game.trace.append("BOT TURN START hand=%s declared[1]=%s unlocked[1]=%s" % [
			game.hand_text(1), str(game.declared[1]), str(game.unlocked[1])
		])
		var steps := 0
		while game.is_game_over() == 0 and steps < 200:
			steps += 1
			if game.current_player == 1:
				await bot.take_turn(game, self, _bot_step)
				continue

			# A simple human policy: counter/accept jumps, choose a suit,
			# otherwise play the first legal card or pick up.
			if game.awaiting_suit_choice:
				var counts := [0, 0, 0, 0]
				for c in game.hands[0]:
					counts[c.suit] += 1
				var best := 0
				for s in range(1, 4):
					if counts[s] > counts[best]:
						best = s
				game.choose_suit(0, best, false)
			elif game.pending_jump_rank != 0:
				var countered := false
				for c in game.hands[0]:
					if game.can_play(c):
						game.play_card(0, c, game.hands[0].size() == 2)
						countered = true
						break
				if not countered:
					game.accept_jump(0)
			else:
				var played := false
				for c in game.hands[0]:
					if game.can_play(c):
						game.play_card(0, c, game.hands[0].size() == 2)
						played = true
						break
				if not played:
					game.pick_up(0)

			if game.current_player == 1 and game.is_game_over() == 0:
				game.trace.append("BOT TURN START hand=%s declared[1]=%s unlocked[1]=%s" % [
					game.hand_text(1), str(game.declared[1]), str(game.unlocked[1])
				])

		_dump(game, "Scenario 3: seeded full game (seed=%d, winner=%d)" % [seed_value, game.winner])
		print("SUMMARY Scenario 3: seed=%d winner=%d ended_by=%s" % [
			seed_value, game.winner, ("none" if game.ended_by == "" else game.ended_by)
		])
		if game.winner == 2:
			var declared_by_bot := false
			for line in game.trace:
				if line.begins_with("ACTION p1 PLAY ") and "declare=true" in line:
					declared_by_bot = true
			print("SUMMARY Scenario 3: bot_declared=%s" % str(declared_by_bot))
			return true
		if steps >= 200:
			print("FAIL: random game did not terminate (seed=%d)" % seed_value)
			return false
	return true
