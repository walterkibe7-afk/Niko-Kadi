class_name SubScreenHeader
extends HBoxContainer

signal back_pressed

@export var title_text: String = "Menu" : set = set_title_text

@onready var _back_button: Button = $BackButton
@onready var _title_label: Label = $TitleLabel
@onready var _coins_label: Label = $CoinsPanel/CoinsMargin/CoinsLabel


func _ready() -> void:
	_back_button.pressed.connect(func() -> void: back_pressed.emit())
	_title_label.text = title_text
	_sync_coins()
	var prog := get_node_or_null("/root/Progression")
	if prog != null and not prog.coins_changed.is_connected(_on_coins_changed):
		prog.coins_changed.connect(_on_coins_changed)


func set_title_text(value: String) -> void:
	title_text = value
	if is_node_ready() and _title_label != null:
		_title_label.text = value


func _on_coins_changed(new_balance: int) -> void:
	if _coins_label != null:
		_coins_label.text = "%d Coins" % new_balance


func _sync_coins() -> void:
	var prog := get_node_or_null("/root/Progression")
	if prog == null:
		_coins_label.text = "250 Coins"
	else:
		_coins_label.text = "%d Coins" % int(prog.coins)
