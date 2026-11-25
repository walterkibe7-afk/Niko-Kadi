class_name ArenaSelectionScreen
extends Control

signal back_requested

const FELT_TEXTURE := preload("res://assets/table/felt.png")

@onready var _header: SubScreenHeader = $SafeMargin/MainVBox/SubScreenHeader
@onready var _arena_list: VBoxContainer = $SafeMargin/MainVBox/ScrollContainer/ArenaList
@onready var _status_label: Label = $SafeMargin/MainVBox/StatusLabel


func _ready() -> void:
	_header.back_pressed.connect(func() -> void: back_requested.emit())
	_rebuild_list()


func _rebuild_list() -> void:
	for child in _arena_list.get_children():
		child.queue_free()

	var prog := get_node_or_null("/root/Progression")
	var selected_id := str(prog.selected_arena_id) if prog != null else "emerald_lounge"

	for arena in CosmeticsCatalog.get_arenas():
		var card := _build_arena_card(arena, prog, selected_id)
		_arena_list.add_child(card)


func _build_arena_card(arena: ArenaThemeData, prog: Node, selected_id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	var is_selected := arena.id == selected_id
	style.bg_color = Color(0.02, 0.11, 0.07, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.95, 0.80, 0.34, 1.0) if is_selected else Color(0.85, 0.70, 0.35, 0.45)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_size = 8
	style.shadow_color = Color(0, 0, 0, 0.4)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var swatch_frame := PanelContainer.new()
	swatch_frame.custom_minimum_size = Vector2(96, 96)
	var swatch_style := StyleBoxFlat.new()
	swatch_style.border_width_left = 2
	swatch_style.border_width_top = 2
	swatch_style.border_width_right = 2
	swatch_style.border_width_bottom = 2
	swatch_style.border_color = arena.accent_gold
	swatch_style.corner_radius_top_left = 12
	swatch_style.corner_radius_top_right = 12
	swatch_style.corner_radius_bottom_left = 12
	swatch_style.corner_radius_bottom_right = 12
	swatch_frame.add_theme_stylebox_override("panel", swatch_style)
	row.add_child(swatch_frame)

	var tex := TextureRect.new()
	tex.texture = arena.felt_texture if arena.felt_texture != null else FELT_TEXTURE
	tex.modulate = arena.primary_tint
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	swatch_frame.add_child(tex)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)

	var title := Label.new()
	title.text = arena.display_name
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.97, 0.95, 0.88, 1.0))
	info.add_child(title)

	var desc := Label.new()
	desc.text = arena.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.80, 0.85, 0.80, 0.88))
	info.add_child(desc)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(148, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.focus_mode = Control.FOCUS_NONE

	var unlocked := true if prog == null else bool(prog.is_arena_unlocked(arena.id))
	if is_selected:
		btn.text = "Equipped"
		btn.disabled = true
	elif unlocked:
		btn.text = "Equip"
	else:
		btn.text = "Unlock (%d)" % arena.unlock_cost

	_style_action_button(btn, is_selected, unlocked)
	btn.pressed.connect(_on_arena_action.bind(arena))
	info.add_child(btn)

	return panel


func _on_arena_action(arena: ArenaThemeData) -> void:
	var prog := get_node_or_null("/root/Progression")
	if prog == null:
		_status_label.text = "Selected %s (preview mode)" % arena.display_name
		return
	if prog.unlock_and_select_arena(arena):
		_status_label.text = "Equipped %s" % arena.display_name
		_rebuild_list()
	else:
		var needed := arena.unlock_cost - int(prog.coins)
		_status_label.text = "Need %d more Coins to unlock %s" % [needed, arena.display_name]


func _style_action_button(btn: Button, is_selected: bool, unlocked: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18
	sb.corner_radius_bottom_right = 18
	if is_selected:
		sb.bg_color = Color(0.06, 0.22, 0.13, 0.9)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.93, 0.78, 0.32, 0.9)
		btn.add_theme_color_override("font_disabled_color", Color(0.93, 0.78, 0.32, 1.0))
	elif unlocked:
		sb.bg_color = Color(0.08, 0.28, 0.17, 1.0)
		btn.add_theme_color_override("font_color", Color(0.97, 0.95, 0.88, 1.0))
	else:
		sb.bg_color = Color(0.93, 0.78, 0.32, 1.0)
		btn.add_theme_color_override("font_color", Color(0.10, 0.08, 0.03, 1.0))
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_font_size_override("font_size", 16)
