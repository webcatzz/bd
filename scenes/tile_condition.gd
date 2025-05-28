extends Area2D

@export var condition: Condition


func _on_area_entered(area: Area2D) -> void:
	if area is Actor:
		area.add_condition(condition)
