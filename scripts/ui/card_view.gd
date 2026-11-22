class_name CardView
extends Node2D

@export var card = null
@export var face_up: bool = false
@export var card_size: Vector2 = Vector2(120, 168)

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	refresh()

func set_card(p_card, p_face_up: bool) -> void:
	card = p_card
	face_up = p_face_up
	assert(_sprite != null, "set_card called before CardView is in the tree")
	refresh()

func refresh() -> void:
	assert(_sprite != null, "refresh called before CardView is in the tree")

	if face_up:
		assert(card != null, "face_up CardView has no card")
		var tex := load(CardArt.card_path(card))
		assert(tex != null, "Failed to load card texture: %s" % CardArt.card_path(card))
		_sprite.texture = tex
	else:
		var tex := load(CardArt.back_path())
		assert(tex != null, "Failed to load card back texture: %s" % CardArt.back_path())
		_sprite.texture = tex

	var texture_size := Vector2(_sprite.texture.get_width(), _sprite.texture.get_height())
	_sprite.scale = card_size / texture_size
	_sprite.visible = true
