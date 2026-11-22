class_name Table
extends Node2D

const SCREEN_SIZE := Vector2(720, 1280)
const MARGIN := 40.0
const CARD_SIZE := Vector2(120, 168)
const CARD_VIEW_SCENE := preload("res://scenes/card_view.tscn")
const SIMPLE_BOT := preload("res://scripts/bot/simple_bot.gd")

const SUIT_SYMBOLS := ["♥", "♦", "♣", "♠"]
const SUIT_NAMES := ["Hearts", "Diamonds", "Clubs", "Spades"]

const OPP_JUMP_NOTICE := "Opponent declared Niko Kadi! Counter with a J/K, or you're skipped"
const OPPONENT_BANNER_TEXT := "OPPONENT: NIKO KADI!"
const PLAYER_BANNER_TEXT := "YOU: NIKO KADI!"

var game: GameState
var turn_label: Label
var game_over_label: Label
var notice_banner: Label
var opponent_banner: Panel
var opponent_banner_label: Label
var player_banner: Panel
var player_banner_label: Label
var suit_indicator_panel: Panel
var suit_indicator_label: Label
var suit_picker_overlay: ColorRect
var suit_buttons: Array[Button] = []
var niko_kadi_button: Button
var niko_kadi_hint: Label
var is_niko_kadi_declared: bool = false
var accept_skip_button: Button
var jump_notice_panel: Panel
var jump_notice_label: Label
var _last_seen_top_card: Card = null
var _opp_had_penalty: bool = false
var _answer_timer_token: int = 0

var _game_over_shown: bool = false
var _game_over_result: int = 0
var _jump_state_active: bool = false
var _jump_flow_token: int = 0
var _jump_waiting_for_input: bool = false
var _jump_pause_active: bool = false
var _opp_declare_seen: bool = false
var _my_declare_seen: bool = false
var _opp_declare_until_msec: int = 0
var _my_declare_until_msec: int = 0
var _pulse_time: float = 0.0

var input_enabled: bool = true
var my_hand_views: Array[CardView] = []
var draw_pile_view: CardView = null

func _ready() -> void:
	game = GameState.new()
	game.start_game()
	
	turn_label = Label.new()
	turn_label.text = "Your turn"
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_label.size = Vector2(720, 44)
	turn_label.position = Vector2(0, 470)
	turn_label.add_theme_font_size_override("font_size", 22)
	turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(turn_label)
	
	game_over_label = Label.new()
	game_over_label.text = ""
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.size = Vector2(720, 40)
	game_over_label.position = Vector2(0, 600)
	game_over_label.add_theme_font_size_override("font_size", 48)
	game_over_label.modulate = Color(1, 0.2, 0.2)
	game_over_label.visible = false
	game_over_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(game_over_label)
	
	notice_banner = Label.new()
	notice_banner.text = ""
	notice_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_banner.size = Vector2(720, 44)
	notice_banner.position = Vector2(0, 520)
	notice_banner.add_theme_font_size_override("font_size", 26)
	notice_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_banner.visible = false
	notice_banner.z_index = 50
	add_child(notice_banner)
	
	_create_declaration_banners()
	_create_jump_notice()
	_create_suit_indicator()
	_create_suit_picker()
	_create_niko_kadi_button()
	_create_accept_skip_button()
	
	_last_seen_top_card = game.top_card()
	_show_deal()
	_update_turn_label()
	_update_suit_indicator()
	_update_ui_state()
	_maybe_start_bot()

func _create_suit_indicator() -> void:
	suit_indicator_panel = Panel.new()
	suit_indicator_panel.size = Vector2(140, 68)
	suit_indicator_panel.position = Vector2(SCREEN_SIZE.x / 2.0 + CARD_SIZE.x + 16.0, SCREEN_SIZE.y / 2.0 - 34.0)
	suit_indicator_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.95, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 3
	suit_indicator_panel.add_theme_stylebox_override("panel", style)
	add_child(suit_indicator_panel)
	
	suit_indicator_label = Label.new()
	suit_indicator_label.size = Vector2(140, 68)
	suit_indicator_label.position = Vector2.ZERO
	suit_indicator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	suit_indicator_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	suit_indicator_label.add_theme_font_size_override("font_size", 20)
	suit_indicator_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	suit_indicator_panel.add_child(suit_indicator_label)

