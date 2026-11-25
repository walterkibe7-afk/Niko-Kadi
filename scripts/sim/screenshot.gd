extends SceneTree

# Runs the game for a few frames and saves screenshots to user://shots/
func _init() -> void:
	var dir := "user://shots"
	DirAccess.make_dir_recursive_absolute(dir)
	var shot: int = 0

	# Shot 1: opening table
	await process_frame
	var table = load("res://scenes/table.tscn").instantiate()
	root.add_child(table)
	for i in 10:
		await process_frame
	_save(table, "01_open")
	shot += 1

	# Shot 2: mid-game with the Niko Kadi offer toast
	table.game.hands[0] = [Card.new(7, Card.Suit.HEARTS), Card.new(9, Card.Suit.SPADES)]
	table.game.hands[1] = [Card.new(5, Card.Suit.CLUBS), Card.new(6, Card.Suit.DIAMONDS), Card.new(8, Card.Suit.HEARTS)]
	table._show_deal()
	table._update_ui_state()
	for i in 5:
		await process_frame
	_save(table, "02_midgame")
	shot += 1

	# From here on, freeze _process so staged states are not reset.
	table.set_process(false)
	table.notice_banner.visible = false
	table.niko_kadi_button.visible = false
	table.niko_kadi_hint.visible = false

	# Shot 3: suit picker overlay
	table.suit_picker_overlay.visible = true
	table.suit_picker_niko_button.visible = true
	await process_frame
	_save(table, "03_suit_picker")
	shot += 1

	# Shot 4: game over
	table.suit_picker_overlay.visible = false
	table.game_over_label.text = "You win!"
	table.game_over_label.visible = true
	await process_frame
	_save(table, "04_game_over")
	shot += 1

	# Shot 5: jump notice + accept skip
	table.game_over_label.visible = false
	table.jump_notice_label.text = Table.OPP_JUMP_DECLARED_NOTICE
	table.jump_notice_panel.visible = true
	table.accept_skip_button.visible = true
	await process_frame
	_save(table, "05_jump_notice")
	shot += 1

	# Shot 6: both declaration banners
	table.jump_notice_panel.visible = false
	table.accept_skip_button.visible = false
	table.game.declared = [true, true]
	table._update_declaration_banner()
	await process_frame
	_save(table, "06_banners")
	shot += 1

	# Shot 7: sys log open
	table.game.declared = [false, false]
	table._update_declaration_banner()
	table.sys_log_text.append_text("[01] Game started\n[02] You played 7♥\n[03] Opp played 8♣\n[01] Your turn\n")
	table.sys_log_panel.visible = true
	await process_frame
	_save(table, "07_sys_log")
	shot += 1

	print("SHOTS_SAVED %d -> %s" % [shot, ProjectSettings.globalize_path(dir)])
	quit(0)


func _save(table: Node, name: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	var path := "user://shots/%s.png" % name
	img.save_png(path)
	print("SAVED " + path)
