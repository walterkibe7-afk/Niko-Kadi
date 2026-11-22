class_name SimpleBot
extends RefCounted

func take_turn(game: GameState, tree: SceneTree) -> void:
	await tree.create_timer(1.0).timeout
	
	if game.current_player != 1:
		return
	
	var played := false
	for card in game.hands[1]:
		if game.can_play(card):
			game.play_card(1, card)
			played = true
			break
	
	if not played:
		game.pick_up(1)
	elif game.awaiting_suit_choice:
		var counts := [0, 0, 0, 0]
		for c in game.hands[1]:
			counts[c.suit] += 1
		var best_suit := 0
		var max_count := -1
		for s in 4:
			if counts[s] > max_count:
				max_count = counts[s]
				best_suit = s
		game.choose_suit(1, best_suit)
