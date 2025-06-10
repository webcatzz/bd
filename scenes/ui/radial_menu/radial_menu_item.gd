@tool
extends Control

@export var radius: float = 12.0:
	set(value):
		radius = value
		custom_minimum_size = Vector2(radius, radius) * 2.0
		size = Vector2.ZERO


func _ready() -> void:
	radius = radius