func _create_suit_picker() -> void:
	suit_picker_overlay = ColorRect.new()
	suit_picker_overlay.size = SCREEN_SIZE
	suit_picker_overlay.color = Color(0, 0, 0, 0.7)
	suit_picker_overlay.visible = false
	suit_picker_overlay.z_index = 100
	suit_picker_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(suit_picker_overlay)
	
	var title := Label.new()
	title.text = "Choose a Suit"
	title.size = Vector2(720, 50)
	title.position = Vector2(0, 380)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	suit_picker_overlay.add_child(title)
	
	var btn_size := Vector2(140, 130)
	var positions := [
		Vector2(210, 460), # Hearts
		Vector2(370, 460), # Diamonds
		Vector2(210, 610), # Clubs
		Vector2(370, 610)  # Spades
	]
	
	for s in 4:
		var btn := Button.new()
		btn.text = "%s\n%s" % [SUIT_SYMBOLS[s], SUIT_NAMES[s]]
		btn.size = btn_size
		btn.position = positions[s]
		btn.add_theme_font_size_override("font_size", 28)
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var style_normal := StyleBoxFlat.new()
		style_normal.bg_color = Color(0.96, 0.96, 0.96)
		style_normal.corner_radius_top_left = 12
		style_normal.corner_radius_top_right = 12
		style_normal.corner_radius_bottom_left = 12
		style_normal.corner_radius_bottom_right = 12
		style_normal.shadow_color = Color(0, 0, 0, 0.3)
		style_normal.shadow_size = 4
		btn.add_theme_stylebox_override("normal", style_normal)
		
		if s == 0 or s == 1:
			btn.add_theme_color_override("font_color", Color(0.85, 0.1, 0.1))
		else:
			btn.add_theme_color_override("font_color", Color(0.12, 0.12, 0.12))
		
		suit_picker_overlay.add_child(btn)
		suit_buttons.append(btn)

func _create_niko_kadi_button() -> void:
	niko_kadi_button = Button.new()
	niko_kadi_button.text = "Niko Kadi: OFF"
	niko_kadi_button.size = Vector2(170, 42)
	niko_kadi_button.position = Vector2(40.0, 1005.0)
	niko_kadi_button.add_theme_font_size_override("font_size", 20)
	niko_kadi_button.visible = false
	niko_kadi_button.z_index = 20
	niko_kadi_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_niko_kadi_button_style()
	add_child(niko_kadi_button)
	
	niko_kadi_hint = Label.new()
	niko_kadi_hint.text = "Switch ON, then play a card to declare."
	niko_kadi_hint.size = Vector2(460, 42)
	niko_kadi_hint.position = Vector2(225.0, 1005.0)
	niko_kadi_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	niko_kadi_hint.add_theme_font_size_override("font_size", 18)
	niko_kadi_hint.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	niko_kadi_hint.visible = false
	niko_kadi_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	niko_kadi_hint.z_index = 20
	add_child(niko_kadi_hint)

func _create_accept_skip_button() -> void:
	accept_skip_button = Button.new()
	accept_skip_button.text = "Accept skip"
	accept_skip_button.size = Vector2(170, 42)
	accept_skip_button.position = Vector2((SCREEN_SIZE.x - 170.0) / 2.0, 520.0)
	accept_skip_button.add_theme_font_size_override("font_size", 20)
	accept_skip_button.visible = false
	accept_skip_button.z_index = 20
	accept_skip_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.92, 0.92)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_size = 2
	style.shadow_color = Color(0, 0, 0, 0.25)
	accept_skip_button.add_theme_stylebox_override("normal", style)
	accept_skip_button.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
	add_child(accept_skip_button)

func _update_niko_kadi_button_style() -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_size = 2
	style.shadow_color = Color(0, 0, 0, 0.25)
	
	if is_niko_kadi_declared:
		niko_kadi_button.text = "Niko Kadi: ON"
		style.bg_color = Color(0.2, 0.75, 0.25)
		niko_kadi_button.add_theme_color_override("font_color", Color.WHITE)
	else:
		niko_kadi_button.text = "Niko Kadi: OFF"
		style.bg_color = Color(0.92, 0.92, 0.92)
		niko_kadi_button.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
		
	niko_kadi_button.add_theme_stylebox_override("normal", style)

func _create_declaration_banners() -> void:
	opponent_banner = _make_declaration_banner(OPPONENT_BANNER_TEXT, Color(0.62, 0.05, 0.08), Vector2(10.0, 8.0))
	opponent_banner_label = opponent_banner.get_child(0) as Label
	player_banner = _make_declaration_banner(PLAYER_BANNER_TEXT, Color(0.04, 0.42, 0.14), Vector2(SCREEN_SIZE.x - 330.0, 8.0))
	player_banner_label = player_banner.get_child(0) as Label


