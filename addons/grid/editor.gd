@tool
extends VBoxContainer

signal redraw_requested

enum Tool {SELECT, DRAW, FILL, REPLACE, MOVE}

var grid: Grid

var tool: Tool = Tool.DRAW
var source_id: int
var tile_id: Vector2i
var erase: bool
var selection_offset: Vector2i

var history: EditorUndoRedoManager
var staged_coords: Array[Vector2i]

var mouse_rect: Rect2i
var mouse_held: bool
var shift_held: bool
var alt_held: bool

@onready var tool_list: ItemList = $Toolbar/ToolList
@onready var source_list: ItemList = $Main/SourceList
@onready var tile_list: ItemList = $Main/TileList


# input

func handle_input(event: InputEventMouse) -> void:
	mouse_held = event.button_mask != MOUSE_BUTTON_MASK_LEFT & MOUSE_BUTTON_MASK_RIGHT
	shift_held = event.shift_pressed
	alt_held = event.alt_pressed
	
	if event is InputEventMouseButton:
		if mouse_held:
			mouse_rect.position = get_mouse_coords()
			mouse_rect.size = Vector2i.ZERO
			erase = event.button_index == MOUSE_BUTTON_RIGHT
		else:
			mouse_rect.end = get_mouse_coords()
		handle_tool_button_input()
	else:
		if mouse_held:
			mouse_rect.end = get_mouse_coords()
		else:
			mouse_rect.position = get_mouse_coords()
			mouse_rect.size = Vector2i.ZERO
	
	stage_tool()
	redraw_requested.emit()


func handle_tool_button_input() -> void:
	match tool:
		Tool.SELECT:
			if mouse_held and is_staged(mouse_rect.end):
				selection_offset = mouse_rect.end - staged_coords.front()
				tool = Tool.MOVE
		Tool.MOVE:
			if not mouse_held:
				move()
				tool = Tool.SELECT
		Tool.DRAW:
			if not mouse_held:
				paint()
		Tool.FILL, Tool.REPLACE:
			if mouse_held:
				paint()


func get_mouse_coords() -> Vector2i:
	return Grid.point_to_coords(grid.get_local_mouse_position())


# staged coords

func stage(coords: Vector2i) -> void:
	var idx: int = staged_coords.bsearch(coords)
	if not is_staged(coords, idx):
		staged_coords.insert(idx, coords)


func stage_rect(rect: Rect2i) -> void:
	for x: int in range(rect.position.x, rect.end.x + 1):
		for y: int in range(rect.position.y, rect.end.y + 1):
			stage(Vector2i(x, y))


func stage_area(coords: Vector2i, source_id: int, tile_id: Vector2i) -> void:
	stage(coords)
	for unit: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var tile: Tile = grid.get_tile(coords + unit)
		if tile and tile.source_id == source_id and tile.tile_id == tile_id and not is_staged(tile.coords):
			stage_area(tile.coords, source_id, tile_id)


func is_staged(coords: Vector2i, idx: int = staged_coords.bsearch(coords)) -> bool:
	return idx < staged_coords.size() and staged_coords[idx] == coords


# tools

func stage_tool() -> void:
	match tool:
		Tool.SELECT: stage_select()
		Tool.MOVE: stage_move()
		Tool.DRAW: stage_draw()
		Tool.FILL: stage_fill()
		Tool.REPLACE: stage_replace()


func stage_select() -> void:
	if mouse_held:
		if not shift_held:
			staged_coords.clear()
		stage_rect(mouse_rect.abs())


func stage_move() -> void:
	var origin: Vector2i = staged_coords.front()
	for i: int in staged_coords.size():
		staged_coords[i] = mouse_rect.end - selection_offset + staged_coords[i] - origin


func stage_draw() -> void:
	if shift_held:
		staged_coords.clear()
		var min_axis: int = mouse_rect.size.abs().min_axis_index()
		mouse_rect.end[min_axis] = mouse_rect.position[min_axis]
		stage_rect(mouse_rect.abs())
	elif alt_held:
		staged_coords.clear()
		stage_rect(mouse_rect.abs())
	else:
		if not mouse_held:
			staged_coords.clear()
		stage(mouse_rect.end)


func stage_fill() -> void:
	staged_coords.clear()
	var tile: Tile = grid.get_tile(mouse_rect.end)
	if tile:
		stage_area(tile.coords, tile.source_id, tile.tile_id)


