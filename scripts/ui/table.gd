class_name Table
extends Node2D

signal match_finished(player_won: bool)
signal exit_to_dashboard_requested

const SCREEN_SIZE := Vector2(720, 1280)
const MARGIN := 24.0
const CARD_SIZE := Vector2(112, 156)
const OPP_HAND_Y := 236.0
const MY_HAND_Y := 1056.0
const DRAW_POS := Vector2(260.0, 540.0)
const DISCARD_POS := Vector2(460.0, 540.0)

const CARD_VIEW_SCENE := preload("res://scenes/card_view.tscn")
const SIMPLE_BOT := preload("res://scripts/bot/simple_bot.gd")
const SMART_BOT := preload("res://scripts/bot/smart_bot.gd")

const EASY_MISTAKE_RATE := 0.25

const SUIT_SYMBOLS := ["♥", "♦", "♣", "♠"]
const SUIT_NAMES := ["Hearts", "Diamonds", "Clubs", "Spades"]

const OPP_JUMP_DECLARED_NOTICE := "Opponent declared Niko Kadi! Counter with a J/K, or you're skipped"
const OPP_JUMP_NOTICE := "Counter with a %s, or you're skipped"
const OPPONENT_BANNER_TEXT := "OPPONENT: NIKO KADI!"
const PLAYER_BANNER_TEXT := "YOU: NIKO KADI!"

var game: GameState
var clock: ChessClock = null

@onready var background: TextureRect = $Background
@onready var background_layer: Node2D = $BackgroundLayer
@onready var felt_texture: TextureRect = $BackgroundLayer/FeltTexture
@onready var vignette: ColorRect = $BackgroundLayer/Vignette
@onready var draw_pile_slot: Panel = $BackgroundLayer/DrawPileSlotBG
@onready var discard_slot: Panel = $BackgroundLayer/DiscardSlotBG

@onready var top_bar: Node2D = $TopBar
@onready var lobby_button: Button = $TopBar/LobbyButton
@onready var bot_button: Button = $TopBar/BotButton
@onready var log_toggle_button: Button = $TopBar/LogToggleButton
@onready var settings_button: Button = $TopBar/SettingsButton

@onready var opp_area: Node2D = $OpponentArea
@onready var opp_panel: Panel = $OpponentArea/OppPanel
@onready var opp_avatar: Panel = $OpponentArea/OppPanel/OppAvatar
@onready var opp_avatar_label: Label = $OpponentArea/OppPanel/OppAvatar/OppAvatarLabel
@onready var opp_name_label: Label = $OpponentArea/OppPanel/OppNameLabel
@onready var opp_count_label: Label = $OpponentArea/OppPanel/OppCountLabel
@onready var opp_clock_label: Label = $OpponentArea/OppPanel/OppClockLabel
@onready var opp_turn_indicator: Panel = $OpponentArea/OppPanel/OppTurnIndicator
@onready var opp_penalty_badge: Label = $OpponentArea/OppPanel/OppPenaltyBadge

@onready var opponent_banner: Panel = $OpponentBanner
@onready var opponent_banner_label: Label = $OpponentBanner/Label
@onready var player_banner: Panel = $PlayerBanner
@onready var player_banner_label: Label = $PlayerBanner/Label

@onready var center_area: Node2D = $CenterArea
@onready var notice_banner: Label = $CenterArea/NoticeBanner
@onready var turn_label: Label = $CenterArea/TurnLabel
@onready var suit_indicator_panel: Panel = $CenterArea/SuitChip
@onready var suit_indicator_label: Label = $CenterArea/SuitChip/SuitLabel
@onready var game_over_label: Label = $CenterArea/GameOverLabel
@onready var jump_notice_panel: Panel = $CenterArea/JumpNoticePanel
@onready var jump_notice_label: Label = $CenterArea/JumpNoticePanel/JumpLabel
@onready var accept_skip_button: Button = $CenterArea/AcceptSkipButton

@onready var my_area: Node2D = $MyArea
@onready var my_panel: Panel = $MyArea/MyPanel
@onready var my_avatar: Panel = $MyArea/MyPanel/MyAvatar
@onready var my_avatar_label: Label = $MyArea/MyPanel/MyAvatar/MyAvatarLabel
@onready var my_name_label: Label = $MyArea/MyPanel/MyNameLabel
@onready var my_count_label: Label = $MyArea/MyPanel/MyCountLabel
@onready var my_clock_label: Label = $MyArea/MyPanel/MyClockLabel
@onready var my_turn_indicator: Panel = $MyArea/MyPanel/MyTurnIndicator
@onready var my_penalty_badge: Label = $MyArea/MyPanel/MyPenaltyBadge

@onready var bottom_controls: Node2D = $BottomControls
@onready var niko_kadi_button: Button = $BottomControls/NikoButton
@onready var niko_kadi_hint: Label = $BottomControls/NikoHint
@onready var locked_hint: Label = $BottomControls/LockedHint

