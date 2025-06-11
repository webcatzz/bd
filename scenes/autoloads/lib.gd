extends Node

enum Icon {
	CLOSE,
	ARROW_PREV,
	ARROW_NEXT,
	ARROW_DOUBLE_PREV,
	ARROW_DOUBLE_NEXT,
	ARROW_OUT_PREV,
	ARROW_OUT_NEXT,
	ARROW_IN_PREV,
	ARROW_IN_NEXT,
	ARROW_SPIN_PREV,
	ARROW_SPIN_NEXT,
	O,
	X,
	CHECK,
	PATH,
}

const ICONS := preload("res://assets/icons.png")


func get_icon(idx: int) -> AtlasTexture:
	var icon := AtlasTexture.new()
	var columns: int = ICONS.get_width() / 8
	icon.atlas = ICONS
	icon.region.size = Vector2(8.0, 8.0)
	icon.region.position = Vector2(idx % columns, idx / columns) * 8.0
	return icon
