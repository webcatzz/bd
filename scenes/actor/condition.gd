class_name Condition
extends Resource

signal ended

@export var id: StringName
@export var time: int = 1
@export var strength: int = 1


func _init(id: StringName = &"", time: int = 0, strength: int = 1) -> void:
	self.id = id
	self.time = time
	self.strength = strength


func tick() -> void:
	time -= 1
	changed.emit()
	if time == 0:
		end()


func end() -> void:
	ended.emit()


func add(condition: Condition) -> void:
	time = maxi(time, condition.time)
	strength = maxi(strength, condition.strength)
	changed.emit()
