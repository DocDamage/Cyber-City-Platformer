extends Node2D

const ROOF_LEFT := Vector2i(0, 0)
const ROOF_MIDDLE := Vector2i(1, 0)
const ROOF_RIGHT := Vector2i(2, 0)

@onready var terrain: TileMapLayer = $"Rooftop Terrain"


func _ready() -> void:
	_paint_rooftop_layout()


func _paint_rooftop_layout() -> void:
	terrain.clear()
	_paint_rooftop(-4, 44, 14)
	_paint_rooftop(7, 14, 10)
	_paint_rooftop(17, 24, 8)
	for y in range(5, 14):
		terrain.set_cell(Vector2i(28, y), 0, ROOF_MIDDLE)


func _paint_rooftop(start_x: int, end_x: int, y: int) -> void:
	for x in range(start_x, end_x):
		var atlas_coordinates := ROOF_MIDDLE
		if x == start_x:
			atlas_coordinates = ROOF_LEFT
		elif x == end_x - 1:
			atlas_coordinates = ROOF_RIGHT
		terrain.set_cell(Vector2i(x, y), 0, atlas_coordinates)
