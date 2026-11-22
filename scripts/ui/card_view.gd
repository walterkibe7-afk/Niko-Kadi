class_name CardView
extends Node2D

@export var card = null
@export var face_up: bool = false
@export var card_size: Vector2 = Vector2(120, 168)

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _area: Area2D = $Area2D

signal gui_input(event: InputEvent, card_view: CardView)

func _ready() -> void:
	refresh()
	_area.input_event.connect(_on_area_input_event.bind(self))

func _on_area_input_event(viewport, event, shape_idx, card_view: CardView):
	gui_input.emit(event, card_view)

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
		_area.monitoring = false
		return

	if _sprite.texture != null:
		_sprite.visible = true
		_area.monitoring = true
		var texture_size := Vector2(_sprite.texture.get_width(), _sprite.texture.get_height())
		if texture_size.x > 0 and texture_size.y > 0:
			_sprite.scale = card_size / texture_size
			# Update collision shape to match card size
			var collision_shape = _area.get_node_or_null("CollisionShape2D")
			if collision_shape:
				collision_shape.shape = RectangleShape2D.new()
				collision_shape.shape.size = card_size
	else:
		_sprite.visible = false
		_area.monitoring = false