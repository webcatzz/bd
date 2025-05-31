@tool
@icon("res://addons/grid/grid.svg")
class_name Grid
extends Node2D

const UP := Vector2(-14.0, -7.0)
const DOWN := Vector2(14.0, 7.0)
const LEFT := Vector2(-10.0, 10.0)
const RIGHT := Vector2(10.0, -10.0)

@export var tile_set: TileSet
@export_storage var tiles: Array[Tile]

var _body: RID
var _astar := AStar2D.new()


# coords

static func coords_to_point(coords: Vector2i) -> Vector2:
	return coords.x * RIGHT + coords.y * DOWN


static func point_to_coords(point: Vector2) -> Vector2i:
	var coords: Vector2
	coords.x = (DOWN.x * point.y - DOWN.y * point.x) / (DOWN.x * RIGHT.y - DOWN.y * RIGHT.x)
	coords.y = (point.x - coords.x * RIGHT.x) / DOWN.x
	return coords.round()


static func snap(point: Vector2) -> Vector2:
	return coords_to_point(point_to_coords(point))


static func unit(vector: Vector2) -> Vector2:
	var angle: float = vector.angle()
	if angle > 0:
		return Grid.LEFT if angle > PI * 0.5 else Grid.DOWN
	else:
		return Grid.UP if angle < -PI * 0.5 else Grid.RIGHT


# tiles

func set_tile(coords: Vector2i, source_id: int, tile_id: Vector2i) -> void:
	remove_tile(coords)
	var tile := Tile.new()
	tile.coords = coords
	tile.source_id = source_id
	tile.tile_id = tile_id
	_list_add_tile(tile)
	_use_tile(tile)


func remove_tile(coords: Vector2i) -> void:
	if not has_tile(coords): return
	_drop_tile(get_tile(coords))
	_list_remove_tile(coords)


func get_tile(coords: Vector2i) -> Tile:
	return _list_get_tile(coords)


func has_tile(coords: Vector2i) -> bool:
	return _list_has_tile(coords)


# tile list

func _list_add_tile(tile: Tile) -> void:
	tiles.insert(_list_idx(tile.coords), tile)


func _list_remove_tile(coords: Vector2i) -> void:
	tiles.remove_at(_list_idx(coords))


func _list_get_tile(coords: Vector2i) -> Tile:
	var idx := _list_idx(coords)
	return tiles[idx] if _list_has_tile(coords, idx) else null


func _list_has_tile(coords: Vector2i, idx := _list_idx(coords)) -> bool:
	return idx < tiles.size() and tiles[idx].coords == coords


func _list_idx(coords: Vector2i) -> int:
	return tiles.map(func(tile: Tile) -> Vector2i: return tile.coords).bsearch_custom(coords, _sort_coords, true)