@onready var suit_picker_overlay: ColorRect = $SuitPicker
@onready var suit_picker_bg: Panel = $SuitPicker/SuitPickerBG
@onready var suit_buttons: Array[Button] = [
	$SuitPicker/BtnHearts, $SuitPicker/BtnDiamonds,
	$SuitPicker/BtnClubs, $SuitPicker/BtnSpades,
]
@onready var suit_picker_niko_button: Button = $SuitPicker/NikoToggle
@onready var suit_picker_close_button: Button = $SuitPicker/SuitPickerClose

@onready var sys_log_panel: Panel = $SysLogPanel
@onready var log_copy_button: Button = $SysLogPanel/CopyButton
@onready var sys_log_text: RichTextLabel = $SysLogPanel/LogText

var is_niko_kadi_declared: bool = false
var is_suit_picker_niko: bool = false
var _niko_offer_seen: bool = false
var _late_declare_open: bool = false
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
var _clock_update_timer: float = 0.0

var input_enabled: bool = true
var my_hand_views: Array[CardView] = []
var draw_pile_view: CardView = null
var staged_chain: Array[Card] = []
var _chain_timer_token: int = 0

var use_smart_bot: bool = true
var _last_opp_hand_size: int = 0
var _arena_theme: ArenaThemeData = null
var _deck_skin: DeckSkinData = null

func _ready() -> void:
	var prog: Node = get_node_or_null("/root/Progression")
	var arena_id := "emerald_lounge"
	var deck_id := "royal_emerald"
	if prog != null:
		arena_id = prog.selected_arena_id
		deck_id = prog.selected_deck_id
	_arena_theme = CosmeticsCatalog.get_arena(arena_id)
	_deck_skin = CosmeticsCatalog.get_deck(deck_id)
	_apply_arena_theme(_arena_theme)

	game = GameState.new()
	clock = ChessClock.new()
	game.log_added.connect(_on_sys_log_added)
	game.start_game()
	_last_opp_hand_size = game.hands[1].size()

	_update_hand_count_labels()
	_update_niko_kadi_button_style()
	_update_suit_picker_niko_style()
	bot_button.text = "Bot: Hard" if use_smart_bot else "Bot: Easy"

	_update_player_names()
	_update_avatars()

	_last_seen_top_card = game.top_card()
	_show_deal()
	_update_turn_label()
	_update_suit_indicator()
	_update_ui_state()
	_start_turn_clock(0)
	_maybe_start_bot()

func _notification(what: int) -> void:
	match what:
		Node.NOTIFICATION_APPLICATION_PAUSED:
			if clock and clock.running_player != -1:
				clock.pause(Time.get_ticks_msec())
		Node.NOTIFICATION_APPLICATION_RESUMED:
			if clock and clock.running_player != -1:
				clock.resume(Time.get_ticks_msec())

func _apply_arena_theme(theme: ArenaThemeData) -> void:
	if not theme:
		return
	if background != null:
		background.modulate = theme.primary_tint
	if felt_texture != null:
		felt_texture.modulate = theme.primary_tint
	if vignette != null:
		vignette.color = theme.vignette_color

func _update_player_names() -> void:
	var prog: Node = get_node_or_null("/root/Progression")
	if prog != null and not prog.player_name.is_empty():
		my_name_label.text = prog.player_name
	else:
		my_name_label.text = "You"
	opp_name_label.text = "Master AI" if use_smart_bot else "Novice AI"

func _update_avatars() -> void:
	opp_avatar_label.text = "♠"
	my_avatar_label.text = "♥"

func _update_hand_count_labels() -> void:
	var mine: int = game.hands[0].size()
	var theirs: int = game.hands[1].size()
	my_count_label.text = "You: %d/%d" % [mine, game.MAX_HAND]
	opp_count_label.text = "Opponent: %d/%d" % [theirs, game.MAX_HAND]

	var warning := Color(1.0, 0.4, 0.4)
	var normal := Color(0.85, 0.83, 0.78, 1.0)
	my_count_label.add_theme_color_override("font_color", warning if mine >= game.MAX_HAND - 1 else normal)
	opp_count_label.add_theme_color_override("font_color", warning if theirs >= game.MAX_HAND - 1 else normal)

func _on_bot_difficulty_toggled() -> void:
	use_smart_bot = not use_smart_bot
	bot_button.text = "Bot: Hard" if use_smart_bot else "Bot: Easy"
	opp_name_label.text = "Master AI" if use_smart_bot else "Novice AI"

func _on_sys_log_added(entry: String) -> void:
	if sys_log_text != null:
		sys_log_text.append_text(entry + "\n")