func stage_replace() -> void:
	staged_coords.clear()
	var filter: Tile = grid.get_tile(mouse_rect.end)
	if filter:
		for tile: Tile in grid.tiles:
			if tile.source_id == filter.source_id and tile.tile_id == filter.tile_id:
				stage(tile.coords)


# actions

func paint() -> void:
	if not staged_coords: return
	history.create_action("Paint tiles")
	
	for coords: Vector2i in staged_coords:
		var tile: Tile = grid.get_tile(coords)
		if tile:
			history.add_undo_method(grid, &"set_tile", coords, tile.source_id, tile.tile_id)
		else:
			history.add_undo_method(grid, &"remove_tile", coords)
		if erase:
			history.add_do_method(grid, &"remove_tile", coords)
		else:
			history.add_do_method(grid, &"set_tile", coords, source_id, tile_id)
	
	history.commit_action()
	staged_coords.clear()
	redraw_requested.emit()


func move() -> void:
	history.create_action("Move tiles")
	
	for coords: Vector2i in staged_coords:
		var start_tile: Tile = grid.get_tile(coords - mouse_rect.size)
		var end_tile: Tile = grid.get_tile(coords)
		if end_tile:
			history.add_undo_method(grid, &"set_tile", end_tile.coords, end_tile.source_id, end_tile.tile_id)
		else:
			history.add_undo_method(grid, &"remove_tile", coords)
		if start_tile:
			history.add_undo_method(grid, &"set_tile", start_tile.coords, start_tile.source_id, start_tile.tile_id)
			history.add_do_method(grid, &"remove_tile", start_tile.coords)
			history.add_do_method(grid, &"set_tile", coords, start_tile.source_id, start_tile.tile_id)
		else:
			history.add_undo_method(grid, &"remove_tile", coords - mouse_rect.size)
	
	history.commit_action()
	redraw_requested.emit()


# drawing

func handle_draw(overlay: Control) -> void:
	var canvas_scale: Vector2 = grid.get_viewport_transform().get_scale()
	var canvas_offset: Vector2 = overlay.get_local_mouse_position() - grid.get_local_mouse_position() * canvas_scale
	overlay.draw_set_transform(canvas_offset, 0.0, canvas_scale)
	
	for coords: Vector2i in staged_coords:
		var point: Vector2 = Grid.coords_to_point(coords)
		var half_x: Vector2 = Grid.RIGHT * 0.5
		var half_y: Vector2 = Grid.DOWN * 0.5
		overlay.draw_colored_polygon([
			point - half_x - half_y,
			point + half_x - half_y,
			point + half_x + half_y,
			point - half_x + half_y,
		], Color(1.0, 1.0, 1.0, 0.125))
	
	overlay.draw_set_transform(Vector2.ZERO)


# list population

func populate_source_list() -> void:
	source_list.clear()
	for i in grid.tile_set.get_source_count():
		var source: TileSetSource = grid.tile_set.get_source(grid.tile_set.get_source_id(i))
		source_list.add_item(source.texture.resource_path.get_file(), source.texture)
	source_list.select(0)
	_on_source_selected(0)


func populate_tile_list() -> void:
	var source: TileSetSource = grid.tile_set.get_source(source_id)
	tile_list.clear()
	for i in source.get_tiles_count():
		var tile_id: Vector2i = source.get_tile_id(i)
		var id: int = tile_list.add_icon_item(get_tile_texture(source, tile_id))
		tile_list.set_item_tooltip(id, str(tile_id))
	tile_list.select(0)
	_on_tile_selection_changed(0, true)


func get_tile_texture(source: TileSetAtlasSource, tile_id: Vector2i) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = source.texture
	texture.region = Rect2(tile_id * source.texture_region_size, source.get_tile_size_in_atlas(tile_id) * source.texture_region_size)
	return texture


# list selection

func _on_tool_selected(idx) -> void:
	staged_coords.clear()
	tool = idx as Tool


func _on_source_selected(idx: int) -> void:
	source_id = grid.tile_set.get_source_id(source_id)


func _on_tile_selection_changed(idx: int, selected: bool) -> void:
	tile_id = grid.tile_set.get_source(source_id).get_tile_id(idx)


# opening & closing

func _on_visibility_changed() -> void:
	if visible:
		if grid and grid.tile_set:
			populate_source_list()
			populate_tile_list()
	else:
		source_list.clear()
		tile_list.clear()


# init

func _ready() -> void:
	tool_list.select(tool)
