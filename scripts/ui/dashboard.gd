class_name Dashboard
extends Control

signal play_requested(use_smart_bot: bool)
signal arena_selection_requested
signal collection_requested
signal profile_requested
signal game_pass_requested
signal replay_tutorial_requested

var _use_smart_bot: bool = true

@onready var _background: TextureRect = $Background
@onready var _vignette: ColorRect = $Vignette
@onready var _top_bar: HBoxContainer = $SafeMargin/MainVBox/TopBar
@onready var _profile_button: Button = $SafeMargin/MainVBox/TopBar/ProfileButton
@onready var _help_button: Button = $SafeMargin/MainVBox/TopBar/HelpButton
@onready var _coins_label: Label = $SafeMargin/MainVBox/TopBar/CoinsPanel/CoinsMargin/CoinsLabel
@onready var _pass_banner: Button = $SafeMargin/MainVBox/PassBanner
@onready var _pass_tier_label: Label = $SafeMargin/MainVBox/PassBanner/PassContent/PassVBox/PassTopRow/PassTierLabel
@onready var _pass_progress: ProgressBar = $SafeMargin/MainVBox/PassBanner/PassContent/PassVBox/PassProgressBar
@onready var _pass_sub_label: Label = $SafeMargin/MainVBox/PassBanner/PassContent/PassVBox/PassSubLabel
@onready var _bot_toggle_button: Button = $SafeMargin/MainVBox/CenterStage/StageMargin/StageVBox/ArenaHeaderRow/BotToggleButton
@onready var _arena_title: Label = $SafeMargin/MainVBox/CenterStage/StageMargin/StageVBox/ArenaTitle
@onready var _left_card: CardPreview = $SafeMargin/MainVBox/CenterStage/StageMargin/StageVBox/DeckShowcase/LeftCard
@onready var _center_card: CardPreview = $SafeMargin/MainVBox/CenterStage/StageMargin/StageVBox/DeckShowcase/CenterCard
@onready var _right_card: CardPreview = $SafeMargin/MainVBox/CenterStage/StageMargin/StageVBox/DeckShowcase/RightCard
@onready var _deck_name_label: Label = $SafeMargin/MainVBox/CenterStage/StageMargin/StageVBox/DeckNameLabel
@onready var _play_button: Button = $SafeMargin/MainVBox/CenterStage/StageMargin/StageVBox/PlayButton
@onready var _bottom_dock: HBoxContainer = $SafeMargin/MainVBox/BottomDock
@onready var _arenas_button: Button = $SafeMargin/MainVBox/BottomDock/ArenasButton
@onready var _collection_button: Button = $SafeMargin/MainVBox/BottomDock/CollectionButton
@onready var _pass_button: Button = $SafeMargin/MainVBox/BottomDock/PassButton


func _ready() -> void:
	_profile_button.pressed.connect(func() -> void: profile_requested.emit())
	_pass_banner.pressed.connect(func() -> void: game_pass_requested.emit())
	_pass_button.pressed.connect(func() -> void: game_pass_requested.emit())
	_arenas_button.pressed.connect(func() -> void: arena_selection_requested.emit())
	_collection_button.pressed.connect(func() -> void: collection_requested.emit())
	_help_button.pressed.connect(func() -> void: replay_tutorial_requested.emit())
	_bot_toggle_button.pressed.connect(_on_bot_toggled)
	_play_button.pressed.connect(_on_play_pressed)

	_connect_progress_signals()
	refresh_from_progress()
	_play_entrance_animation()


func refresh_from_progress() -> void:
	var prog := get_node_or_null("/root/Progression")
	var arena_id := "emerald_lounge"
	var deck_id := "royal_emerald"

	if prog == null:
		_profile_button.text = "Player"
		_coins_label.text = "250 Coins"
		_pass_tier_label.text = "Tier 1"
		_pass_progress.value = 0.0
		_pass_sub_label.text = "0 / 100 XP to next reward"
	else:
		_profile_button.text = str(prog.player_name)
		_coins_label.text = "%d Coins" % int(prog.coins)
		var xp_in_tier: int = int(prog.season_xp) % 100
		_pass_tier_label.text = "Tier %d" % int(prog.season_level)
		_pass_progress.value = float(xp_in_tier)
		_pass_sub_label.text = "%d / 100 XP to next reward" % xp_in_tier
		arena_id = str(prog.selected_arena_id)
		deck_id = str(prog.selected_deck_id)

	var arena := CosmeticsCatalog.get_arena(arena_id)
	_arena_title.text = arena.display_name
	_background.modulate = arena.primary_tint
	_vignette.color = arena.vignette_color

	var deck := CosmeticsCatalog.get_deck(deck_id)
	_deck_name_label.text = "Deck: %s" % deck.display_name
	_left_card.skin_data = deck
	_center_card.skin_data = deck
	_right_card.skin_data = deck


func get_tutorial_targets() -> Dictionary:
	return {
		"top_bar": _top_bar,
		"game_pass": _pass_banner,
		"bottom_dock": _bottom_dock,
		"play_button": _play_button,
	}


func _connect_progress_signals() -> void:
	var prog := get_node_or_null("/root/Progression")
	if prog == null:
		return
	if not prog.profile_changed.is_connected(refresh_from_progress):
		prog.profile_changed.connect(refresh_from_progress)
	if not prog.coins_changed.is_connected(_on_coins_changed):
		prog.coins_changed.connect(_on_coins_changed)
	if not prog.cosmetics_changed.is_connected(refresh_from_progress):
		prog.cosmetics_changed.connect(refresh_from_progress)
	if not prog.pass_changed.is_connected(refresh_from_progress):
		prog.pass_changed.connect(refresh_from_progress)


func _on_coins_changed(_new_balance: int) -> void:
	refresh_from_progress()


func _on_bot_toggled() -> void:
	_use_smart_bot = not _use_smart_bot
	_bot_toggle_button.text = "Bot: Hard" if _use_smart_bot else "Bot: Easy"


func _on_play_pressed() -> void:
	_play_button.disabled = true
	play_requested.emit(_use_smart_bot)


func _play_entrance_animation() -> void:
	modulate.a = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