func _make_declaration_banner(text: String, bg: Color, pos: Vector2) -> Panel:
	var panel := Panel.new()
	panel.size = Vector2(320, 76)
	panel.position = pos
	panel.z_index = 200
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(1, 1, 1, 0.9)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = panel.size
	label.position = Vector2.ZERO
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	add_child(panel)
	return panel


func _create_jump_notice() -> void:
	jump_notice_panel = Panel.new()
	jump_notice_panel.size = Vector2(700, 100)
	jump_notice_panel.position = Vector2(10, 560)
	jump_notice_panel.z_index = 210
	jump_notice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jump_notice_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.94)
	style.border_color = Color(1, 0.75, 0.2)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	jump_notice_panel.add_theme_stylebox_override("panel", style)

	jump_notice_label = Label.new()
	jump_notice_label.text = OPP_JUMP_NOTICE
	jump_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jump_notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	jump_notice_label.size = jump_notice_panel.size
	jump_notice_label.position = Vector2.ZERO
	jump_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	jump_notice_label.add_theme_font_size_override("font_size", 28)
	jump_notice_label.add_theme_color_override("font_color", Color.WHITE)
	jump_notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jump_notice_panel.add_child(jump_notice_label)
	add_child(jump_notice_panel)


func _process(delta: float) -> void:
	# Catch the exact frame a declaration appears, even if no UI refresh follows.
	var opp_declared := game.has_declared(1)
	if opp_declared and not _opp_declare_seen:
		_opp_declare_seen = true
		_opp_declare_until_msec = Time.get_ticks_msec() + 2500
	elif not opp_declared:
		_opp_declare_seen = false

	var my_declared := game.has_declared(0)
	if my_declared and not _my_declare_seen:
		_my_declare_seen = true
		_my_declare_until_msec = Time.get_ticks_msec() + 2500
	elif not my_declared:
		_my_declare_seen = false

	_update_declaration_banner()
	_check_jump_state()

	# Pulse/flash so the banner cannot be mistaken for a static HUD element.
	_pulse_time += delta
	var wave := 0.5 + 0.5 * sin(_pulse_time * 8.0)
	for banner in [opponent_banner, player_banner]:
		if banner.visible:
			banner.modulate = Color(1, 1, 1, 0.65 + 0.35 * wave)
			banner.scale = Vector2.ONE * (1.0 + 0.02 * wave)


func _update_declaration_banner() -> void:
	if game_over_label.visible:
		opponent_banner.visible = false
		player_banner.visible = false
		return

	# During the final-card reveal keep a fresh declaration on screen so the
	# winning play cannot wipe it out before the player has time to read it.
	var in_final_reveal := _game_over_shown and not game_over_label.visible
	var now := Time.get_ticks_msec()
	opponent_banner.visible = game.has_declared(1) or (in_final_reveal and now < _opp_declare_until_msec)
	player_banner.visible = game.has_declared(0) or (in_final_reveal and now < _my_declare_until_msec)

func _update_ui_state() -> void:
	if game.is_game_over() != 0:
		niko_kadi_button.visible = false
		niko_kadi_hint.visible = false
		accept_skip_button.visible = false
		_update_declaration_banner()
		return

	var show_niko = (game.hands[0].size() == 2 and game.current_player == 0 and game.has_legal_move(0) and not game.awaiting_suit_choice)
	niko_kadi_button.visible = show_niko
	niko_kadi_hint.visible = show_niko
	if not show_niko and is_niko_kadi_declared:
		is_niko_kadi_declared = false
		_update_niko_kadi_button_style()

	_update_declaration_banner()
	_check_jump_state()

func _check_jump_state() -> void:
	var active := game.current_player == 0 and game.pending_jump_rank != 0 and game.is_game_over() == 0
	if not active:
		_jump_state_active = false
		_jump_flow_token += 1
		_jump_waiting_for_input = false
		_jump_pause_active = false
		accept_skip_button.visible = false
		jump_notice_panel.visible = false
		return
	if _jump_state_active:
		return
	_jump_state_active = true
	_start_jump_flow()


