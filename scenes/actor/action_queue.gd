class_name ActionQueue
extends Node2D

@export_range(1, 1, 1, "or_greater") var max_size: int = 5

var actions: Array[Action]
var start: Vector2


func push() -> Action:
	var action := Action.new()
	action.start = at(-1).end if size() else start
	actions.append(action)
	add_child(action)
	return action


func pop(idx: int = -1) -> Action:
	return actions.pop_at(idx)


func at(idx: int) -> Action:
	return actions[idx]


func size() -> int:
	return actions.size()


func clear() -> void:
	while size():
		pop().queue_free()