func _update_niko_kadi_button_style() -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_size = 5
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	if is_niko_kadi_declared:
		niko_kadi_button.text = "Niko Kadi: ON"
		style.bg_color = Color(0.12, 0.58, 0.22, 1.0)
		style.border_color = Color(0.98, 0.86, 0.42, 1.0)
		niko_kadi_button.add_theme_color_override("font_color", Color.WHITE)
	else:
		niko_kadi_button.text = "Niko Kadi: OFF"
		style.bg_color = Color(0.04, 0.08, 0.06, 0.95)
		style.border_color = Color(0.75, 0.62, 0.32, 0.8)
		niko_kadi_button.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8, 1.0))

	niko_kadi_button.add_theme_stylebox_override("normal", style)

func _update_suit_picker_niko_style() -> void:
	assert(suit_picker_niko_button != null, "Suit picker Niko Kadi button must be created")
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_size = 4
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	if is_suit_picker_niko:
		suit_picker_niko_button.text = "Niko Kadi: ON"
		style.bg_color = Color(0.12, 0.58, 0.22, 1.0)
		style.border_color = Color(0.98, 0.86, 0.42, 1.0)
		suit_picker_niko_button.add_theme_color_override("font_color", Color.WHITE)
	else:
		suit_picker_niko_button.text = "Niko Kadi: OFF"
		style.bg_color = Color(0.04, 0.08, 0.06, 0.95)
		style.border_color = Color(0.75, 0.62, 0.32, 0.8)
		suit_picker_niko_button.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8, 1.0))

	suit_picker_niko_button.add_theme_stylebox_override("normal", style)

func _process(delta: float) -> void:
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
	_update_locked_hint()
	_update_clock_display()
	_check_clock_flag()
	_update_turn_indicators()
	_update_penalty_badges()

	_pulse_time += delta
	var wave := 0.5 + 0.5 * sin(_pulse_time * 8.0)
	for banner in [opponent_banner, player_banner]:
		if banner.visible:
			banner.modulate = Color(1, 1, 1, 0.75 + 0.25 * wave)
			banner.scale = Vector2.ONE * (1.0 + 0.015 * wave)

	_clock_update_timer += delta
	if _clock_update_timer >= 2.0:
		_clock_update_timer = 0.0
		_send_ping()

func _update_declaration_banner() -> void:
	if game_over_label.visible:
		opponent_banner.visible = false
		player_banner.visible = false
		return

	var in_final_reveal := _game_over_shown and not game_over_label.visible
	var now := Time.get_ticks_msec()
	opponent_banner.visible = game.has_declared(1) or (in_final_reveal and now < _opp_declare_until_msec)
	player_banner.visible = game.has_declared(0) or (in_final_reveal and now < _my_declare_until_msec)

func _update_ui_state() -> void:
	if game.is_game_over() != 0:
		niko_kadi_button.visible = false
		niko_kadi_hint.visible = false
		locked_hint.visible = false
		accept_skip_button.visible = false
		_update_declaration_banner()
		return

	if _late_declare_open:
		_update_declaration_banner()
		_check_jump_state()
		return

	var show_niko := _can_show_niko_kadi()
	var last_card_declare: bool = show_niko and game.hands[0].size() == 1
	niko_kadi_button.visible = show_niko
	niko_kadi_hint.visible = show_niko
	if last_card_declare:
		niko_kadi_button.text = "NIKO KADI!"
		niko_kadi_hint.text = "Tap to declare, then play your last card to win"
	elif show_niko:
		niko_kadi_hint.text = "Switch ON, then play to leave 1 plain card."
	if show_niko and not _niko_offer_seen:
		_niko_offer_seen = true
		_show_notice("Niko Kadi available: tap it to declare" if last_card_declare else "Niko Kadi available: switch ON, then play to declare")
	elif not show_niko:
		_niko_offer_seen = false
	if not show_niko and is_niko_kadi_declared:
		is_niko_kadi_declared = false
		_update_niko_kadi_button_style()

	_update_declaration_banner()
	_check_jump_state()

func _update_locked_hint() -> void:
	var one_plain: bool = game.hands[0].size() == 1 and game.is_game_over() == 0 and game.hands[0][0].is_plain()
	locked_hint.visible = one_plain and not game.can_win_with_last_card(0) and not _late_declare_open and not niko_kadi_button.visible
	if game.declared[0] and game.hands[1].is_empty():
		locked_hint.text = "You can't win while the opponent has no cards"
	elif game.declared[0]:
		locked_hint.text = "Niko Kadi declared: you can win once the opponent has played"
	else:
		locked_hint.text = "Last card won't win unless you declare Niko Kadi"

func _format_ms(ms: int) -> String:
	if ms < 0:
		ms = 0
	var total_seconds: int = ms / 1000
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func _update_clock_display() -> void:
	if not clock:
		return
	var now: int = Time.get_ticks_msec()
	var running: int = clock.running_player
	for p in 2:
		var time_left: int = clock.time_left(p, now)
		var text := _format_ms(time_left)
		var label := opp_clock_label if p == 1 else my_clock_label
		label.text = text
		if p == running:
			label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
		else:
			label.add_theme_color_override("font_color", Color(0.97, 0.95, 0.88, 1.0))

