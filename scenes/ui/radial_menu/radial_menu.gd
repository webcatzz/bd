@tool
class_name RadialMenu
extends Container

signal selected(idx: int)

const RADIUS := 28.0
const START_ANGLE := PI * -0.5
const ITEM_SEPARATION := PI * 0.3
const TWEEN_TIME := 0.2


func move_to(point: Vector2) -> void:
	position = point - size * 0.5


# items

func add_item(text: String, icon: Texture2D, callback: Callable = print.bind(text)) -> void:
	var item: Control = preload("res://scenes/ui/radial_menu/radial_menu_item.tscn").instantiate()
	item.position = (size - item.size) * 0.5
	#item.text = text
	item.icon = icon
	item.pressed.connect(callback)
	item.pressed.connect(queue_free)
	add_child(item)


# sorting

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()


func _sort_children() -> void:
	var controls: Array[Control]
	for child: Node in get_children():
		if child is Control and child.visible:
			controls.append(child)
	# center
	var center: Vector2 = size * 0.5
	controls[0].position = center - controls[0].size * 0.5
	# petals
	var start_angle: float = START_ANGLE + ITEM_SEPARATION * (controls.size()) * -0.5
	var tween: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i: int in range(1, controls.size()):
		tween.tween_property(controls[i], ^"position", center - controls[i].size * 0.5 + Vector2.from_angle(start_angle + ITEM_SEPARATION * i) * RADIUS, TWEEN_TIME)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		queue_free()


func _ready() -> void:
	if not Engine.is_editor_hint():
		for child: Node in get_children():
			if child is Control and child.visible:
				child.grab_focus()
