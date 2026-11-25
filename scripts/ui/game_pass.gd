class_name GamePassScreen
extends Control

signal back_requested

@onready var _header: SubScreenHeader = $SafeMargin/MainVBox/SubScreenHeader
@onready var _tier_label: Label = $SafeMargin/MainVBox/SummaryCard/MarginContainer/VBoxContainer/TopRow/TierLabel
@onready var _xp_bar: ProgressBar = $SafeMargin/MainVBox/SummaryCard/MarginContainer/VBoxContainer/XpProgressBar
@onready var _xp_sub_label: Label = $SafeMargin/MainVBox/SummaryCard/MarginContainer/VBoxContainer/XpSubLabel
@onready var _tier_list: VBoxContainer = $SafeMargin/MainVBox/ScrollContainer/TierList


func _ready() -> void:
	_header.back_pressed.connect(func() -> void: back_requested.emit())
	_refresh()


func _refresh() -> void:
	var prog := get_node_or_null("/root/Progression")
	var level := 1
	var xp := 0
	if prog != null:
		level = int(prog.season_level)
		xp = int(prog.season_xp)

	var xp_in_tier := xp % 100
	_tier_label.text = "Tier %d" % level
	_xp_bar.value = float(xp_in_tier)
	_xp_sub_label.text = "%d / 100 XP toward Tier %d" % [xp_in_tier, level + 1]

	_rebuild_tiers(prog, level)


func _rebuild_tiers(prog: Node, current_level: int) -> void:
	for child in _tier_list.get_children():
		child.queue_free()

	for tier_info in CosmeticsCatalog.get_pass_tiers():
		var tier_num: int = int(tier_info["tier"])
		var reward_amount: int = int(tier_info["amount"])
		var claimed := false if prog == null else bool(prog.is_tier_claimed(tier_num))
		var can_claim := false if prog == null else bool(prog.can_claim_tier(tier_num))
		var unlocked := current_level >= tier_num

		var panel := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.02, 0.11, 0.07, 0.92)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.95, 0.80, 0.34, 0.95) if can_claim else Color(0.85, 0.70, 0.35, 0.4)
		sb.corner_radius_top_left = 16
		sb.corner_radius_top_right = 16
		sb.corner_radius_bottom_left = 16
		sb.corner_radius_bottom_right = 16
		panel.add_theme_stylebox_override("panel", sb)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 18)
		margin.add_theme_constant_override("margin_top", 14)
		margin.add_theme_constant_override("margin_right", 18)
		margin.add_theme_constant_override("margin_bottom", 14)
		panel.add_child(margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		margin.add_child(row)

		var tier_badge := Label.new()
		tier_badge.custom_minimum_size = Vector2(72, 0)
		tier_badge.text = "TIER %d" % tier_num
		tier_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tier_badge.add_theme_font_size_override("font_size", 16)
		tier_badge.add_theme_color_override("font_color", Color(0.93, 0.78, 0.32, 1.0))
		row.add_child(tier_badge)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var title := Label.new()
		title.text = str(tier_info["title"])
		title.add_theme_font_size_override("font_size", 19)
		title.add_theme_color_override("font_color", Color(0.97, 0.95, 0.88, 1.0))
		info.add_child(title)

		var reward_lbl := Label.new()
		reward_lbl.text = str(tier_info["label"])
		reward_lbl.add_theme_font_size_override("font_size", 15)
		reward_lbl.add_theme_color_override("font_color", Color(0.80, 0.86, 0.80, 0.9))
		info.add_child(reward_lbl)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(118, 42)
		btn.focus_mode = Control.FOCUS_NONE
		if claimed:
			btn.text = "Claimed"
			btn.disabled = true
		elif can_claim:
			btn.text = "Claim"
		elif unlocked:
			btn.text = "Claim"
			btn.disabled = true
		else:
			btn.text = "Locked"
			btn.disabled = true

		_style_claim_button(btn, can_claim, claimed)
		btn.pressed.connect(_on_claim_pressed.bind(tier_num, reward_amount))
		row.add_child(btn)

		_tier_list.add_child(panel)


func _on_claim_pressed(tier_num: int, reward_amount: int) -> void:
	var prog := get_node_or_null("/root/Progression")
	if prog != null and prog.claim_pass_tier(tier_num, reward_amount):
		_refresh()


func _style_claim_button(btn: Button, can_claim: bool, claimed: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16
	sb.corner_radius_bottom_right = 16
	if can_claim:
		sb.bg_color = Color(0.93, 0.78, 0.32, 1.0)
		btn.add_theme_color_override("font_color", Color(0.10, 0.08, 0.03, 1.0))
	elif claimed:
		sb.bg_color = Color(0.06, 0.20, 0.12, 0.85)
		btn.add_theme_color_override("font_disabled_color", Color(0.93, 0.78, 0.32, 0.9))
	else:
		sb.bg_color = Color(0.04, 0.09, 0.07, 0.75)
		btn.add_theme_color_override("font_disabled_color", Color(0.60, 0.65, 0.60, 0.7))
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_font_size_override("font_size", 15)