func _update_turn_indicators() -> void:
	var is_my_turn := game.current_player == 0 and game.is_game_over() == 0
	my_turn_indicator.visible = is_my_turn
	opp_turn_indicator.visible = not is_my_turn and game.is_game_over() == 0

	var wave := 0.5 + 0.5 * sin(_pulse_time * 6.0)
	if is_my_turn:
		my_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
		opp_panel.modulate = Color(0.85, 0.85, 0.85, 0.88)
		my_turn_indicator.modulate = Color(1, 1, 1, 0.8 + 0.2 * wave)
	else:
		opp_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
		my_panel.modulate = Color(0.85, 0.85, 0.85, 0.88)
		opp_turn_indicator.modulate = Color(1, 1, 1, 0.8 + 0.2 * wave)

func _update_penalty_badges() -> void:
	var has_penalty := game.pending_penalty > 0
	var wave := 0.5 + 0.5 * sin(_pulse_time * 10.0)
	var badge_mod := Color(1.0, 0.95, 0.85, 0.85 + 0.15 * wave)

	if game.current_player == 0:
		my_penalty_badge.visible = has_penalty
		opp_penalty_badge.visible = false
		if has_penalty:
			my_penalty_badge.text = "+%d CARDS" % game.pending_penalty
			my_penalty_badge.modulate = badge_mod
	else:
		opp_penalty_badge.visible = has_penalty
		my_penalty_badge.visible = false
		if has_penalty:
			opp_penalty_badge.text = "+%d CARDS" % game.pending_penalty
			opp_penalty_badge.modulate = badge_mod

func _check_clock_flag() -> void:
	if not clock:
		return
	var now: int = Time.get_ticks_msec()
	var flagged: int = clock.flagged_player(now)
	if flagged != -1:
		game.winner = 2 - flagged
		game.over_limit_player = flagged
		game.log_event("Player %d flagged: Player %d wins on time" % [flagged + 1, 2 - flagged])
		_check_game_over()

func _send_ping() -> void:
	pass

func _start_turn_clock(player: int) -> void:
	if clock and clock.running_player == -1:
		clock.start(player, Time.get_ticks_msec())

func _stop_turn_clock(_player: int) -> void:
	if clock and clock.running_player != -1:
		clock.stop(Time.get_ticks_msec(), 0)

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
	var r := "J" if game.pending_jump_rank == 11 else "K"

	if opponent_declared_jump:
		jump_notice_label.text = OPP_JUMP_DECLARED_NOTICE
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
		jump_notice_label.text = OPP_JUMP_DECLARED_NOTICE if opponent_declared_jump else (OPP_JUMP_NOTICE % r)
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
	_stop_turn_clock(0)
	if not game.accept_jump(0):
		return
	_show_deal()
	_update_turn_label()
	_update_suit_indicator()
	_update_ui_state()
	_check_game_over()
	_maybe_start_bot()

func _on_niko_kadi_toggled() -> void:
	if not input_enabled or not _can_show_niko_kadi():
		return
	if game.hands[0].size() == 1:
		game.declare_now(0)
		_update_ui_state()
		return
	is_niko_kadi_declared = not is_niko_kadi_declared
	_update_niko_kadi_button_style()

func _on_suit_picker_niko_toggled() -> void:
	if not input_enabled or game.current_player != 0 or game.hands[0].size() != 1:
		return
	is_suit_picker_niko = not is_suit_picker_niko
	_update_suit_picker_niko_style()

func _on_accept_skip_clicked() -> void:
	if not input_enabled or game.current_player != 0 or game.pending_jump_rank == 0:
		return
	_do_accept_skip()

func _update_suit_indicator() -> void:
	var s: int = game.current_suit
	suit_indicator_label.text = "Suit:\n%s %s" % [SUIT_SYMBOLS[s], SUIT_NAMES[s]]
	if s == 0 or s == 1:
		suit_indicator_label.add_theme_color_override("font_color", Color(0.85, 0.12, 0.15))
	elif s == 2:
		suit_indicator_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
	else:
		suit_indicator_label.add_theme_color_override("font_color", Color(0.12, 0.18, 0.32))