func _sort_coords(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or a.y == b.y and a.x > b.x


# tile servers

func _use_tile(tile: Tile) -> void:
	var source: TileSetAtlasSource = tile_set.get_source(tile.source_id)
	var data: TileData = source.get_tile_data(tile.tile_id, 0)
	var size: Vector2i = source.get_tile_size_in_atlas(tile.tile_id) * source.texture_region_size
	var transform := Transform2D(0.0, coords_to_point(tile.coords))
	# rendering
	tile.canvas_item = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(tile.canvas_item, get_canvas_item())
	RenderingServer.canvas_item_set_transform(tile.canvas_item, transform)
	RenderingServer.canvas_item_set_z_index(tile.canvas_item, data.z_index)
	RenderingServer.canvas_item_add_texture_rect_region(
		tile.canvas_item,
		Rect2(size * -0.5 - Vector2(data.texture_origin), size),
		source.texture.get_rid(),
		Rect2(tile.tile_id * source.texture_region_size, size)
	)
	# collision
	for layer: int in tile_set.get_physics_layers_count():
		for i: int in data.get_collision_polygons_count(layer):
			var shape: RID = PhysicsServer2D.convex_polygon_shape_create()
			PhysicsServer2D.shape_set_data(shape, data.get_collision_polygon_points(layer, i))
			PhysicsServer2D.body_add_shape(_body, shape, transform)
			tile.collision_shapes.append(shape)
	# navigation
	for layer: int in tile_set.get_navigation_layers_count():
		if data.get_navigation_polygon(layer):
			var region: RID = NavigationServer2D.region_create()
			NavigationServer2D.region_set_navigation_polygon(region, data.get_navigation_polygon(layer))
			NavigationServer2D.region_set_transform(region, transform)
			tile.navigation_regions.append(region)


func _drop_tile(tile: Tile) -> void:
	RenderingServer.free_rid(tile.canvas_item)
	while tile.collision_shapes.size():
		PhysicsServer2D.free_rid(tile.collision_shapes.pop_back())
	while tile.navigation_regions.size():
		NavigationServer2D.free_rid(tile.navigation_regions.pop_back())


# astar

func set_point_open(point: Vector2, open: bool) -> void:
	_astar.set_point_disabled(_astar.get_closest_point(point, true), not open)


func is_point_open(point: Vector2) -> bool:
	return has_point(point) and not _astar.is_point_disabled(_astar.get_closest_point(point, true))


func has_point(point: Vector2) -> bool:
	return point == _astar.get_point_position(_astar.get_closest_point(point, true))


func get_point_path(from: Vector2, to: Vector2, partial := false) -> PackedVector2Array:
	return _astar.get_point_path(_astar.get_closest_point(from), _astar.get_closest_point(to), partial)


func _generate_astar() -> void:
	_astar.clear()
	_astar.reserve_space(maxi(tiles.size(), _astar.get_point_capacity()))
	var max_action_length_squared: float = Action.MAX_LENGTH ** 2.0
	for i: int in tiles.size():
		_astar.add_point(i, coords_to_point(tiles[i].coords))
		for j: int in i:
			if tiles[i].coords.distance_squared_to(tiles[j].coords) < max_action_length_squared:
				_astar.connect_points(i, j)


# physics queries

func query(point: Vector2, params := PhysicsPointQueryParameters2D.new()) -> Array[Node2D]:
	params.position = point
	var colliders: Array[Node2D]
	for collision: Dictionary in get_world_2d().direct_space_state.intersect_point(params):
		colliders.append(collision.collider)
	return colliders


func query_actor(point: Vector2) -> Actor:
	for collider: Node2D in query(point):
		if collider is Actor:
			return collider
	return null


# debug

func draw_collisions(renderer: Node2D) -> void:
	var color: Color = ProjectSettings.get_setting("debug/shapes/collision/shape_color")
	for i: int in PhysicsServer2D.body_get_shape_count(_body):
		var shape: RID = PhysicsServer2D.body_get_shape(_body, i)
		var points: PackedVector2Array
		for point: Vector2 in PhysicsServer2D.shape_get_data(shape):
			points.append(point + PhysicsServer2D.body_get_shape_transform(_body, i).origin)
		renderer.draw_colored_polygon(points, color)
		renderer.draw_polyline(points, color)


# init

func _ready() -> void:
	# navigation
	_generate_astar()
	# debug
	if get_tree().debug_collisions_hint:
		var debug_renderer := Node2D.new()
		debug_renderer.z_index = 1
		debug_renderer.draw.connect(draw_collisions.bind(debug_renderer))
		add_child(debug_renderer)


func _enter_tree() -> void:
	# collision
	_body = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_space(_body, get_world_2d().space)
	PhysicsServer2D.body_set_mode(_body, PhysicsServer2D.BODY_MODE_STATIC)
	PhysicsServer2D.body_attach_object_instance_id(_body, get_instance_id())
	# tiles
	for tile: Tile in tiles:
		_use_tile(tile)


func _exit_tree() -> void:
	# collision
	PhysicsServer2D.free_rid(_body)
	# tiles
	for tile: Tile in tiles:
		_drop_tile(tile)
