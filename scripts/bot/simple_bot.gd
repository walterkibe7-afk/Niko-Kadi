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