func _show_suit_picker() -> void:
	is_suit_picker_niko = false
	_update_suit_picker_niko_style()
	suit_picker_niko_button.visible = (
		game.hands[0].size() == 1
		and game.hands[0][0].is_plain()
		and not game.declared[0]
	)
	suit_picker_overlay.visible = true

	var tween := create_tween()
	suit_picker_bg.scale = Vector2(0.8, 0.8)
	suit_picker_bg.modulate = Color(1, 1, 1, 0)
	tween.tween_property(suit_picker_bg, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(suit_picker_bg, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_suit_chosen(suit: int) -> void:
	var declare: bool = is_suit_picker_niko
	if declare:
		assert(game.hands[0].size() == 1, "Suit-picker declaration requires exactly one card")
	_stop_turn_clock(0)
	if not game.choose_suit(0, suit, declare):
		return
	is_suit_picker_niko = false
	_update_suit_picker_niko_style()

	var tween := create_tween()
	tween.tween_property(suit_picker_bg, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(suit_picker_bg, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_hide_suit_picker).set_delay(0.15)

func _hide_suit_picker() -> void:
	suit_picker_overlay.visible = false
	suit_picker_bg.scale = Vector2(1, 1)
	suit_picker_bg.modulate = Color(1, 1, 1, 1)

	_show_deal()
	_update_turn_label()
	_update_suit_indicator()
	_update_ui_state()
	_check_game_over()
	_maybe_start_bot()

func _on_suit_picker_close() -> void:
	if suit_picker_overlay.visible:
		var tween := create_tween()
		tween.tween_property(suit_picker_bg, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(suit_picker_bg, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(_hide_suit_picker).set_delay(0.15)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion_pos: Vector2 = get_canvas_transform().affine_inverse() * event.position
		if input_enabled and game != null and game.current_player == 0 and not my_hand_views.is_empty():
			for i in range(my_hand_views.size() - 1, -1, -1):
				var cv := my_hand_views[i]
				var rect := Rect2(cv.position - CARD_SIZE / 2.0, CARD_SIZE)
				var hovered := rect.has_point(motion_pos)
				if hovered != cv.is_hovered:
					cv.set_hovered(hovered)
		return

	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return

	var click_pos: Vector2 = get_canvas_transform().affine_inverse() * event.position

	if log_toggle_button.get_global_rect().has_point(click_pos):
		sys_log_panel.visible = not sys_log_panel.visible
		log_toggle_button.text = "Hide Log" if sys_log_panel.visible else "Log"
		return

	if bot_button.get_global_rect().has_point(click_pos):
		_on_bot_difficulty_toggled()
		return

	if lobby_button != null and lobby_button.get_global_rect().has_point(click_pos):
		exit_to_dashboard_requested.emit()
		return

	if settings_button.get_global_rect().has_point(click_pos):
		_show_notice("Settings coming soon")
		return

	if sys_log_panel.visible:
		if log_copy_button.get_global_rect().has_point(click_pos):
			DisplayServer.clipboard_set("\n".join(PackedStringArray(game.log_entries)))
			_show_notice("Log copied to clipboard")
			return
		if sys_log_panel.get_global_rect().has_point(click_pos):
			return

	if _late_declare_open and niko_kadi_button.get_global_rect().has_point(click_pos):
		_take_late_declaration()
		return

	if not input_enabled or game.current_player != 0 or game.is_game_over() != 0:
		return

	if suit_picker_overlay.visible:
		if suit_picker_niko_button.visible and suit_picker_niko_button.get_global_rect().has_point(click_pos):
			_on_suit_picker_niko_toggled()
			return
		if suit_picker_close_button.get_global_rect().has_point(click_pos):
			_on_suit_picker_close()
			return
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

	if draw_pile_view != null:
		var pile_rect := Rect2(draw_pile_view.position - CARD_SIZE / 2.0, CARD_SIZE)
		if pile_rect.has_point(click_pos):
			_on_draw_pile_clicked()
			return

func _show_deal_animated() -> void:
	_show_deal()

func _show_deal() -> void:
	_clear_table()
	_update_hand_count_labels()

	# Draw pile slot & Discard slot position sync
	if draw_pile_slot != null:
		draw_pile_slot.position = DRAW_POS - CARD_SIZE / 2.0
		draw_pile_slot.size = CARD_SIZE
	if discard_slot != null:
		discard_slot.position = DISCARD_POS - CARD_SIZE / 2.0
		discard_slot.size = CARD_SIZE

	# Stacked deck visual for draw pile
	var deck_size: int = game.draw_pile.cards.size() if (game.draw_pile != null and "cards" in game.draw_pile) else 12
	var stack_depth: int = mini(deck_size, 3)
	for s in range(stack_depth - 1, 0, -1):
		var offset := Vector2(-s * 2.5, -s * 2.5)
		var stack_cv := _add_card_view(null, false, DRAW_POS + offset)
		stack_cv.modulate = Color(0.82, 0.82, 0.82, 0.95)

	# Main draw pile top card
	draw_pile_view = _add_card_view(null, false, DRAW_POS)

	# Main top discard card
	if game.top_card() != null:
		var top_cv := _add_card_view(game.top_card(), true, DISCARD_POS)
		top_cv.rotation_degrees = randf_range(-2.0, 2.0)

	# Place hands
	_place_opponent_hand(game.hands[1], OPP_HAND_Y)
	_place_my_hand(game.hands[0], MY_HAND_Y)

func _clear_table() -> void:
	for child in get_children():
		if child is CardView:
			child.queue_free()
	my_hand_views.clear()
	draw_pile_view = null

func _place_my_hand(hand: Array, y_center: float) -> void:
	var count: int = hand.size()
	if count == 0:
		return

	var max_spacing := CARD_SIZE.x + 8.0
	var usable_width := SCREEN_SIZE.x - MARGIN * 2.0
	var spacing: float = max_spacing
	if count > 1:
		spacing = min((usable_width - CARD_SIZE.x) / (count - 1), max_spacing)

	var total_w := CARD_SIZE.x + (count - 1) * spacing
	var start_x := (SCREEN_SIZE.x - total_w) / 2.0 + CARD_SIZE.x / 2.0

	for i in count:
		var card: Card = hand[i]
		var x := start_x + i * spacing
		var norm_pos: float = 0.0
		if count > 1:
			norm_pos = (float(i) / (count - 1) - 0.5) * 2.0
		var arc_lift := (1.0 - norm_pos * norm_pos) * 6.0
		var y := y_center - arc_lift
		var rot := norm_pos * 4.0

		var cv := _add_card_view(card, true, Vector2(x, y))
		cv.fan_angle = rot
		cv.base_pos = Vector2(x, y)
		cv.rotation_degrees = rot
		if card in staged_chain:
			cv.set_staged(true)
		my_hand_views.append(cv)

func _place_opponent_hand(hand: Array, y_center: float) -> void:
	var count: int = hand.size()
	if count == 0:
		return

	var max_spacing := CARD_SIZE.x + 4.0
	var usable_width := SCREEN_SIZE.x - MARGIN * 2.0
	var spacing: float = max_spacing
	if count > 1:
		spacing = min((usable_width - CARD_SIZE.x) / (count - 1), max_spacing)

	var total_w := CARD_SIZE.x + (count - 1) * spacing
	var start_x := (SCREEN_SIZE.x - total_w) / 2.0 + CARD_SIZE.x / 2.0

	for i in count:
		var x := start_x + i * spacing
		var cv := _add_card_view(null, false, Vector2(x, y_center))
		cv.base_pos = Vector2(x, y_center)

func _place_hand(hand: Array, face_up: bool, y: float) -> void:
	if face_up and hand == game.hands[0]:
		_place_my_hand(hand, y)
	else:
		_place_opponent_hand(hand, y)

func _update_turn_label() -> void:
	if game.is_game_over() != 0:
		return
	if game.current_player == 0:
		if game.hands[0].is_empty():
			turn_label.text = "You have no cards: tap the draw pile"
			return
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

func _offer_late_declaration() -> void:
	var eligible: bool = game.hands[0].size() == 1 and game.hands[0][0].is_plain() and not game.declared[0]
	if not eligible:
		return
	_late_declare_open = true
	is_niko_kadi_declared = false
	_update_niko_kadi_button_style()
	niko_kadi_button.text = "NIKO KADI!"
	niko_kadi_button.visible = true
	niko_kadi_hint.text = "Tap now, before the opponent plays"
	niko_kadi_hint.visible = true
	var deadline := Time.get_ticks_msec() + 2500
	while _late_declare_open and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_late_declare_open = false
	niko_kadi_button.visible = false
	niko_kadi_hint.visible = false

func _take_late_declaration() -> void:
	game.declare_late(0)
	_late_declare_open = false

func _maybe_start_bot() -> void:
	if game.current_player == 1 and input_enabled and game.is_game_over() == 0:
		_start_turn_clock(1)
		await _offer_late_declaration()
		_opp_had_penalty = (game.pending_penalty > 0)
		var bot := _make_bot()
		await bot.take_turn(game, get_tree(), _on_bot_step)
		_stop_turn_clock(1)
		_on_bot_step()
		if game.current_player == 0:
			_start_turn_clock(0)
			_check_jump_state()

func _make_bot() -> SimpleBot:
	if use_smart_bot:
		return SMART_BOT.new()
	var bot := SIMPLE_BOT.new()
	bot.mistake_rate = EASY_MISTAKE_RATE
	return bot

func _on_bot_step() -> void:
	var current_top = game.top_card()
	if current_top != _last_seen_top_card and current_top.rank == 14:
		if _opp_had_penalty:
			_show_notice("Opponent blocked with an Ace")
		elif game.current_player == 0:
			_show_opponent_notice()
	_opp_had_penalty = (game.pending_penalty > 0)
	_last_seen_top_card = current_top

	var drawn := game.hands[1].size() - _last_opp_hand_size
	if drawn > 0:
		_show_notice("Opponent picked up %d card%s" % [drawn, "" if drawn == 1 else "s"])
	_last_opp_hand_size = game.hands[1].size()

	_show_deal()
	_update_turn_label()
	_update_suit_indicator()
	_update_ui_state()
	_check_game_over()

func _show_notice(text: String) -> void:
	notice_banner.text = text
	notice_banner.add_theme_color_override("font_color", Color.WHITE)
	notice_banner.visible = true

	var tween := create_tween()
	notice_banner.modulate = Color(1, 1, 1, 0)
	tween.tween_property(notice_banner, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_hide_notice.bind(text)).set_delay(2.5)

func _hide_notice(text: String) -> void:
	if notice_banner.text == text:
		var tween := create_tween()
		tween.tween_property(notice_banner, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(func(): notice_banner.visible = false).set_delay(0.2)

func _show_opponent_notice() -> void:
	var s: int = game.current_suit
	notice_banner.text = "Opponent chose %s" % SUIT_SYMBOLS[s]
	if s == 0 or s == 1:
		notice_banner.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	else:
		notice_banner.add_theme_color_override("font_color", Color.WHITE)
	notice_banner.visible = true

	var tween := create_tween()
	notice_banner.modulate = Color(1, 1, 1, 0)
	tween.tween_property(notice_banner, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): notice_banner.visible = false).set_delay(2.0)

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
			_stop_turn_clock(0)
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
		_stop_turn_clock(0)
		_maybe_start_bot()

func _on_card_clicked(card: Card) -> bool:
	if not input_enabled or game.current_player != 0 or game.is_game_over() != 0 or game.awaiting_suit_choice:
		return false

	if card in staged_chain:
		if card == staged_chain[0] and staged_chain.size() > 1:
			staged_chain.clear()
		else:
			staged_chain.erase(card)
		_refresh_staged_visuals()
		if staged_chain.is_empty():
			_chain_timer_token += 1
			turn_label.text = "Your turn"
		else:
			_restart_chain_timer()
		_update_ui_state()
		return true

	if not staged_chain.is_empty():
		if _can_extend_chain(card):
			staged_chain.append(card)
			_refresh_staged_visuals()
			_update_ui_state()
			_restart_chain_timer()
			return true
		elif (staged_chain[0].rank == 12 or staged_chain[0].rank == 8) and card.suit == staged_chain.back().suit:
			var question_cards := staged_chain.duplicate()
			staged_chain.clear()
			if _commit_cards(question_cards):
				return _on_card_clicked(card)
			return false
		else:
			_shake_card(card)
			return false

	if _can_extend_chain(card):
		_cancel_jump_flow()
		_answer_timer_token += 1
		staged_chain.append(card)
		_refresh_staged_visuals()
		_update_ui_state()
		_restart_chain_timer()
		return true

	return _commit_cards([card])

func _restart_chain_timer() -> void:
	_chain_timer_token += 1
	var token := _chain_timer_token
	turn_label.text = "Chaining %d card(s)... tap another or wait" % staged_chain.size()
	await get_tree().create_timer(1.8).timeout
	if token != _chain_timer_token or staged_chain.is_empty():
		return
	var cards_to_play: Array[Card] = []
	cards_to_play.assign(staged_chain)
	staged_chain.clear()
	_commit_cards(cards_to_play)

func _commit_cards(cards: Array[Card]) -> bool:
	_chain_timer_token += 1
	var had_penalty := game.pending_penalty > 0
	var typed_cards: Array[Card] = []
	typed_cards.assign(cards)

	var declare_flag := is_niko_kadi_declared and game.can_declare_on_play(0, typed_cards)
	if game.play_cards(0, typed_cards, declare_flag):
		_cancel_jump_flow()
		_answer_timer_token += 1
		is_niko_kadi_declared = false
		_update_niko_kadi_button_style()
		_show_deal()
		_update_turn_label()
		_update_suit_indicator()
		_update_ui_state()
		_check_game_over()

		var lead_card := typed_cards[0]
		if lead_card.rank == 14 and had_penalty and not game.awaiting_suit_choice:
			_show_notice("Ace blocked the penalty")
			if game.current_player == 1:
				_stop_turn_clock(0)
				_maybe_start_bot()
		elif game.awaiting_suit_choice and game.current_player == 0:
			_show_suit_picker()
		elif game.awaiting_answer and game.current_player == 0:
			_start_answer_countdown()
		elif game.current_player == 1:
			_stop_turn_clock(0)
			_maybe_start_bot()
		elif game.current_player == 0 and game.pending_jump_rank != 0:
			_check_jump_state()
		return true
	else:
		_show_deal()
		_shake_card(cards[0])
		return false

func _on_draw_pile_clicked() -> void:
	if not input_enabled or game.current_player != 0 or game.is_game_over() != 0 or game.awaiting_suit_choice or game.pending_jump_rank != 0:
		return
	staged_chain.clear()
	_chain_timer_token += 1
	_answer_timer_token += 1
	_stop_turn_clock(0)
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
			tween.tween_property(cv, "position:x", orig_x + 8.0, 0.04)
			tween.tween_property(cv, "position:x", orig_x - 8.0, 0.04)
			tween.tween_property(cv, "position:x", orig_x + 8.0, 0.04)
			tween.tween_property(cv, "position:x", orig_x - 8.0, 0.04)
			tween.tween_property(cv, "position:x", orig_x, 0.04)
			break

func _game_over_text(result: int) -> String:
	if game.over_limit_player == 0:
		return "You went over %d cards: you lose" % game.MAX_HAND
	if game.over_limit_player == 1:
		return "Opponent went over %d cards: you win" % game.MAX_HAND
	return "You win!" if result == 1 else "You lose!"

func _check_game_over() -> void:
	if _game_over_shown:
		return
	var result := game.is_game_over()
	if result == 0:
		return
	if clock and clock.running_player != -1:
		clock.stop(Time.get_ticks_msec(), 0)
	game.log_event("GAME OVER: %s won!" % ("You" if result == 1 else "Opp"))
	_game_over_shown = true
	_game_over_result = result
	input_enabled = false
	_cancel_jump_flow()
	_show_deal()
	_update_ui_state()
	_update_declaration_banner()

	await get_tree().create_timer(1.5).timeout
	game_over_label.text = _game_over_text(result)
	game_over_label.visible = true

	var tween := create_tween()
	game_over_label.modulate = Color(1, 1, 1, 0)
	game_over_label.scale = Vector2(0.5, 0.5)
	tween.tween_property(game_over_label, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(game_over_label, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if lobby_button != null:
		lobby_button.text = "Continue"
	match_finished.emit(result == 1)
	_update_declaration_banner()

func _can_extend_chain(card: Card) -> bool:
	if card in staged_chain:
		return false
	if staged_chain.size() + 1 >= game.hands[0].size():
		return false
	if staged_chain.is_empty():
		if not game.can_play(card):
			return false
		if game.hands[0].size() <= 2:
			return false
		for other in game.hands[0]:
			if other != card and other.rank == card.rank:
				return true
		return false
	else:
		return card.rank == staged_chain[0].rank

func _has_declaration_play() -> bool:
	var hand: Array = game.hands[0]
	if hand.size() < 2:
		return false
	if hand.size() == 2:
		for card in hand:
			if game.can_play(card):
				return true
		return false
	var needed := hand.size() - 1
	var subsets := _combinations(hand, needed)
	for subset in subsets:
		var rank: int = subset[0].rank
		var same_rank := true
		for card in subset:
			if card.rank != rank:
				same_rank = false
				break
		if same_rank:
			if _subset_can_declare(subset):
				return true
	return false

func _subset_can_declare(subset: Array) -> bool:
	for offset in subset.size():
		var ordered: Array[Card] = []
		for i in subset.size():
			ordered.append(subset[(offset + i) % subset.size()])
		if game.can_declare_on_play(0, ordered):
			return true
	return false

func _combinations(cards: Array, take: int) -> Array:
	var result: Array = []
	if take <= 0 or take > cards.size():
		return result
	var current: Array = []
	_collect_combinations(cards, 0, take, current, result)
	return result

func _collect_combinations(cards: Array, start: int, take: int, current: Array, result: Array) -> void:
	if current.size() == take:
		result.append(current.duplicate())
		return
	for i in range(start, cards.size()):
		current.append(cards[i])
		_collect_combinations(cards, i + 1, take, current, result)
		current.pop_back()

func _can_show_niko_kadi() -> bool:
	if game.current_player != 0 or game.awaiting_suit_choice or game.is_game_over() != 0:
		return false
	if game.hands[0].size() == 1:
		return game.hands[0][0].is_plain() and not game.declared[0] and not game.awaiting_answer and not game.awaiting_call
	if staged_chain.is_empty():
		return _has_declaration_play()
	var hand: Array = game.hands[0]
	if game.can_declare_on_play(0, staged_chain):
		return true
	var remaining: Array = []
	for c in hand:
		if not (c in staged_chain):
			remaining.append(c)
	var rank: int = staged_chain[0].rank
	var pool: Array = []
	for c in remaining:
		if c.rank == rank:
			pool.append(c)
	var needed_extra := hand.size() - 1 - staged_chain.size()
	if needed_extra <= 0:
		return false
	var subsets := _combinations(pool, needed_extra)
	for subset in subsets:
		var candidate: Array[Card] = []
		candidate.assign(staged_chain + subset)
		if _subset_can_declare(candidate):
			return true
	return false

func _refresh_staged_visuals() -> void:
	for cv in my_hand_views:
		cv.set_staged(cv.card in staged_chain)

func _add_card_view(p_card, p_face_up: bool, p_position: Vector2) -> CardView:
	var cv := CARD_VIEW_SCENE.instantiate() as CardView
	cv.position = p_position
	cv.card_size = CARD_SIZE
	add_child(cv)
	if _deck_skin != null:
		cv.apply_deck_skin(_deck_skin)
	cv.set_card(p_card, p_face_up)
	return cv
