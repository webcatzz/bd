extends CanvasLayer

@export var order: Label

@onready var battle: Battle = get_parent()


func _on_battle_continued() -> void:
	order.text = ""
	for i: int in battle.actors.size():
		if i == battle.actor_idx: order.text += "> "
		order.text += battle.actors[i].name.to_lower() + "\n"


# init

func _ready() -> void:
	hide()
