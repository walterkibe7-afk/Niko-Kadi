extends SceneTree

# Headless bot measurements: the old SimpleBot plays against the new SmartBot from
# both seats, so a win rate says which one is better rather than which one moved first.
# `godot --headless --path . --script res://scripts/sim/bot_sim.gd -- 2000`
# The optional argument is the number of games per matchup (default 20000).

const GAMES := 20000
const MAX_STEPS := 3000
const BASE_SEED := 1

const EVENTS := [
	"calling an exact card",
	"(called card)",
	"countered the call with",
	"blocked penalty",
	"declared NIKO KADI",
	"Reshuffled",
	"accepted skip",
]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var games: int = int(args[0]) if args.size() > 0 else GAMES

	_matchup("Smart(0) vs Simple(1)", true, false, games)
	_matchup("Simple(0) vs Smart(1)", false, true, games)
	_matchup("Smart vs Smart (balance)", true, true, games)
	_matchup("Simple vs Simple (baseline)", false, false, games)
	quit()


func _matchup(title: String, smart0: bool, smart1: bool, games: int) -> void:
	var bots: Array = [_bot(smart0), _bot(smart1)]
	var wins := [0, 0]
	var over_limit := [0, 0]
	var total_steps := 0
	var longest := 0
	var events := {}
	for key in EVENTS:
		events[key] = 0

	for g in games:
		seed(BASE_SEED + g)  # a failing game g is reproducible by its seed
		var game := GameState.new()
		game.print_log = false
		game.start_game()
		var expected_cards: int = game.draw_pile.cards.size() + game.discard_pile.size() + game.hands[0].size() + game.hands[1].size()

		var steps := 0
		while game.is_game_over() == 0:
			steps += 1
			assert(steps <= MAX_STEPS, "Game %d (seed %d) did not finish in %d steps" % [g, BASE_SEED + g, MAX_STEPS])
			bots[game.current_player].step(game, game.current_player)
			_check(game, expected_cards, g)

		wins[game.winner - 1] += 1
		if game.over_limit_player != -1:
			over_limit[game.over_limit_player] += 1
		total_steps += steps
		longest = maxi(longest, steps)
		for entry in game.log_entries:
			for key in EVENTS:
				if entry.contains(key):
					events[key] += 1

	var lost_limit: int = over_limit[0] + over_limit[1]
	print("--- %s | %d games ---" % [title, games])
	print("  Seat 0 (moves first): %d (%.1f%%) | Seat 1: %d (%.1f%%)" % [
		wins[0], 100.0 * wins[0] / games, wins[1], 100.0 * wins[1] / games])
	print("  Games won on the card limit: %d (%.1f%%), seat 0 went over %d, seat 1 went over %d" % [
		lost_limit, 100.0 * lost_limit / games, over_limit[0], over_limit[1]])
	print("  Average steps: %d | Longest: %d" % [total_steps / games, longest])
	print("  Rule events: ", events)


func _bot(smart: bool) -> SimpleBot:
	if smart:
		return SmartBot.new()
	return SimpleBot.new()


func _check(game: GameState, expected_cards: int, g: int) -> void:
	var total: int = game.draw_pile.cards.size() + game.discard_pile.size() + game.hands[0].size() + game.hands[1].size()
	assert(total == expected_cards, "Game %d: card count is %d, expected %d" % [g, total, expected_cards])
	var pending := 0
	for flag in [game.awaiting_suit_choice, game.awaiting_call, game.pending_penalty > 0, game.pending_jump_rank != 0, game.call_rank != 0]:
		if flag:
			pending += 1
	assert(pending <= 1, "Game %d: more than one pending state at once" % g)
