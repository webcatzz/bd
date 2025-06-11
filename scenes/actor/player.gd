class_name Player
extends Actor

var hover_action: Action


# turn

func _turn_logic() -> void:
	set_process_unhandled_input(true)
	add_hover_action()


func end_turn() -> void:
	set_process_unhandled_input(false)
	if hover_action:
		path.pop().queue_free()
		hover_action = null
	super()


# input

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("right_click"):
		open_radial_menu()
	elif hover_action:
		if event is InputEventMouseMotion:
			update_hover_action()
		elif event.is_action_pressed("click"):
			commit_hover_action()


func open_radial_menu() -> void:
	var menu: RadialMenu = Game.cursor.open_menu()
	if hover_action:
		if hover_action.type != Action.Type.MOVE:
			menu.add_item("Cross", Lib.get_icon(Lib.Icon.O), set_hover_action_type.bind(Action.Type.MOVE))
		if hover_action.type != Action.Type.HIT:
			menu.add_item("Strike", Lib.get_icon(Lib.Icon.X), set_hover_action_type.bind(Action.Type.HIT))
	else:
		menu.add_item("Cross", Lib.get_icon(Lib.Icon.O), push_error, true)
	menu.add_item("Edit path", Lib.get_icon(Lib.Icon.PATH), open_path_menu)
	menu.add_item("Commit", Lib.get_icon(Lib.Icon.CHECK), end_turn)


func open_path_menu() -> void:
	var menu: RadialMenu = Game.cursor.open_menu()
	menu.add_item("Undo", Lib.get_icon(Lib.Icon.ARROW_SPIN_PREV), undo_path, path.size() > 1)
	menu.add_item("Clear", Lib.get_icon(Lib.Icon.ARROW_IN_PREV), clear_path, path.size() > 1)


# hover action

func add_hover_action() -> void:
	hover_action = path.push()
	hover_action.modulate.a = 0.5
	update_hover_action()


func update_hover_action() -> void:
	var cursor_point: Vector2 = hover_action.start + Grid.coords_to_point(Vector2(Grid.point_to_coords(get_global_mouse_position() - hover_action.start)).limit_length(Action.MAX_LENGTH))
	match hover_action.type:
		Action.Type.MOVE:
			hover_action.end = cursor_point
		Action.Type.HIT:
			hover_action.target = cursor_point
			hover_action.end = cursor_point + Grid.unit(hover_action.start - cursor_point)
	hover_action.force_raycast_update()
	hover_action.is_possible = not hover_action.is_colliding()


func set_hover_action_type(type: Action.Type) -> void:
	if hover_action:
		hover_action.type = type
		update_hover_action()


func commit_hover_action() -> void:
	if not hover_action.is_possible: return
	hover_action.modulate.a = 1.0
	hover_action = null
	if path.size() < path.max_size:
		add_hover_action()


func clear_path() -> void:
	path.clear()
	add_hover_action()


func undo_path() -> void:
	path.pop().queue_free()
	path.pop().queue_free()
	add_hover_action()


# init

func _ready() -> void:
	Game.player = self
	set_process_unhandled_input(false)
