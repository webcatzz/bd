class_name Action
extends RayCast2D

enum Type {MOVE, HIT}

const MAX_LENGTH := 3.5
const SPRITE_SIZE := Vector2i(8, 8)
const DOT_SEPARATION := 12.0

var start: Vector2 : set = _set_start
var end: Vector2 : set = _set_end
var type: Type : set = _set_type

var target: Vector2 : set = _set_target
var item: Item : set = _set_item
var is_possible: bool = true : set = _set_is_possible


# drawing

func _draw() -> void:
	draw_set_transform(-start)
	_draw_dots()
	if is_possible:
		_draw_sprite(Vector2i(1, 0), end)
	if type == Type.HIT:
		_draw_sprite(Vector2i(2, 0), target)


func _draw_sprite(coords: Vector2i, point: Vector2, scale: Vector2 = Vector2.ONE) -> void:
	draw_texture_rect_region(
		preload("res://assets/path.png"),
		Rect2(point - SPRITE_SIZE * 0.5, Vector2(SPRITE_SIZE) * scale),
		Rect2(coords * SPRITE_SIZE, SPRITE_SIZE)
	)


func _draw_dots() -> void:
	var length: float = (end - start).length()
	var count: int = length / DOT_SEPARATION
	var separation: float = length * 0.5 if count == 1 else DOT_SEPARATION - (DOT_SEPARATION - fmod(length, DOT_SEPARATION)) / count
	for i: int in count:
		_draw_sprite(Vector2i.ZERO, start.move_toward(end, separation * (i + 1)))


# color

func set_color(color: Color) -> void:
	self_modulate = Color(color, self_modulate.a)


func set_alpha(value: float) -> void:
	self_modulate.a = value


# shake

func set_target_shaking(value: bool) -> void:
	var occupant: Actor = Game.battle.grid.query_actor(target)
	if occupant:
		occupant.sprite.shake() if value else occupant.sprite.stop()


# setters

func _set_start(value: Vector2) -> void:
	start = value
	position = start
	target_position = end - start
	queue_redraw()


func _set_end(value: Vector2) -> void:
	end = value
	target_position = end - start
	queue_redraw()


func _set_type(value: Type) -> void:
	type = value
	set_color(Palette.RED if type == Type.HIT else Palette.WHITE)
	set_target_shaking(type == Type.HIT and is_possible)
	queue_redraw()


func _set_target(value: Vector2) -> void:
	if target == value: return
	set_target_shaking(false)
	target = value
	set_target_shaking(true)
	queue_redraw()


func _set_item(value: Item) -> void:
	item = value
	queue_redraw()


func _set_is_possible(value: bool) -> void:
	is_possible = value
	set_alpha(1.0 if is_possible else 0.5)
	set_target_shaking(type == Type.HIT and is_possible)
	queue_redraw()
