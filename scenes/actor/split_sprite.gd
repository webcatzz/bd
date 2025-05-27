@tool
class_name SplitSprite
extends Node2D

@export var texture: Texture2D = preload("res://assets/guy.png")
@export var offset: Vector2
@export var parts: int = 1 : set = _set_parts

var sprites: Array[Sprite2D]
var animator: Tween


func push(count: int = 1) -> void:
	for i in count:
		var sprite := Sprite2D.new()
		sprite.texture = AtlasTexture.new()
		sprite.texture.atlas = texture
		sprites.append(sprite)
		add_child(sprite)
	_split()


func pop(count: int = 1) -> void:
	for i in count:
		sprites.pop_back().queue_free()
	_split()


func _split() -> void:
	var width := texture.get_width()
	var height := texture.get_height() / sprites.size()
	for i in sprites.size():
		sprites[i].texture.region = Rect2(0, height * i, width, height)
		sprites[i].offset.y = height * (i - sprites.size() / 2.0 + 0.5) + offset.y


func separate(amount := 4.0) -> void:
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	for i in sprites.size():
		tween.tween_property(sprites[i], "position:y", amount * (i - parts + 1), 0.2)


func shake(loops: int = 0, amount := 0.5, duration := 0.05) -> void:
	stop()
	animator = create_tween().set_parallel()
	for i in sprites.size():
		var subtween := create_tween().set_loops(loops)
		subtween.tween_property(sprites[i], "position:x", amount if i % 2 else -amount, duration)
		subtween.tween_property(sprites[i], "position:x", 0.0, duration)
		subtween.tween_property(sprites[i], "position:x", -amount if i % 2 else amount, duration)
		subtween.tween_property(sprites[i], "position:x", 0.0, duration)
		animator.tween_subtween(subtween)


func stop() -> void:
	if animator:
		animator.kill()
		for sprite in sprites:
			sprite.position.x = 0.0


func _set_parts(value: int) -> void:
	parts = value
	if parts > sprites.size():
		push(parts - sprites.size())
	elif parts < sprites.size():
		pop(sprites.size() - parts)
