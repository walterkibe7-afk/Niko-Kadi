class_name Table
extends Node2D

const SCREEN_SIZE := Vector2(720, 1280)
const MARGIN := 40.0
const CARD_SIZE := Vector2(120, 168)
const CARD_VIEW_SCENE := preload("res://scenes/card_view.tscn")
const SIMPLE_BOT := preload("res://scripts/bot/simple_bot.gd")

const SUIT_SYMBOLS := ["♥", "♦", "♣", "♠"]
const SUIT_NAMES := ["Hearts", "Diamonds", "Clubs", "Spades"]

var game: GameState
var turn_label: Label
var game_over_label: Label
var notice_banner: Label
var suit_indicator_panel: Panel
var suit_indicator_label: Label
var suit_picker_overlay: ColorRect
var suit_buttons: Array[Button] = []
var niko_kadi_button: Button
var is_niko_kadi_declared: bool = false
var accept_skip_button: Button
var _is_auto_skipping: bool = false
var _last_seen_top_card: Card = null

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
	
	_create_suit_indicator()
	_create_suit_picker()
	_create_niko_kadi_button()
	_create_accept_skip_button()
	
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
		
		var style_normal := StyleBoxFlat.new()
		style_normal.bg_color = Color(0.96, 0.96, 0.96)
		style_normal.corner_radius_top_left = 12
		style_normal.corner_radius_top_right = 12
		style_normal.corner_radius_bottom_left = 12
		style_normal.corner_radius_bottom_right = 12
		style_normal.shadow_color = Color(0, 0, 0, 0.3)
		style_normal.shadow_size = 4
		btn.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover := style_normal.duplicate() as StyleBoxFlat
		style_hover.bg_color = Color(1.0, 1.0, 1.0)
		btn.add_theme_stylebox_override("hover", style_hover)
		
		var style_pressed := style_normal.duplicate() as StyleBoxFlat
		style_pressed.bg_color = Color(0.88, 0.88, 0.88)
		btn.add_theme_stylebox_override("pressed", style_pressed)
		
		if s == 0 or s == 1:
			btn.add_theme_color_override("font_color", Color(0.85, 0.1, 0.1))
			btn.add_theme_color_override("font_hover_color", Color(0.75, 0.05, 0.05))
			btn.add_theme_color_override("font_pressed_color", Color(0.6, 0.0, 0.0))
		else:
			btn.add_theme_color_override("font_color", Color(0.12, 0.12, 0.12))
			btn.add_theme_color_override("font_hover_color", Color(0.25, 0.25, 0.25))
			btn.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0))
		
		btn.pressed.connect(_on_suit_chosen.bind(s))
		suit_picker_overlay.add_child(btn)
		suit_buttons.append(btn)

func _create_niko_kadi_button() -> void:
	niko_kadi_button = Button.new()
	niko_kadi_button.text = "Niko Kadi"
	niko_kadi_button.size = Vector2(170, 42)
	niko_kadi_button.position = Vector2((SCREEN_SIZE.x - 170.0) / 2.0, 1005.0)
	niko_kadi_button.add_theme_font_size_override("font_size", 20)
	niko_kadi_button.visible = false
	niko_kadi_button.z_index = 20
	niko_kadi_button.pressed.connect(_on_niko_kadi_toggled)
	_update_niko_kadi_button_style()
	add_child(niko_kadi_button)

func _create_accept_skip_button() -> void:
	accept_skip_button = Button.new()
	accept_skip_button.text = "Accept skip"
	accept_skip_button.size = Vector2(170, 42)
	accept_skip_button.position = Vector2((SCREEN_SIZE.x - 170.0) / 2.0, 520.0)
	accept_skip_button.add_theme_font_size_override("font_size", 20)
	accept_skip_button.visible = false
	accept_skip_button.z_index = 20
	accept_skip_button.pressed.connect(_on_accept_skip_clicked)
	
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
	
	var style_hover := style.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color(1.0, 1.0, 1.0)
	accept_skip_button.add_theme_stylebox_override("hover", style_hover)
	add_child(accept_skip_button)

func _update_niko_kadi_button_style() -> void:
	if niko_kadi_button == null:
		return
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
		niko_kadi_button.text = "Niko Kadi"
		style.bg_color = Color(0.92, 0.92, 0.92)
		niko_kadi_button.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
		
	niko_kadi_button.add_theme_stylebox_override("normal", style)
	var style_hover := style.duplicate() as StyleBoxFlat
	style_hover.bg_color = style.bg_color.lightened(0.1)
	niko_kadi_button.add_theme_stylebox_override("hover", style_hover)

