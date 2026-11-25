class_name DashboardTutorial
extends Control

signal tutorial_completed
signal tutorial_skipped

const STEPS := [
	{
		"key": "top_bar",
		"title": "Profile & Coins",
		"body": "View your player profile, achievements, and coin balance earned from every Kadi match.",
	},
	{
		"key": "game_pass",
		"title": "Seasonal Game Pass",
		"body": "Earn XP as you play to unlock seasonal tiers and claim bonus coin rewards.",
	},
	{
		"key": "bottom_dock",
		"title": "Arenas & Collection",
		"body": "Switch between themed arenas and equip complete card-deck skins.",
	},
	{
		"key": "play_button",
		"title": "Ready for the Table",
		"body": "Choose bot difficulty above and tap PLAY KADI whenever you are ready.",
	},
]

var _targets: Dictionary = {}
var _step_index: int = 0

@onready var _scrim_top: ColorRect = $ScrimTop
@onready var _scrim_bottom: ColorRect = $ScrimBottom
@onready var _scrim_left: ColorRect = $ScrimLeft
@onready var _scrim_right: ColorRect = $ScrimRight
@onready var _highlight_frame: Panel = $HighlightFrame
@onready var _tooltip_card: PanelContainer = $TooltipCard
@onready var _step_label: Label = $TooltipCard/MarginContainer/VBoxContainer/StepLabel
@onready var _title_label: Label = $TooltipCard/MarginContainer/VBoxContainer/TitleLabel
@onready var _body_label: Label = $TooltipCard/MarginContainer/VBoxContainer/BodyLabel
@onready var _skip_button: Button = $TooltipCard/MarginContainer/VBoxContainer/ButtonRow/SkipButton
@onready var _next_button: Button = $TooltipCard/MarginContainer/VBoxContainer/ButtonRow/NextButton


func _ready() -> void:
	_next_button.pressed.connect(_on_next_pressed)
	_skip_button.pressed.connect(_on_skip_pressed)
	resized.connect(_layout_current_step)
	call_deferred("_layout_current_step")


func start_with_targets(targets: Dictionary) -> void:
	_targets = targets
	_step_index = 0
	if is_node_ready():
		call_deferred("_layout_current_step")


func _on_next_pressed() -> void:
	if _step_index + 1 >= STEPS.size():
		tutorial_completed.emit()
		return
	_step_index += 1
	_layout_current_step()


func _on_skip_pressed() -> void:
	tutorial_skipped.emit()


func _layout_current_step() -> void:
	var step: Dictionary = STEPS[_step_index]
	_step_label.text = "STEP %d OF %d" % [_step_index + 1, STEPS.size()]
	_title_label.text = str(step["title"])
	_body_label.text = str(step["body"])
	_next_button.text = "Got It" if _step_index == STEPS.size() - 1 else "Next"

	var vp_size := get_viewport_rect().size
	var target_rect := Rect2(vp_size * 0.25, Vector2(vp_size.x * 0.5, 110.0))
	var key: String = str(step["key"])
	if _targets.has(key):
		var ctrl := _targets[key] as Control
		if is_instance_valid(ctrl):
			target_rect = ctrl.get_global_rect().grow(8.0)

	target_rect.position.x = clampf(target_rect.position.x, 8.0, vp_size.x - 16.0)
	target_rect.position.y = clampf(target_rect.position.y, 8.0, vp_size.y - 16.0)
	target_rect.end.x = clampf(target_rect.end.x, target_rect.position.x + 24.0, vp_size.x - 8.0)
	target_rect.end.y = clampf(target_rect.end.y, target_rect.position.y + 24.0, vp_size.y - 8.0)

	_apply_scrim_cutout(target_rect, vp_size)
	_position_tooltip(target_rect, vp_size)


func _apply_scrim_cutout(r: Rect2, vp: Vector2) -> void:
	_scrim_top.position = Vector2.ZERO
	_scrim_top.size = Vector2(vp.x, r.position.y)

	_scrim_bottom.position = Vector2(0.0, r.end.y)
	_scrim_bottom.size = Vector2(vp.x, maxf(0.0, vp.y - r.end.y))

	_scrim_left.position = Vector2(0.0, r.position.y)
	_scrim_left.size = Vector2(r.position.x, r.size.y)

	_scrim_right.position = Vector2(r.end.x, r.position.y)
	_scrim_right.size = Vector2(maxf(0.0, vp.x - r.end.x), r.size.y)

	_highlight_frame.position = r.position
	_highlight_frame.size = r.size


func _position_tooltip(r: Rect2, vp: Vector2) -> void:
	_tooltip_card.size.x = minf(vp.x - 48.0, 560.0)
	_tooltip_card.reset_size()
	var card_size := _tooltip_card.size
	var x := (vp.x - card_size.x) * 0.5
	var space_below := vp.y - r.end.y
	var y := r.end.y + 18.0 if space_below >= card_size.y + 36.0 else maxf(24.0, r.position.y - card_size.y - 18.0)

	_tooltip_card.modulate.a = 0.0
	_tooltip_card.position = Vector2(x, y + 10.0)
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_tooltip_card, "modulate:a", 1.0, 0.22)
	tween.tween_property(_tooltip_card, "position:y", y, 0.22)
