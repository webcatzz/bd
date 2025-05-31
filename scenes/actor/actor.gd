class_name Actor
extends AnimatableBody2D

@export var traits: Array[StringName]

var conditions: Array[Condition]

@onready var sprite: SplitSprite = $SplitSprite
@onready var path: ActionQueue = $Path
@onready var condition_icons: VBoxContainer = $ConditionIcons


# turn

func take_turn() -> void:
	path.start = global_position
	tick_conditions()
	end_turn() if is_dead() else _turn_logic()


func _turn_logic() -> void:
	end_turn()


func end_turn() -> void:
	while path.size():
		var action := path.pop(0)
		action.queue_free()
		await act(action)
	Game.battle.step()


func act(action: Action) -> void:
	move_to(action.end)
	if action.target:
		var target: Actor = Game.battle.grid.query_actor(action.target)
		if target: hit(target)
	
	await get_tree().create_timer(0.1).timeout


# moving

func move_to(point: Vector2) -> void:
	position = point


func can_stand(point: Vector2) -> bool:
	return not Game.battle.grid.query_actor(point)


# hitting

func hit(actor: Actor) -> void:
	actor.take_hit()


func take_hit() -> void:
	prints("ouch", traits)
	remove_trait(get_trait_at(-1))
	sprite.shake(1, 8.0, 0.025)


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


# conditions

func add_condition(condition: Condition) -> void:
	var same := get_condition(condition.id)
	if same:
		same.add(condition)
	else:
		conditions.append(condition)
		condition.ended.connect(remove_condition.bind(condition))
		# icon
		var icon := preload("res://scenes/ui/condition_icon.tscn").instantiate()
		icon.display(condition)
		condition_icons.add_child(icon)


func remove_condition(condition: Condition) -> void:
	conditions.erase(condition)
	condition.ended.disconnect(remove_condition)


func get_condition(id: StringName) -> Condition:
	for condition in conditions:
		if condition.id == id:
			return condition
	return null


func get_condition_time(id: StringName) -> int:
	var condition := get_condition(id)
	return condition.time if condition else 0


func get_condition_strength(id: StringName) -> int:
	var condition := get_condition(id)
	return condition.strength if condition else 0


func tick_conditions() -> void:
	for condition in conditions:
		condition.tick()
		if condition.id == &"doom" and not condition.time:
			remove_trait(get_trait_at(-1))
