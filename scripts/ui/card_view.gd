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
	if _sprite != null:
		refresh()

func refresh() -> void:
	if _sprite == null:
		return

	if face_up and card != null:
		_sprite.texture = load(CardArt.card_path(card))
	elif not face_up:
		_sprite.texture = load(CardArt.back_path())
	else:
		_sprite.texture = null
		_sprite.visible = false
		return

	if _sprite.texture != null:
		_sprite.visible = true
		var texture_size := Vector2(_sprite.texture.get_width(), _sprite.texture.get_height())
		if texture_size.x > 0 and texture_size.y > 0:
			_sprite.scale = card_size / texture_size
	else:
		_sprite.visible = false
