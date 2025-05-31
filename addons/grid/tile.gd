@tool
class_name Tile
extends Resource

@export var coords: Vector2i
@export var source_id: int
@export var tile_id: Vector2i

var canvas_item: RID
var collision_shapes: Array[RID]
var navigation_regions: Array[RID]
