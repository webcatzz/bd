class_name Cursor
extends Sprite2D


func open_menu() -> RadialMenu:
	var menu: RadialMenu = preload("res://scenes/ui/radial_menu/radial_menu.tscn").instantiate()
	menu.move_to(position)
	get_parent().add_child(menu)
	return menu


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		position = get_global_mouse_position()


func _ready() -> void:
	get_window().mouse_entered.connect(Input.set_mouse_mode.call_deferred.bind(Input.MOUSE_MODE_HIDDEN))
	get_window().mouse_exited.connect(Input.set_mouse_mode.call_deferred.bind(Input.MOUSE_MODE_VISIBLE))
