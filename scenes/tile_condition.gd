extends Area2D

@export var condition: Condition


func _on_body_entered(body: Node2D) -> void:
	if body is Actor:
		body.add_condition(condition)
