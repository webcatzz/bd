extends Node

var icons: Texture2D = preload("res://assets/icons.png")


func get_icon(coords: Vector2i) -> AtlasTexture:
	var icon := AtlasTexture.new()
	icon.atlas = icons
	icon.region.position = coords * 8.0
	icon.region.size = Vector2(8.0, 8.0)
	return icon
