class_name CardView
extends Node2D

@export var card = null
@export var face_up: bool = false
@export var card_size: Vector2 = Vector2(112, 156)

var fan_angle: float = 0.0
var base_pos: Vector2 = Vector2.ZERO
var is_staged: bool = false
var is_hovered: bool = false
var deck_skin: DeckSkinData = null

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shadow: Sprite2D = $Shadow

func _ready() -> void:
	refresh()

func apply_deck_skin(skin: DeckSkinData) -> void:
	deck_skin = skin
	if is_inside_tree() and _sprite != null:
		refresh()

func set_card(p_card, p_face_up: bool) -> void:
	card = p_card
	face_up = p_face_up
	if is_inside_tree() and _sprite != null:
		refresh()

func refresh() -> void:
	if not is_inside_tree() or _sprite == null:
		return

	if face_up:
		assert(card != null, "face_up CardView has no card")
		var tex := load(CardArt.card_path(card)) as Texture2D
		assert(tex != null, "Failed to load card texture: %s" % CardArt.card_path(card))
		_sprite.texture = tex
		if deck_skin != null:
			_sprite.modulate = deck_skin.face_bg_color
		else:
			_sprite.modulate = Color.WHITE
	else:
		var back_tex: Texture2D = null
		if deck_skin != null and deck_skin.card_back_texture != null:
			back_tex = deck_skin.card_back_texture
		else:
			back_tex = load(CardArt.back_path()) as Texture2D
		assert(back_tex != null, "Failed to load card back texture")
		_sprite.texture = back_tex
		if deck_skin != null:
			_sprite.modulate = deck_skin.back_primary_color.lerp(Color.WHITE, 0.45)
		else:
			_sprite.modulate = Color.WHITE

	var texture_size := Vector2(_sprite.texture.get_width(), _sprite.texture.get_height())
	_sprite.scale = card_size / texture_size
	_sprite.visible = true

	# Multi-layered realistic shadow
	if _shadow != null:
		_shadow.texture = _sprite.texture
		_shadow.scale = _sprite.scale
		_shadow.visible = true
		_shadow.z_index = -1
		_update_shadow_state()

func _update_shadow_state() -> void:
	if _shadow == null:
		return
	if is_staged:
		_shadow.offset = Vector2(8, 16)
		_shadow.modulate = Color(0, 0, 0, 0.35)
		_shadow.scale = _sprite.scale * 1.04
	elif is_hovered:
		_shadow.offset = Vector2(6, 12)
		_shadow.modulate = Color(0, 0, 0, 0.38)
		_shadow.scale = _sprite.scale * 1.02
	else:
		_shadow.offset = Vector2(4, 7)
		_shadow.modulate = Color(0, 0, 0, 0.32)
		_shadow.scale = _sprite.scale

func set_hovered(p_hovered: bool) -> void:
	is_hovered = p_hovered
	_update_elevation()

func set_staged(p_staged: bool) -> void:
	is_staged = p_staged
	_update_elevation()

func _update_elevation() -> void:
	var target_y := base_pos.y
	var target_rot := fan_angle
	var target_mod := Color.WHITE

	if is_staged:
		target_y -= 34.0
		target_rot = 0.0
		target_mod = Color(1.15, 1.15, 0.95, 1.0)
	elif is_hovered:
		target_y -= 18.0
		target_rot = fan_angle * 0.4
		target_mod = Color(1.08, 1.08, 1.08, 1.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", target_y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees", target_rot, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "modulate", target_mod, 0.12)
	_update_shadow_state()

func animate_play(target_pos: Vector2, p_delay: float = 0.0) -> Tween:
	var tween := create_tween()
	tween.set_parallel(true)
	# Arching motion: slight lift and scale peak
	tween.tween_property(self, "position", target_pos, 0.28).set_delay(p_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12).set_delay(p_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.16).set_delay(p_delay + 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var random_tilt := randf_range(-3.5, 3.5)
	tween.tween_property(self, "rotation_degrees", random_tilt, 0.28).set_delay(p_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _shadow != null:
		tween.tween_property(_shadow, "offset", Vector2(6, 10), 0.28).set_delay(p_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween

func animate_draw(target_pos: Vector2, p_delay: float = 0.0) -> Tween:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_pos, 0.32).set_delay(p_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees", fan_angle, 0.32).set_delay(p_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _shadow != null:
		tween.tween_property(_shadow, "offset", Vector2(4, 7), 0.32).set_delay(p_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween

func animate_flip(p_face_up: bool, p_delay: float = 0.0) -> Tween:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_sprite, "scale:x", 0.0, 0.14).set_delay(p_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if _shadow != null:
		tween.tween_property(_shadow, "scale:x", 0.0, 0.14).set_delay(p_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(face_up_ready.bind(p_face_up)).set_delay(p_delay + 0.14)
	tween.tween_property(_sprite, "scale:x", card_size.x / _sprite.texture.get_width(), 0.14).set_delay(p_delay + 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _shadow != null:
		tween.tween_property(_shadow, "scale:x", card_size.x / _sprite.texture.get_width(), 0.14).set_delay(p_delay + 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween

func face_up_ready(p_face_up: bool) -> void:
	face_up = p_face_up
	refresh()