func _start_jump_flow() -> void:
	_jump_flow_token += 1
	var token := _jump_flow_token
	var opponent_declared_jump := game.has_declared(1)

	# A declared J/K never resolves instantly: hold the skip for two seconds so
	# the banner and the counter prompt are readable before anything can end.
	if opponent_declared_jump:
		_jump_pause_active = true
		accept_skip_button.visible = false
		jump_notice_panel.visible = true
		_update_turn_label()
		await get_tree().create_timer(2.0).timeout
		if token != _jump_flow_token:
			return
		_jump_pause_active = false

	if game.current_player != 0 or game.pending_jump_rank == 0 or game.is_game_over() != 0:
		_cancel_jump_flow()
		return

	if game.has_legal_move(0):
		# Counter held: give the player three seconds to tap J/K or Accept skip.
		_jump_waiting_for_input = true
		accept_skip_button.visible = true
		jump_notice_panel.visible = true
		_update_turn_label()
		await get_tree().create_timer(3.0).timeout
		if token != _jump_flow_token:
			return
		if _jump_waiting_for_input and game.current_player == 0 and game.pending_jump_rank != 0 and game.is_game_over() == 0:
			_do_accept_skip()
	else:
		_do_accept_skip()


func _cancel_jump_flow() -> void:
	_jump_flow_token += 1
	_jump_waiting_for_input = false
	_jump_pause_active = false
	jump_notice_panel.visible = false


func _do_accept_skip() -> void:
	_cancel_jump_flow()
	if game.current_player != 0 or game.pending_jump_rank == 0 or game.is_game_over() != 0:
		return
	if not game.accept_jump(0):
		return
	_show_deal()
	_update_turn_label()
	_update_suit_indicator()
	_update_ui_state()
	_check_game_over()
	_maybe_start_bot()

func _on_niko_kadi_toggled() -> void:
	if not input_enabled or game.current_player != 0 or game.hands[0].size() != 2:
		return
	is_niko_kadi_declared = not is_niko_kadi_declared
	_update_niko_kadi_button_style()

func _on_accept_skip_clicked() -> void:
	if not input_enabled or game.current_player != 0 or game.pending_jump_rank == 0:
		return
	_do_accept_skip()

func _update_suit_indicator() -> void:
	var s: int = game.current_suit
	suit_indicator_label.text = "Suit:\n%s %s" % [SUIT_SYMBOLS[s], SUIT_NAMES[s]]
	if s == 0 or s == 1:
		suit_indicator_label.add_theme_color_override("font_color", Color(0.85, 0.1, 0.1))
	else:
		suit_indicator_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.12))

func _show_suit_picker() -> void:
	suit_picker_overlay.visible = true

func _on_suit_chosen(suit: int) -> void:
	if not game.choose_suit(0, suit):
		return
	suit_picker_overlay.visible = false
	_show_deal()
	_update_turn_label()
	_update_suit_indicator()
	_update_ui_state()
	_check_game_over()
	_maybe_start_bot()

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	if not input_enabled or game.current_player != 0 or game.is_game_over() != 0:
		return

	var click_pos: Vector2 = get_canvas_transform().affine_inverse() * event.position

	# While the suit picker is showing, handle its buttons and ignore clicks on cards and draw pile
	if suit_picker_overlay.visible:
		for s in 4:
			var btn := suit_buttons[s]
			if btn.get_global_rect().has_point(click_pos):
				_on_suit_chosen(s)
				return
		return

	if accept_skip_button.visible and accept_skip_button.get_global_rect().has_point(click_pos):
		_on_accept_skip_clicked()
		return

	if niko_kadi_button.visible and niko_kadi_button.get_global_rect().has_point(click_pos):
		_on_niko_kadi_toggled()
		return

	for i in range(my_hand_views.size() - 1, -1, -1):
		var cv := my_hand_views[i]
		var rect := Rect2(cv.position - CARD_SIZE / 2.0, CARD_SIZE)
		if rect.has_point(click_pos):
			_on_card_clicked(cv.card)
			return

	var draw_rect := Rect2(draw_pile_view.position - CARD_SIZE / 2.0, CARD_SIZE)
	if draw_rect.has_point(click_pos):
		_on_draw_pile_clicked()
		return

