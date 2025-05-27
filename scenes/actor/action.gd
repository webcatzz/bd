class_name Action
extends Node2D

enum Type {MOVE, HIT}

const MAX_DISTANCE: float = 3.5
const SPRITE_SIZE := Vector2i(8, 8)
const DOT_SEPARATION: float = 12.0

var start: Vector2 : set = _set_start
var end: Vector2 : set = _set_end
var type: Type : set = _set_type

var target: Vector2 : set = _set_target
var item: Item : set = _set_item
var is_possible: bool = true : set = _set_is_possible


# drawing

func _draw() -> void:
	self_modulate = Palette.WHITE
	_draw_dots()
	_draw_sprite(Vector2i(1, 0), end)
	
	if type == Type.HIT:
		_draw_sprite(Vector2i(2, 0), target)
		self_modulate = Palette.RED
	
	#_draw_sprite(Vector2i(1 if type == Type.MOVE else 2 if type == Type.HIT else 0, 0), to)
	#self_modulate = Color(Palette.WHITE, 0.5)


func _draw_sprite(coords: Vector2i, point: Vector2, scale: Vector2 = Vector2.ONE) -> void:
	draw_texture_rect_region(
		preload("res://assets/path.png"),
		Rect2(point - SPRITE_SIZE * 0.5, Vector2(SPRITE_SIZE) * scale),
		Rect2(coords * SPRITE_SIZE, SPRITE_SIZE)
	)


func _draw_dots() -> void:
	var length: float = (end - start).length()
	var count: int = length / DOT_SEPARATION
	var separation: float
	if count == 1:
		separation = length * 0.5
	else:
		separation = DOT_SEPARATION - (DOT_SEPARATION - fmod(length, DOT_SEPARATION)) / count
	for d: int in count:
		_draw_sprite(Vector2i.ZERO, start.move_toward(end, separation * (d + 1)))


# shake

func set_target_shaking(value: bool) -> void:
	var occupant: Actor = Game.battle.grid.at(target)
	if occupant:
		occupant.sprite.shake() if value else occupant.sprite.stop()


# setters

func _set_start(value: Vector2) -> void:
	start = value
	queue_redraw()


func _set_end(value: Vector2) -> void:
	end = value
	queue_redraw()


func _set_type(value: Type) -> void:
	type = value
	#if type != Type.HIT:
		#set_target_shaking(false)
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
	queue_redraw()
