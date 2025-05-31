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

@export var debug: bool

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
	tile.draw(self)
	_list_add_tile(tile)

func remove_tile(coords: Vector2i) -> void:
	if not has_tile(coords): return
	get_tile(coords).kill()
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


# physics

func at(point: Vector2) -> Area2D:
	var params := PhysicsPointQueryParameters2D.new()
	params.collide_with_bodies = false
	params.collide_with_areas = true
	params.collision_mask = 0b1
	params.position = point
	var collisions := get_world_2d().direct_space_state.intersect_point(params, 1)
	return collisions.front().collider if collisions else null


func ray(from: Vector2, to: Vector2) -> CollisionObject2D:
	var params := PhysicsRayQueryParameters2D.create(from, to)
	params.collide_with_areas = true
	var collision := get_world_2d().direct_space_state.intersect_ray(params)
	return collision.collider


func ray_all(from: Vector2, to: Vector2) -> Array[CollisionObject2D]:
	var colliders: Array[CollisionObject2D]
	var params := PhysicsRayQueryParameters2D.create(from, to)
	params.collide_with_areas = true
	
	while true:
		var collision := get_world_2d().direct_space_state.intersect_ray(params)
		if collision:
			colliders.append(collision.collider)
			params.exclude.append(collision.collider.get_rid())
		else:
			break
	
	return colliders


# polygons

func add_collision_polygon(points: PackedVector2Array, coords: Vector2i) -> void:
	var shape: RID = PhysicsServer2D.convex_polygon_shape_create()
	PhysicsServer2D.shape_set_data(shape, points)
	PhysicsServer2D.body_add_shape(_body, shape, Transform2D(0.0, coords_to_point(coords)))


func add_nav_polygon(nav_poly: NavigationPolygon, point: Vector2) -> void:
	var nav_region := NavigationRegion2D.new()
	nav_region.navigation_polygon = nav_poly
	nav_region.position = point
	add_child(nav_region)


# debug

func draw_debug(renderer: Node2D) -> void:
	var color: Color
	# collision
	color = Color(Color.RED, 0.5)
	for i: int in PhysicsServer2D.body_get_shape_count(_body):
		var shape: RID = PhysicsServer2D.body_get_shape(_body, i)
		var points: PackedVector2Array
		for point: Vector2 in PhysicsServer2D.shape_get_data(shape):
			points.append(point + PhysicsServer2D.body_get_shape_transform(_body, i).origin)
		renderer.draw_polyline(points, color)
		renderer.draw_colored_polygon(points, Color(color, 0.5))
	# astar
	color = Color(Color.GOLD, 0.5)
	for id: int in _astar.get_point_ids():
		var point: Vector2 = _astar.get_point_position(id)
		renderer.draw_circle(point, 2.0, color, not _astar.is_point_disabled(id))
		for connected_id: int in _astar.get_point_connections(id):
			if id > connected_id:
				renderer.draw_line(point, _astar.get_point_position(connected_id), Color(color, 0.5))


# init

func _ready() -> void:
	if not Engine.is_editor_hint():
		# collision
		_body = PhysicsServer2D.body_create()
		PhysicsServer2D.body_set_space(_body, get_world_2d().space)
		PhysicsServer2D.body_set_mode(_body, PhysicsServer2D.BODY_MODE_STATIC)
	# tiles
	for tile: Tile in tiles:
		tile.draw(self)
	if not Engine.is_editor_hint():
		# navigation
		_generate_astar()
		# debug
		if debug:
			var debug_renderer := Node2D.new()
			debug_renderer.z_index = 1
			debug_renderer.draw.connect(draw_debug.bind(debug_renderer))
			add_child(debug_renderer)


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		# collision
		for i: int in PhysicsServer2D.body_get_shape_count(_body):
			PhysicsServer2D.free_rid(PhysicsServer2D.body_get_shape(_body, i))
		PhysicsServer2D.free_rid(_body)
	# tiles
	for tile: Tile in tiles:
		tile.kill()
