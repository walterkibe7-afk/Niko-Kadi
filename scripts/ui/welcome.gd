class_name WelcomeScreen
extends Control

signal welcome_completed(player_name: String)

@onready var _main_card: PanelContainer = $SafeMargin/CenterStack/WelcomeCard
@onready var _center_preview: CardPreview = $SafeMargin/CenterStack/WelcomeCard/CardMargin/CardVBox/ShowcaseRow/CenterCard
@onready var _name_input: LineEdit = $SafeMargin/CenterStack/WelcomeCard/CardMargin/CardVBox/NameInput
@onready var _enter_button: Button = $SafeMargin/CenterStack/WelcomeCard/CardMargin/CardVBox/EnterButton
@onready var _skip_button: Button = $SafeMargin/CenterStack/WelcomeCard/CardMargin/CardVBox/SkipButton


func _ready() -> void:
	_enter_button.pressed.connect(_on_enter_pressed)
	_skip_button.pressed.connect(_on_skip_pressed)
	_name_input.text_submitted.connect(_on_name_submitted)
	_play_intro_animation()


func _play_intro_animation() -> void:
	_main_card.modulate.a = 0.0
	_main_card.position.y += 24.0

	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_main_card, "modulate:a", 1.0, 0.45)
	tween.tween_property(_main_card, "position:y", _main_card.position.y - 24.0, 0.45)

	await tween.finished
	if is_instance_valid(_center_preview):
		_center_preview.flip_to(false, 0.35)


func _on_name_submitted(_new_text: String) -> void:
	_submit_welcome()


func _on_enter_pressed() -> void:
	_submit_welcome()


func _on_skip_pressed() -> void:
	welcome_completed.emit("Player")


func _submit_welcome() -> void:
	var chosen := _name_input.text.strip_edges()
	if chosen.is_empty():
		chosen = "Player"
	_enter_button.disabled = true
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	await tween.finished
	welcome_completed.emit(chosen)
