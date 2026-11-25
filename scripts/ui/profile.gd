class_name ProfileScreen
extends Control

signal back_requested

@onready var _header: SubScreenHeader = $SafeMargin/MainVBox/SubScreenHeader
@onready var _name_input: LineEdit = $SafeMargin/MainVBox/ScrollContainer/ContentVBox/IdentityCard/MarginContainer/VBoxContainer/NameRow/NameInput
@onready var _save_name_button: Button = $SafeMargin/MainVBox/ScrollContainer/ContentVBox/IdentityCard/MarginContainer/VBoxContainer/NameRow/SaveNameButton
@onready var _equipped_label: Label = $SafeMargin/MainVBox/ScrollContainer/ContentVBox/IdentityCard/MarginContainer/VBoxContainer/EquippedLabel
@onready var _matches_value: Label = $SafeMargin/MainVBox/ScrollContainer/ContentVBox/StatsCard/MarginContainer/StatsRow/MatchesBox/MatchesValue
@onready var _wins_value: Label = $SafeMargin/MainVBox/ScrollContainer/ContentVBox/StatsCard/MarginContainer/StatsRow/WinsBox/WinsValue
@onready var _rate_value: Label = $SafeMargin/MainVBox/ScrollContainer/ContentVBox/StatsCard/MarginContainer/StatsRow/RateBox/RateValue
@onready var _achievements_list: VBoxContainer = $SafeMargin/MainVBox/ScrollContainer/ContentVBox/AchievementsList


func _ready() -> void:
	_header.back_pressed.connect(func() -> void: back_requested.emit())
	_save_name_button.pressed.connect(_on_save_name_pressed)
	_name_input.text_submitted.connect(func(_t: String) -> void: _on_save_name_pressed())
	_refresh()


func _refresh() -> void:
	var prog := get_node_or_null("/root/Progression")
	var p_name := "Player"
	var played := 0
	var won := 0
	var deck_id := "royal_emerald"
	var arena_id := "emerald_lounge"
	var deck_count := 1
	var arena_count := 1

	if prog != null:
		p_name = str(prog.player_name)
		played = int(prog.matches_played)
		won = int(prog.matches_won)
		deck_id = str(prog.selected_deck_id)
		arena_id = str(prog.selected_arena_id)
		deck_count = prog.unlocked_deck_ids.size()
		arena_count = prog.unlocked_arena_ids.size()

	_name_input.text = p_name
	var deck := CosmeticsCatalog.get_deck(deck_id)
	var arena := CosmeticsCatalog.get_arena(arena_id)
	_equipped_label.text = "Arena: %s  •  Deck: %s" % [arena.display_name, deck.display_name]

	_matches_value.text = str(played)
	_wins_value.text = str(won)
	var rate := int(round(float(won) * 100.0 / float(played))) if played > 0 else 0
	_rate_value.text = "%d%%" % rate

	_rebuild_achievements(played, won, deck_count, arena_count)


func _on_save_name_pressed() -> void:
	var prog := get_node_or_null("/root/Progression")
	if prog != null:
		prog.set_player_name(_name_input.text)
		_refresh()


func _rebuild_achievements(played: int, won: int, deck_count: int, arena_count: int) -> void:
	for child in _achievements_list.get_children():
		child.queue_free()

	for item in CosmeticsCatalog.get_achievements(played, won, deck_count, arena_count):
		var panel := PanelContainer.new()
		var unlocked := bool(item["unlocked"])
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.03, 0.13, 0.08, 0.92) if unlocked else Color(0.02, 0.07, 0.05, 0.75)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.93, 0.78, 0.32, 0.9) if unlocked else Color(0.5, 0.55, 0.5, 0.3)
		sb.corner_radius_top_left = 14
		sb.corner_radius_top_right = 14
		sb.corner_radius_bottom_left = 14
		sb.corner_radius_bottom_right = 14
		panel.add_theme_stylebox_override("panel", sb)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_bottom", 12)
		panel.add_child(margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		margin.add_child(row)

		var text_box := VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_box)

		var title := Label.new()
		title.text = str(item["title"])
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_color_override("font_color", Color(0.97, 0.95, 0.88, 1.0) if unlocked else Color(0.7, 0.75, 0.7, 0.75))
		text_box.add_child(title)

		var desc := Label.new()
		desc.text = str(item["description"])
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 14)
		desc.add_theme_color_override("font_color", Color(0.78, 0.84, 0.78, 0.85))
		text_box.add_child(desc)

		var badge := Label.new()
		badge.text = "UNLOCKED" if unlocked else "LOCKED"
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 13)
		badge.add_theme_color_override("font_color", Color(0.93, 0.78, 0.32, 1.0) if unlocked else Color(0.55, 0.6, 0.56, 0.7))
		row.add_child(badge)

		_achievements_list.add_child(panel)