func _show_deal() -> void:
	_clear_table()
	
	# My hand face-up along the bottom with 40px margin above bottom edge.
	_place_hand(game.hands[0], true, SCREEN_SIZE.y - MARGIN - CARD_SIZE.y / 2.0)
	# Opponent's hand face-down along the top with 40px margin below top edge.
	_place_hand(game.hands[1], false, MARGIN + CARD_SIZE.y / 2.0)
	# Top discard card face-up in the middle.
	_add_card_view(
		game.top_card(),
		true,
		Vector2(
			SCREEN_SIZE.x / 2.0 + CARD_SIZE.x / 2.0 + 12.0,
			SCREEN_SIZE.y / 2.0,
		),
	)
	# Face-down draw pile beside the discard card.
	draw_pile_view = _add_card_view(
		null,
		false,
		Vector2(
			SCREEN_SIZE.x / 2.0 - CARD_SIZE.x / 2.0 - 12.0,
			SCREEN_SIZE.y / 2.0,
		),
	)

func _clear_table() -> void:
	for child in get_children():
		if child is CardView:
			child.queue_free()
	my_hand_views.clear()
	draw_pile_view = null

func _update_turn_label() -> void:
	if game.is_game_over() != 0:
		return
	if game.current_player == 0:
		if game.pending_penalty > 0:
			turn_label.text = "Pick up %d, or stack a 2/3, or block with an Ace" % game.pending_penalty
		elif game.pending_jump_rank != 0:
			if _jump_pause_active or _jump_waiting_for_input:
				turn_label.text = "Counter with a J/K, or accept skip"
			elif game.has_legal_move(0):
				var r = "J" if game.pending_jump_rank == 11 else "K"
				turn_label.text = "Counter with a %s, or accept skip" % r
			else:
				turn_label.text = "You were skipped"
		elif game.awaiting_answer:
			pass
		elif game.awaiting_suit_choice:
			turn_label.text = "Choose a suit"
		elif not game.has_legal_move(0):
			turn_label.text = "No playable card: tap the draw pile"
		else:
			turn_label.text = "Your turn"
	else:
		turn_label.text = "Opponent's turn"

func _maybe_start_bot() -> void:
	if game.current_player == 1 and input_enabled and game.is_game_over() == 0:
		_opp_had_penalty = (game.pending_penalty > 0)
		var bot = SIMPLE_BOT.new()
		await bot.take_turn(game, get_tree(), _on_bot_step)
		_on_bot_step()
		if game.current_player == 0:
			_check_jump_state()

func _on_bot_step() -> void:
	var current_top = game.top_card()
	if current_top != _last_seen_top_card and current_top.rank == 14:
		if _opp_had_penalty:
			_show_notice("Opponent blocked with an Ace")
		elif game.current_player == 0:
			_show_opponent_notice()
	_opp_had_penalty = (game.pending_penalty > 0)
	_last_seen_top_card = current_top
	
	_show_deal()
	_update_turn_label()
	_update_suit_indicator()
	_update_ui_state()
	_check_game_over()

func _show_notice(text: String) -> void:
	notice_banner.text = text
	notice_banner.add_theme_color_override("font_color", Color.WHITE)
	notice_banner.visible = true
	var timer := get_tree().create_timer(2.0)
	await timer.timeout
	if notice_banner.text == text:
		notice_banner.visible = false

func _show_opponent_notice() -> void:
	var s: int = game.current_suit
	notice_banner.text = "Opponent chose %s" % SUIT_SYMBOLS[s]
	if s == 0 or s == 1:
		notice_banner.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		notice_banner.add_theme_color_override("font_color", Color.WHITE)
	notice_banner.visible = true
	var timer := get_tree().create_timer(2.0)
	await timer.timeout
	if notice_banner.text == "Opponent chose %s" % SUIT_SYMBOLS[s]:
		notice_banner.visible = false

func _start_answer_countdown() -> void:
	_answer_timer_token += 1
	var token := _answer_timer_token
	
	if not game.has_legal_move(0):
		turn_label.text = "No answer: pick up"
		await get_tree().create_timer(1.0).timeout
		if _answer_timer_token != token:
			return
		if game.awaiting_answer and game.current_player == 0 and game.is_game_over() == 0:
			game.pick_up(0)
			is_niko_kadi_declared = false
			_update_niko_kadi_button_style()
			_show_deal()
			_update_turn_label()
			_update_suit_indicator()
			_update_ui_state()
			_check_game_over()
			_maybe_start_bot()
		return
		
	for remaining in [3, 2, 1]:
		if _answer_timer_token != token:
			return
		turn_label.text = "Drop an answer: %d" % remaining
		await get_tree().create_timer(1.0).timeout
		
	if _answer_timer_token != token:
		return
		
	if game.awaiting_answer and game.current_player == 0 and game.is_game_over() == 0:
		turn_label.text = "Time's up: you pick up 1 card"
		_show_notice("Time's up: you pick up 1 card")
		game.pick_up(0)
		is_niko_kadi_declared = false
		_update_niko_kadi_button_style()
		_show_deal()
		_update_turn_label()
		_update_suit_indicator()
		_update_ui_state()
		_check_game_over()
		_maybe_start_bot()

