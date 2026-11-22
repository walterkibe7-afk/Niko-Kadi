class_name Table
extends Node2D

const SCREEN_SIZE := Vector2(720, 1280)
const MARGIN := 40.0
const CARD_SIZE := Vector2(120, 168)
const CARD_VIEW_SCENE := preload("res://scenes/card_view.tscn")
const SIMPLE_BOT := preload("res://scripts/bot/simple_bot.gd")

var game: GameState
var turn_label: Label
var game_over_label: Label
var input_enabled: bool = true

func _ready() -> void:
	game = GameState.new()
	game.start_game()
	
	turn_label = Label.new()
	turn_label.text = "Your turn"
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_label.position = Vector2(SCREEN_SIZE.x / 2.0, 60.0)
	turn_label.add_theme_constant_override("font_size", 24)
	add_child(turn_label)
	
	game_over_label = Label.new()
	game_over_label.text = ""
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.position = Vector2(SCREEN_SIZE.x / 2.0, SCREEN_SIZE.y / 2.0)
	game_over_label.add_theme_constant_override("font_size", 48)
	game_over_label.modulate = Color(1, 0.2, 0.2)
	game_over_label.visible = false
	add_child(game_over_label)
	
	_show_deal()
	_update_turn_label()
	_maybe_start_bot()

func _show_deal() -> void:
	_clear_table()
	
	# My hand face-up along the bottom with 40px margin above bottom edge.
	_place_hand(game.hands[0], true, SCREEN_SIZE.y - MARGIN - CARD_SIZE.y)
	# Opponent's hand face-down along the top with 40px margin below top edge.
	_place_hand(game.hands[1], false, MARGIN)
	# Starter card face-up in the middle.
	_add_card_view(
		game.discard_pile[0],
		true,
		Vector2(
			SCREEN_SIZE.x / 2.0 - CARD_SIZE.x / 2.0,
			SCREEN_SIZE.y / 2.0 - CARD_SIZE.y / 2.0,
		),
	)
	# Face-down draw pile beside the starter card.
	_add_card_view(
		null,
		false,
		Vector2(
			SCREEN_SIZE.x / 2.0 - CARD_SIZE.x * 1.5 - 12.0,
			SCREEN_SIZE.y / 2.0 - CARD_SIZE.y / 2.0,
		),
	)

func _clear_table() -> void:
	for child in get_children():
		if child is CardView:
			child.queue_free()

func _update_turn_label() -> void:
	if game.current_player == 0:
		turn_label.text = "Your turn"
	else:
		turn_label.text = "Opponent's turn"

func _maybe_start_bot() -> void:
	if game.current_player == 1 and input_enabled:
		var bot = SIMPLE_BOT.new()
		bot.take_turn(game, get_tree())
		call_deferred("_on_bot_done")

func _on_bot_done() -> void:
	_show_deal()
	_update_turn_label()
	_check_game_over()
	if input_enabled and game.current_player == 1:
		_maybe_start_bot()

func _on_card_clicked(card: Card) -> void:
	if not input_enabled or game.current_player != 0:
		return
	if game.play_card(0, card):
		_show_deal()
		_update_turn_label()
		_check_game_over()
		_maybe_start_bot()
	else:
		# Illegal move - shake the card
		_shake_card(card)

func _on_draw_pile_clicked() -> void:
	if not input_enabled or game.current_player != 0:
		return
	game.pick_up(0)
	_show_deal()
	_update_turn_label()
	_check_game_over()
	_maybe_start_bot()

func _shake_card(card: Card) -> void:
	for child in get_children():
		if child is CardView and child.card == card and child.face_up:
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(child, "position:x", child.position.x + 10, 0.05)
			tween.tween_property(child, "position:x", child.position.x - 10, 0.05)
			tween.tween_property(child, "position:x", child.position.x + 10, 0.05)
			tween.tween_property(child, "position:x", child.position.x - 10, 0.05)
			tween.tween_property(child, "position:x", child.position.x, 0.05)
			break

func _check_game_over() -> void:
	var result = game.is_game_over()
	if result == 1:
		input_enabled = false
		game_over_label.text = "You win!"
		game_over_label.visible = true
	elif result == 2:
		input_enabled = false
		game_over_label.text = "You lose!"
		game_over_label.visible = true

# Instantiate the scene (not just the script) so the CardView has its Sprite2D,
# and add it to the tree before set_card() so @onready is assigned.
func _add_card_view(p_card, p_face_up: bool, p_position: Vector2) -> CardView:
	var cv := CARD_VIEW_SCENE.instantiate() as CardView
	cv.position = p_position
	add_child(cv)
	cv.set_card(p_card, p_face_up)
	
	if p_face_up and p_card != null:
		cv.gui_input.connect(_on_card_gui_input.bind(cv))
	elif not p_face_up and p_card == null:
		# Draw pile
		cv.gui_input.connect(_on_draw_pile_gui_input.bind(cv))
	
	return cv

func _on_card_gui_input(event: InputEvent, card_view: CardView) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_card_clicked(card_view.card)

func _on_draw_pile_gui_input(event: InputEvent, card_view: CardView) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_draw_pile_clicked()

# Places hand cards evenly spaced along `y`, overlapping if they don't fit.
func _place_hand(hand, face_up: bool, y: float) -> void:
	var count
	count = hand.size()
	if count == 0:
		return
	var usable := SCREEN_SIZE.x - MARGIN * 2.0
	var spacing := CARD_SIZE.x
	if count > 1:
		spacing = clamp((usable - CARD_SIZE.x) / (count - 1), 0.0, CARD_SIZE.x)
	var x := MARGIN
	for card in hand:
		_add_card_view(card, face_up, Vector2(x, y))
		x += spacing