class_name CardPreview
extends Control

@export var rank_text: String = "A" : set = set_rank_text
@export var suit_symbol: String = "♠" : set = set_suit_symbol
@export var is_red_suit: bool = false : set = set_is_red_suit
@export var show_back: bool = false : set = set_show_back
@export var skin_data: DeckSkinData : set = set_skin_data

@onready var _face_panel: PanelContainer = $AspectRatioContainer/CardRoot/FacePanel
@onready var _back_panel: PanelContainer = $AspectRatioContainer/CardRoot/BackPanel
@onready var _top_rank: Label = $AspectRatioContainer/CardRoot/FacePanel/MarginContainer/VBoxContainer/TopRank
@onready var _center_suit: Label = $AspectRatioContainer/CardRoot/FacePanel/MarginContainer/VBoxContainer/CenterSuit
@onready var _bottom_rank: Label = $AspectRatioContainer/CardRoot/FacePanel/MarginContainer/VBoxContainer/BottomRank
@onready var _back_texture: TextureRect = $AspectRatioContainer/CardRoot/BackPanel/BackTexture
@onready var _back_emblem: Label = $AspectRatioContainer/CardRoot/BackPanel/BackEmblem


func _ready() -> void:
	resized.connect(_update_pivot)
	_update_pivot()
	_refresh_visuals()


func set_rank_text(value: String) -> void:
	rank_text = value
	if is_node_ready():
		_refresh_visuals()


func set_suit_symbol(value: String) -> void:
	suit_symbol = value
	if is_node_ready():
		_refresh_visuals()


func set_is_red_suit(value: bool) -> void:
	is_red_suit = value
	if is_node_ready():
		_refresh_visuals()


func set_show_back(value: bool) -> void:
	show_back = value
	if is_node_ready():
		_refresh_visuals()


func set_skin_data(value: DeckSkinData) -> void:
	skin_data = value
	if is_node_ready():
		_refresh_visuals()


func flip_to(face_down: bool, duration: float = 0.28) -> void:
	var half := duration * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale:x", 0.04, half)
	await tween.finished
	show_back = face_down
	var tween_out := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_out.tween_property(self, "scale:x", 1.0, half)


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _refresh_visuals() -> void:
	if _face_panel == null or _back_panel == null:
		return

	_face_panel.visible = not show_back
	_back_panel.visible = show_back

	var suit_color := Color(0.78, 0.12, 0.14, 1.0) if is_red_suit else Color(0.11, 0.13, 0.14, 1.0)
	_top_rank.text = "%s\n%s" % [rank_text, suit_symbol]
	_bottom_rank.text = "%s\n%s" % [suit_symbol, rank_text]
	_center_suit.text = suit_symbol
	_top_rank.add_theme_color_override("font_color", suit_color)
	_center_suit.add_theme_color_override("font_color", suit_color)
	_bottom_rank.add_theme_color_override("font_color", suit_color)

	if skin_data != null:
		var face_style := _face_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if face_style != null:
			face_style.bg_color = skin_data.face_bg_color
			face_style.border_color = skin_data.face_accent_color
			_face_panel.add_theme_stylebox_override("panel", face_style)

		var back_style := _back_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if back_style != null:
			back_style.bg_color = skin_data.back_primary_color
			back_style.border_color = skin_data.face_accent_color
			_back_panel.add_theme_stylebox_override("panel", back_style)

		_back_emblem.add_theme_color_override("font_color", skin_data.face_accent_color)
		_back_texture.texture = skin_data.card_back_texture
		_back_texture.visible = skin_data.card_back_texture != null
		_back_emblem.visible = skin_data.card_back_texture == null
	else:
		_back_texture.visible = false
		_back_emblem.visible = true
