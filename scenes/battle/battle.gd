class_name Battle
extends Node

signal started
signal continued
signal ended

@export var grid: Grid
@export var actors: Array[Actor]

var actor_idx: int = -1


func start() -> void:
	Game.battle = self
	started.emit()
	cont()


func cont() -> void:
	actor_idx = (actor_idx + 1) % actors.size()
	if actors[actor_idx].is_dead():
		cont()
	else:
		actors[actor_idx].take_turn()
	continued.emit()


func end() -> void:
	Game.battle = null
	ended.emit()


# init

func _ready() -> void:
	start()