func _update_ui_state() -> void:
	if game == null or game.is_game_over() != 0:
		if niko_kadi_button != null:
			niko_kadi_button.visible = false
		if accept_skip_button != null:
			accept_skip_button.visible = false
		return

	if niko_kadi_button != null:
		var show_niko = (game.hands[0].size() == 2 and game.current_player == 0 and not game.awaiting_suit_choice)
		niko_kadi_button.visible = show_niko
		if not show_niko and is_niko_kadi_declared:
			is_niko_kadi_declared = false
			_update_niko_kadi_button_style()

	_check_jump_state()

func _check_jump_state() -> void:
	if accept_skip_button == null:
		return
	if game.current_player == 0 and game.pending_jump_rank != 0 and game.is_game_over() == 0:
		if game.has_legal_move(0):
			accept_skip_button.visible = true
		else:
			accept_skip_button.visible = false
			if not _is_auto_skipping:
				_auto_accept_skip()
	else:
		accept_skip_button.visible = false

func _auto_accept_skip() -> void:
	_is_auto_skipping = true
	_update_turn_label()
	await get_tree().create_timer(1.2).timeout
	_is_auto_skipping = false
	if game.current_player == 0 and game.pending_jump_rank != 0 and game.is_game_over() == 0:
		game.accept_jump(0)
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
	if not game.accept_jump(0):
		return
	_show_deal()
	_update_turn_label()
	_update_suit_indicator()
	_update_ui_state()
	_check_game_over()
	_maybe_start_bot()

func _update_suit_indicator() -> void:
	if suit_indicator_label == null or game == null:
		return
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
	if suit_picker_overlay != null and suit_picker_overlay.visible:
		for s in 4:
			var btn := suit_buttons[s]
			if btn.get_global_rect().has_point(click_pos):
				_on_suit_chosen(s)
				return
		return

	if accept_skip_button != null and accept_skip_button.visible and accept_skip_button.get_global_rect().has_point(click_pos):
		_on_accept_skip_clicked()
		return

	if niko_kadi_button != null and niko_kadi_button.visible and niko_kadi_button.get_global_rect().has_point(click_pos):
		_on_niko_kadi_toggled()
		return

	for i in range(my_hand_views.size() - 1, -1, -1):
		var cv := my_hand_views[i]
		if not is_instance_valid(cv):
			continue
		var rect := Rect2(cv.position - CARD_SIZE / 2.0, CARD_SIZE)
		if rect.has_point(click_pos):
			_on_card_clicked(cv.card)
			return

	if draw_pile_view != null and is_instance_valid(draw_pile_view):
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
	if not game.discard_pile.is_empty():
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
	if game == null or game.is_game_over() != 0:
		return
	if game.current_player == 0:
		if game.pending_penalty > 0:
			turn_label.text = "Pick up %d, or stack a 2/3, or block with an Ace" % game.pending_penalty
		elif game.pending_jump_rank != 0:
			if game.has_legal_move(0):
				var r = "J" if game.pending_jump_rank == 11 else "K"
				turn_label.text = "Counter with a %s, or accept skip" % r
			else:
				turn_label.text = "You were skipped"
		elif game.awaiting_answer:
			var s = game.question_suit
			turn_label.text = "Answer with a %s %s card, or pick up" % [SUIT_SYMBOLS[s], SUIT_NAMES[s]]
		elif game.awaiting_suit_choice:
			turn_label.text = "Choose a suit"
		else:
			turn_label.text = "Your turn"
	else:
		turn_label.text = "Opponent's turn"

func _maybe_start_bot() -> void:
	if game.current_player == 1 and input_enabled and game.is_game_over() == 0:
		var bot = SIMPLE_BOT.new()
		await bot.take_turn(game, get_tree(), _on_bot_step)
		_on_bot_step()
		if game.current_player == 0:
			_check_jump_state()

func _on_bot_step() -> void:
	var current_top = game.top_card()
	if current_top != _last_seen_top_card and current_top.rank == 14 and game.current_player == 0:
		_show_opponent_notice()
	_last_seen_top_card = current_top
	
	_show_deal()
	_update_turn_label()
	_update_suit_indicator()
	_update_ui_state()
	_check_game_over()

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
	notice_banner.visible = false

func _on_card_clicked(card: Card) -> bool:
	if not input_enabled or game.current_player != 0 or game.is_game_over() != 0 or game.awaiting_suit_choice:
		return false
	if game.play_card(0, card, is_niko_kadi_declared):
		is_niko_kadi_declared = false
		_update_niko_kadi_button_style()
		_show_deal()
		_update_turn_label()
		_update_suit_indicator()
		_update_ui_state()
		_check_game_over()
		if game.awaiting_suit_choice and game.current_player == 0:
			_show_suit_picker()
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
	var result = game.is_game_over()
	if result == 1:
		input_enabled = false
		game_over_label.text = "You win!"
		game_over_label.visible = true
		_update_ui_state()
	elif result == 2:
		input_enabled = false
		game_over_label.text = "You lose!"
		game_over_label.visible = true
		_update_ui_state()

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
