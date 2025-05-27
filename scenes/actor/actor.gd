class_name Actor
extends Area2D

@export var traits: Array[StringName]

@onready var sprite: SplitSprite = $SplitSprite
@onready var path: ActionQueue = $Path


# turns

func take_turn() -> void:
	path.start = global_position
	_turn_logic()


func _turn_logic() -> void:
	end_turn()


func end_turn() -> void:
	while path.size():
		var action: Action = path.pop(0)
		action.queue_free()
		
		move_to(action.end)
		if action.target:
			var target: Actor = Game.battle.grid.at(action.target)
			if target: hit(target)
		
		await get_tree().create_timer(0.1).timeout
	
	Game.battle.cont()


# moving

func move_to(point: Vector2) -> void:
	position = point


func can_stand(point: Vector2) -> bool:
	return true


# hitting

func hit(actor: Actor) -> void:
	actor.remove_trait(actor.traits[-1])
	actor.sprite.shake(1, 8.0, 0.025)


func can_hit(actor: Actor) -> bool:
	return actor and actor != self


func die() -> void:
	modulate.a = 0.5


func is_dead() -> bool:
	return traits.is_empty()


# traits

func add_trait(id: StringName) -> void:
	traits.append(id)


func remove_trait(id: StringName) -> void:
	traits.erase(id)
	if is_dead(): die()


func has_trait(id: StringName) -> bool:
	return id in traits


func get_trait_at(idx: int) -> StringName:
	return traits[idx]
