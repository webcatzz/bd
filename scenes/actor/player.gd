class_name Player
extends Actor

var action_mode: Action.Type : set = _set_action_mode
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		end_turn()
	elif event.is_action_pressed("right_click"):
		while path.size():
			path.pop().queue_free()
		add_hover_action()
	elif hover_action:
		if event is InputEventMouseMotion:
			update_hover_action()
		elif event.is_action_pressed("click"):
			commit_hover_action()
		elif event.is_action_pressed("mode_move"):
			action_mode = Action.Type.MOVE
		elif event.is_action_pressed("mode_hit"):
			action_mode = Action.Type.HIT


# hover action

func add_hover_action() -> void:
	hover_action = path.push()
	hover_action.type = action_mode
	hover_action.modulate.a = 0.5
	update_hover_action()


func update_hover_action() -> void:
	var cursor_point: Vector2 = hover_action.start + Grid.coords_to_point(Vector2(Grid.point_to_coords(get_global_mouse_position() - hover_action.start)).limit_length(Action.MAX_DISTANCE))
	match hover_action.type:
		Action.Type.MOVE:
			hover_action.end = cursor_point
		Action.Type.HIT:
			hover_action.target = cursor_point
			hover_action.end = cursor_point + Grid.unit(hover_action.start - cursor_point)


func commit_hover_action() -> void:
	hover_action.modulate.a = 1.0
	hover_action = null
	if path.size() < path.max_size:
		add_hover_action()


func _set_action_mode(value: Action.Type) -> void:
	action_mode = value
	if hover_action:
		hover_action.type = value
	update_hover_action()


# init

func _ready() -> void:
	set_process_unhandled_input(false)
