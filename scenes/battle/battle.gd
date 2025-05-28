class_name Battle
extends Node

signal started
signal continued
signal ended

enum State {ONGOING, WON, LOST}

@export var grid: Grid
@export var actors: Array[Actor]

var actor_idx: int = -1


# loop

func start() -> void:
	Game.battle = self
	started.emit()
	step()


func step() -> void:
	match get_state():
		State.ONGOING: cont()
		_: end()


func cont() -> void:
	actor_idx = (actor_idx + 1) % actors.size()
	actors[actor_idx].take_turn()
	continued.emit()


func end() -> void:
	Game.battle = null
	ended.emit()


# state

func get_state() -> State:
	if Game.player.is_dead():
		return State.LOST
	elif actors.filter(func(actor: Actor) -> bool: return not actor.is_dead()).size() == 1:
		return State.WON
	return State.ONGOING


# init

func _ready() -> void:
	start()
