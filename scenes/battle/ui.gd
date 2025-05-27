extends CanvasLayer

@export var order: Label


func _on_battle_continued() -> void:
	order.text = ""
	for i: int in Game.battle.actors.size():
		if i == Game.battle.actor_idx: order.text += "> "
		order.text += Game.battle.actors[i].name.to_lower() + "\n"


# init

func _ready() -> void:
	hide()