func _on_card_clicked(card: Card) -> bool:
	if not input_enabled or game.current_player != 0 or game.is_game_over() != 0 or game.awaiting_suit_choice:
		return false
	var had_penalty := game.pending_penalty > 0
	if game.play_card(0, card, is_niko_kadi_declared):
		_cancel_jump_flow()
		_answer_timer_token += 1
		is_niko_kadi_declared = false
		_update_niko_kadi_button_style()
		_show_deal()
		_update_turn_label()
		_update_suit_indicator()
		_update_ui_state()
		_check_game_over()
		if card.rank == 14 and had_penalty:
			_show_notice("Ace blocked the penalty")
			if game.current_player == 1:
				_maybe_start_bot()
		elif game.awaiting_suit_choice and game.current_player == 0:
			_show_suit_picker()
		elif game.awaiting_answer and game.current_player == 0:
			_start_answer_countdown()
		elif game.current_player == 1:
			_maybe_start_bot()
		elif game.current_player == 0 and game.pending_jump_rank != 0:
			_check_jump_state()
		return true
	else:
		# Illegal move - shake the card
		_shake_card(card)
		return false

func _on_draw_pile_clicked() -> void:
	if not input_enabled or game.current_player != 0 or game.is_game_over() != 0 or game.awaiting_suit_choice or game.pending_jump_rank != 0:
		return
	_answer_timer_token += 1
	game.pick_up(0)
	is_niko_kadi_declared = false
	_update_niko_kadi_button_style()
	_show_deal()
	_update_turn_label()
	_update_suit_indicator()
	_update_ui_state()
	_check_game_over()
	_maybe_start_bot()

func _shake_card(card: Card) -> void:
	for child in get_children():
		if child is CardView and child.card == card and child.face_up:
			var cv := child as CardView
			var orig_x: float = cv.position.x
			var tween := create_tween()
			tween.tween_property(cv, "position:x", orig_x + 10.0, 0.05)
			tween.tween_property(cv, "position:x", orig_x - 10.0, 0.05)
			tween.tween_property(cv, "position:x", orig_x + 10.0, 0.05)
			tween.tween_property(cv, "position:x", orig_x - 10.0, 0.05)
			tween.tween_property(cv, "position:x", orig_x, 0.05)
			break

func _check_game_over() -> void:
	if _game_over_shown:
		return
	var result := game.is_game_over()
	if result == 0:
		return
	_game_over_shown = true
	_game_over_result = result
	input_enabled = false
	_cancel_jump_flow()
	_show_deal()  # leave the winning card on the table during the reveal
	_update_ui_state()
	_update_declaration_banner()

	# Never flash the result instantly: let the final card sit for ~1.5 seconds.
	await get_tree().create_timer(1.5).timeout
	game_over_label.text = "You win!" if result == 1 else "You lose!"
	game_over_label.visible = true
	_update_declaration_banner()

# Instantiate the scene (not just the script) so the CardView has its Sprite2D,
# and add it to the tree before set_card() so @onready is assigned.
func _add_card_view(p_card, p_face_up: bool, p_position: Vector2) -> CardView:
	var cv := CARD_VIEW_SCENE.instantiate() as CardView
	cv.position = p_position
	add_child(cv)
	cv.set_card(p_card, p_face_up)
	return cv

# Places hand cards evenly spaced along `y`, overlapping if they don't fit.
func _place_hand(hand, face_up: bool, y: float) -> void:
	var count: int = hand.size()
	if count == 0:
		return
	var usable := SCREEN_SIZE.x - MARGIN * 2.0
	var spacing := CARD_SIZE.x
	if count > 1:
		spacing = clamp((usable - CARD_SIZE.x) / (count - 1), 0.0, CARD_SIZE.x)
	var x := MARGIN + CARD_SIZE.x / 2.0
	for card in hand:
		var cv := _add_card_view(card, face_up, Vector2(x, y))
		if face_up and hand == game.hands[0]:
			my_hand_views.append(cv)
		x += spacing
