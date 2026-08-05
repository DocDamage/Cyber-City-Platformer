extends SceneTree

const OUTPUT_ROOT := "res://Stages/TileSets"
const TILE_SHEETS := [
	{
		"name": "Act1_Rooftops2_Palette",
		"texture": "res://assets/runtime/environments/Act1_CyberCity/Rooftops 2/Environment/tileset.png",
		"tile_size": Vector2i(16, 16),
	},
	{
		"name": "Act2_RobotFactory_Palette",
		"texture": "res://assets/runtime/environments/Act2_RobotFactory/Mega Robot Factory/CENA (!)/TILESET/Tileset.png",
		"tile_size": Vector2i(32, 32),
	},
	{
		"name": "Act3_NeonMoon_Palette",
		"texture": "res://assets/runtime/environments/Act3_NeonMoon/Neon Moon Protocol/Trerrain/Terrain 24x24 (1).png",
		"tile_size": Vector2i(24, 24),
	},
	{
		"name": "Act4_AbyssalNight_Palette",
		"texture": "res://assets/runtime/environments/Act4_AbyssalNight/Abyssal Night/Abyssal Night – Color (2)/Trerrain/Terrain 24x24 (1).png",
		"tile_size": Vector2i(24, 24),
	},
]


func _initialize() -> void:
	_build.call_deferred()


func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT))
	var built_count := 0
	for sheet_value: Variant in TILE_SHEETS:
		if _build_tileset(sheet_value):
			built_count += 1
	if built_count != TILE_SHEETS.size():
		push_error("Stage TileSet library is incomplete: built %d of %d." % [built_count, TILE_SHEETS.size()])
		quit(1)
		return
	print("STAGE_TILESET_BUILDER_OK tile_sets=", built_count)
	quit()


func _build_tileset(sheet: Dictionary) -> bool:
	var texture_path := String(sheet.texture)
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("Could not load stage tile sheet: %s" % texture_path)
		return false
	var tile_size: Vector2i = sheet.tile_size
	if texture.get_width() % tile_size.x != 0 or texture.get_height() % tile_size.y != 0:
		push_error("Tile sheet is not an exact %s grid: %s" % [tile_size, texture_path])
		return false

	var tile_set := TileSet.new()
	tile_set.resource_name = String(sheet.name)
	tile_set.tile_size = tile_size
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 0)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = tile_size
	tile_set.add_source(atlas, 0)
	var image := texture.get_image()
	var grid_size := Vector2i(texture.get_width() / tile_size.x, texture.get_height() / tile_size.y)
	var tile_count := 0
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var coordinates := Vector2i(x, y)
			if _tile_has_visible_pixels(image, coordinates, tile_size):
				atlas.create_tile(coordinates)
				var tile_data := atlas.get_tile_data(coordinates, 0)
				tile_data.add_collision_polygon(0)
				tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
					Vector2(-tile_size.x * 0.5, -tile_size.y * 0.5),
					Vector2(tile_size.x * 0.5, -tile_size.y * 0.5),
					Vector2(tile_size.x * 0.5, tile_size.y * 0.5),
					Vector2(-tile_size.x * 0.5, tile_size.y * 0.5),
				]))
				tile_count += 1
	var output_path := OUTPUT_ROOT.path_join("%s.tres" % String(sheet.name))
	if ResourceSaver.save(tile_set, output_path) != OK:
		push_error("Could not save stage TileSet: %s" % output_path)
		return false
	print("  ", sheet.name, ": ", tile_count, " paintable cells")
	return true


func _tile_has_visible_pixels(image: Image, coordinates: Vector2i, tile_size: Vector2i) -> bool:
	if image == null or image.is_empty():
		return true
	var origin := coordinates * tile_size
	for y in range(origin.y, origin.y + tile_size.y):
		for x in range(origin.x, origin.x + tile_size.x):
			if image.get_pixel(x, y).a > 0.01:
				return true
	return false
