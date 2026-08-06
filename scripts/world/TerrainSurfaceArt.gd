class_name TerrainSurfaceArt
extends Node2D

var local_rect := Rect2()
var atlas_regions: Dictionary = {}
var cell_size := 16.0
var source_texture: Texture2D


func configure(size: Vector2, texture: Texture2D, regions: Dictionary, cell: float, source_path: String) -> void:
	local_rect = Rect2(Vector2.ZERO, size)
	source_texture = texture
	atlas_regions = regions.duplicate(true)
	cell_size = cell
	set_meta(&"local_visual_rect", local_rect)
	set_meta(&"source_texture", source_path)
	set_meta(&"tile_cell_size", int(cell))
	queue_redraw()


func _draw() -> void:
	if source_texture == null or cell_size <= 0.0 or local_rect.size.x <= 0.0 or local_rect.size.y <= 0.0:
		return
	var columns := maxi(ceili(local_rect.size.x / cell_size), 1)
	var rows := maxi(ceili(local_rect.size.y / cell_size), 1)
	for row: int in range(rows):
		for column: int in range(columns):
			var tile_key := "fill"
			if row == 0:
				tile_key = "top_left" if column == 0 else ("top_right" if column == columns - 1 else "top_middle")
			var source_region := atlas_regions.get(tile_key, Rect2()) as Rect2
			var destination_position := Vector2(float(column) * cell_size, float(row) * cell_size)
			var remaining := local_rect.size - destination_position
			var drawn_size := Vector2(minf(cell_size, remaining.x), minf(cell_size, remaining.y))
			if drawn_size.x <= 0.0 or drawn_size.y <= 0.0:
				continue
			var clipped_source := Rect2(source_region.position, drawn_size)
			draw_texture_rect_region(source_texture, Rect2(destination_position, drawn_size), clipped_source)
