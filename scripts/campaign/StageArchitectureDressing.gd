class_name StageArchitectureDressing
extends Node2D


class RegionalStageSupport extends Node2D:
	var environment_id: StringName
	var motif_id: StringName
	var support_size := Vector2(220.0, 150.0)
	var flip_horizontal := false

	func configure(environment: StringName, motif: StringName, size: Vector2, flipped: bool) -> void:
		environment_id = environment
		motif_id = motif
		support_size = size
		flip_horizontal = flipped
		name = "%sAssembly" % String(motif_id).to_pascal_case()
		queue_redraw()

	func _draw() -> void:
		if environment_id == &"neon_moon":
			_draw_lunar_support()
		elif environment_id == &"abyssal_night":
			_draw_abyssal_support()

	func _draw_lunar_support() -> void:
		var half_width := support_size.x * 0.5
		var height := support_size.y
		var body := Color("17315d")
		var plate := Color("2f4d7a")
		var edge := Color("8defff")
		var glow := Color("4fc8ff")
		var shadow := Color("09162e")
		draw_rect(Rect2(-half_width, 0.0, support_size.x, height), shadow)
		draw_rect(Rect2(-half_width + 7.0, 0.0, support_size.x - 14.0, height), body)
		draw_rect(Rect2(-half_width + 14.0, 8.0, support_size.x - 28.0, height - 16.0), plate, false, 2.0)
		for row: int in range(maxi(int(height / 28.0), 1)):
			var y := 16.0 + float(row) * 28.0
			var light := glow
			light.a = 0.62 if row % 2 == 0 else 0.32
			draw_line(Vector2(-half_width + 18.0, y), Vector2(half_width - 18.0, y), light, 2.0)
		var rail_color := edge
		rail_color.a = 0.74
		draw_line(Vector2(-half_width + 6.0, 2.0), Vector2(-half_width + 6.0, height), rail_color, 3.0)
		draw_line(Vector2(half_width - 6.0, 2.0), Vector2(half_width - 6.0, height), rail_color, 3.0)
		var is_shaft := "shaft" in String(motif_id) or "lift" in String(motif_id)
		if is_shaft:
			for index: int in range(3):
				var x := (-half_width + 38.0) + float(index) * (support_size.x - 76.0) * 0.5
				draw_line(Vector2(x, 0.0), Vector2(x, height), Color("6ce8ff", 0.52), 2.0)
			var ring_center := Vector2(0.0, minf(height * 0.42, 78.0))
			draw_arc(ring_center, minf(half_width - 22.0, 48.0), 0.1, TAU - 0.1, 24, Color("a5fff0", 0.62), 3.0)
			draw_circle(ring_center, 7.0, Color("d2ffff", 0.9))
		else:
			var pod_center := Vector2(0.0, minf(height * 0.45, 62.0))
			draw_circle(pod_center, minf(half_width * 0.34, 32.0), Color("193f6b"))
			draw_arc(pod_center, minf(half_width * 0.34, 32.0), 0.0, TAU, 20, Color("8defff", 0.75), 2.0)
			draw_line(Vector2(-half_width, 0.0), Vector2(half_width, 0.0), Color("c4ffff", 0.9), 3.0)

	func _draw_abyssal_support() -> void:
		var half_width := support_size.x * 0.5
		var height := support_size.y
		var shadow := Color("16091d")
		var stone := Color("3b1b42")
		var plate := Color("5d294f")
		var trim := Color("f55a8a")
		var corruption := Color("a8ee62")
		var left_x := -half_width if not flip_horizontal else half_width
		var direction := 1.0 if not flip_horizontal else -1.0
		var buttress := PackedVector2Array([
			Vector2(-half_width, 0.0),
			Vector2(half_width, 0.0),
			Vector2(half_width * 0.56, height),
			Vector2(-half_width * 0.74, height),
		])
		draw_colored_polygon(buttress, shadow)
		var inner := PackedVector2Array([
			Vector2(-half_width + 9.0, 5.0),
			Vector2(half_width - 10.0, 5.0),
			Vector2(half_width * 0.42, height - 8.0),
			Vector2(-half_width * 0.58, height - 8.0),
		])
		draw_colored_polygon(inner, stone)
		for row: int in range(maxi(int(height / 30.0), 1)):
			var y := 18.0 + float(row) * 30.0
			var width := maxf(half_width - 18.0 - float(row) * 3.0, 18.0)
			draw_line(Vector2(-width, y), Vector2(width, y), plate, 3.0)
			if row % 2 == 0:
				var vein := trim
				vein.a = 0.58
				draw_line(Vector2(-width * 0.72, y - 5.0), Vector2(width * 0.56, y + 5.0), vein, 1.5)
		var root_color := trim
		root_color.a = 0.8
		draw_line(Vector2(left_x, 0.0), Vector2(left_x + direction * half_width * 0.45, height), root_color, 4.0)
		draw_line(Vector2(-left_x, 0.0), Vector2(-left_x - direction * half_width * 0.32, height), root_color, 3.0)
		if "nest" in String(motif_id) or "corruption" in String(motif_id):
			for index: int in range(3):
				var node_center := Vector2(-half_width * 0.46 + float(index) * half_width * 0.46, 28.0 + float(index % 2) * 38.0)
				draw_circle(node_center, 10.0, Color("4b843f"))
				draw_arc(node_center, 10.0, 0.0, TAU, 12, corruption, 2.0)
		else:
			var relic_center := Vector2(0.0, minf(height * 0.38, 58.0))
			draw_circle(relic_center, 17.0, Color("361d57"))
			draw_arc(relic_center, 22.0, 0.0, TAU, 16, Color("bc9cff", 0.7), 2.0)
			draw_line(Vector2(-half_width, 0.0), Vector2(half_width, 0.0), Color("ffd1df", 0.72), 3.0)


const ASSET_PATHS := {
	&"cyber_rooftop_catwalk": "res://assets/runtime/props/TraversalKits/Generated/cyber_rooftop_catwalk_v1.png",
	&"cyber_billboard_gantry": "res://assets/runtime/props/TraversalKits/Generated/cyber_billboard_gantry_v1.png",
	&"cyber_antenna_shaft": "res://assets/runtime/props/TraversalKits/Generated/cyber_antenna_shaft_v1.png",
	&"cyber_skybridge_truss": "res://assets/runtime/props/TraversalKits/Generated/cyber_skybridge_truss_v1.png",
	&"cyber_elevator_cage": "res://assets/runtime/props/TraversalKits/Generated/cyber_elevator_cage_v1.png",
	&"cyber_antenna_perch": "res://assets/runtime/props/TraversalKits/Generated/cyber_antenna_perch_v1.png",
	&"factory_conveyor": "res://assets/runtime/props/TraversalKits/Generated/factory_conveyor_v1.png",
	&"factory_maintenance_gantry": "res://assets/runtime/props/TraversalKits/Generated/factory_maintenance_gantry_v1.png",
	&"factory_furnace_catwalk": "res://assets/runtime/props/TraversalKits/Generated/factory_furnace_catwalk_v1.png",
	&"factory_cargo_lift": "res://assets/runtime/props/TraversalKits/Generated/factory_cargo_lift_v1.png",
	&"factory_crane_runway": "res://assets/runtime/props/TraversalKits/Generated/factory_crane_runway_v1.png",
	&"factory_crusher_bay": "res://assets/runtime/props/TraversalKits/Generated/factory_crusher_bay_v1.png",
}

var stage_id: StringName
var stage: StageBase
var terrain: TileMapLayer


func configure(stage_node: StageBase, value: StringName) -> void:
	stage = stage_node
	terrain = stage.get_terrain() if stage != null else null
	stage_id = value
	name = "StageArchitectureDressing"
	set_meta(&"stage_id", String(stage_id))
	_build()


func _build() -> void:
	match stage_id:
		&"1-1":
			_add_structure(&"cyber_rooftop_catwalk", Vector2(430.0, 446.0), 0.43, 56.0)
			_add_structure(&"cyber_billboard_gantry", Vector2(980.0, 446.0), 0.31, 302.0)
		&"1-2":
			_add_structure(&"cyber_billboard_gantry", Vector2(560.0, 446.0), 0.31, 302.0)
			_add_structure(&"cyber_skybridge_truss", Vector2(1450.0, 446.0), 0.52, 48.0)
			_add_structure(&"cyber_billboard_gantry", Vector2(2300.0, 446.0), 0.31, 302.0)
			_add_structure(&"cyber_skybridge_truss", Vector2(3400.0, 446.0), 0.52, 48.0, true)
		&"1-3":
			_add_structure(&"cyber_antenna_shaft", Vector2(520.0, 446.0), 0.52, 235.0)
			_add_structure(&"cyber_antenna_shaft", Vector2(1830.0, 446.0), 0.52, 235.0)
			_add_structure(&"cyber_antenna_perch", Vector2(3540.0, 446.0), 0.42, 185.0)
		&"1-4":
			_add_structure(&"cyber_skybridge_truss", Vector2(460.0, 446.0), 0.54, 48.0)
			_add_structure(&"cyber_skybridge_truss", Vector2(1260.0, 446.0), 0.54, 48.0, true)
			_add_structure(&"cyber_skybridge_truss", Vector2(2080.0, 446.0), 0.54, 48.0)
			_add_structure(&"cyber_skybridge_truss", Vector2(3820.0, 446.0), 0.54, 48.0, true)
		&"1-5":
			_add_structure(&"cyber_antenna_perch", Vector2(2160.0, 446.0), 0.38, 185.0)
			_add_structure(&"cyber_rooftop_catwalk", Vector2(3050.0, 446.0), 0.40, 56.0)
		&"2-1":
			_add_structure(&"factory_conveyor", Vector2(220.0, 430.0), 0.38, 0.0)
			_add_structure(&"factory_maintenance_gantry", Vector2(680.0, 430.0), 0.37, 95.0)
			_add_structure(&"factory_furnace_catwalk", Vector2(1120.0, 430.0), 0.34, 245.0)
		&"2-2":
			_add_structure(&"factory_conveyor", Vector2(480.0, 430.0), 0.38, 0.0)
			_add_structure(&"factory_conveyor", Vector2(1560.0, 430.0), 0.38, 0.0, true)
			_add_structure(&"factory_cargo_lift", Vector2(2520.0, 430.0), 0.46, 235.0)
			_add_structure(&"factory_crane_runway", Vector2(3720.0, 430.0), 0.42, 104.0)
		&"2-3":
			_add_structure(&"factory_furnace_catwalk", Vector2(620.0, 430.0), 0.36, 245.0)
			_add_structure(&"factory_furnace_catwalk", Vector2(1820.0, 430.0), 0.36, 245.0, true)
			_add_structure(&"factory_crane_runway", Vector2(2620.0, 430.0), 0.41, 104.0)
			_add_structure(&"factory_furnace_catwalk", Vector2(3700.0, 430.0), 0.36, 245.0)
		&"2-4":
			_add_structure(&"factory_maintenance_gantry", Vector2(560.0, 430.0), 0.40, 95.0)
			_add_structure(&"factory_crusher_bay", Vector2(1560.0, 430.0), 0.37, 170.0)
			_add_structure(&"factory_maintenance_gantry", Vector2(2630.0, 430.0), 0.40, 95.0, true)
			_add_structure(&"factory_crane_runway", Vector2(3740.0, 430.0), 0.42, 104.0)
		&"2-5":
			_add_structure(&"factory_crane_runway", Vector2(2200.0, 430.0), 0.42, 104.0)
			_add_structure(&"factory_crusher_bay", Vector2(3100.0, 430.0), 0.37, 170.0)
		&"3-1":
			_add_regional_structure(&"neon_moon", &"lunar_crater_beacon", Vector2(520.0, 446.0), Vector2(250.0, 142.0))
			_add_regional_structure(&"neon_moon", &"lunar_low_g_pylon", Vector2(1760.0, 446.0), Vector2(226.0, 176.0))
			_add_regional_structure(&"neon_moon", &"lunar_crater_span", Vector2(3370.0, 446.0), Vector2(298.0, 154.0), true)
		&"3-2":
			_add_regional_structure(&"neon_moon", &"cleanroom_airlock", Vector2(620.0, 446.0), Vector2(238.0, 150.0))
			_add_regional_structure(&"neon_moon", &"cleanroom_specimen_stack", Vector2(1940.0, 446.0), Vector2(224.0, 184.0))
			_add_regional_structure(&"neon_moon", &"observation_spine", Vector2(3340.0, 446.0), Vector2(286.0, 162.0), true)
		&"3-3":
			_add_regional_structure(&"neon_moon", &"security_shaft_array", Vector2(640.0, 446.0), Vector2(236.0, 230.0))
			_add_regional_structure(&"neon_moon", &"security_lift_column", Vector2(1980.0, 446.0), Vector2(232.0, 242.0), true)
			_add_regional_structure(&"neon_moon", &"grid_crown_pylon", Vector2(3500.0, 446.0), Vector2(268.0, 210.0))
		&"3-4":
			_add_regional_structure(&"neon_moon", &"biotech_growth_frame", Vector2(590.0, 446.0), Vector2(242.0, 168.0))
			_add_regional_structure(&"neon_moon", &"biotech_gravity_dais", Vector2(2050.0, 446.0), Vector2(258.0, 186.0), true)
			_add_regional_structure(&"neon_moon", &"biotech_containment_pylon", Vector2(3580.0, 446.0), Vector2(238.0, 212.0))
		&"3-5":
			_add_regional_structure(&"neon_moon", &"command_ring_support", Vector2(1840.0, 446.0), Vector2(286.0, 188.0))
			_add_regional_structure(&"neon_moon", &"oracle_telemetry_spire", Vector2(3330.0, 446.0), Vector2(270.0, 226.0), true)
		&"4-1":
			_add_regional_structure(&"abyssal_night", &"outpost_corruption_buttress", Vector2(560.0, 446.0), Vector2(254.0, 170.0))
			_add_regional_structure(&"abyssal_night", &"outpost_ruin_lift", Vector2(1910.0, 446.0), Vector2(236.0, 198.0), true)
			_add_regional_structure(&"abyssal_night", &"outpost_corruption_buttress", Vector2(3490.0, 446.0), Vector2(290.0, 188.0))
		&"4-2":
			_add_regional_structure(&"abyssal_night", &"chasm_cable_buttress", Vector2(620.0, 446.0), Vector2(266.0, 238.0))
			_add_regional_structure(&"abyssal_night", &"chasm_void_lift", Vector2(1960.0, 446.0), Vector2(224.0, 254.0), true)
			_add_regional_structure(&"abyssal_night", &"chasm_cable_buttress", Vector2(3500.0, 446.0), Vector2(282.0, 224.0))
		&"4-3":
			_add_regional_structure(&"abyssal_night", &"nest_rib_buttress", Vector2(560.0, 446.0), Vector2(258.0, 190.0))
			_add_regional_structure(&"abyssal_night", &"nest_corruption_node", Vector2(1980.0, 446.0), Vector2(236.0, 212.0), true)
			_add_regional_structure(&"abyssal_night", &"nest_rib_buttress", Vector2(3600.0, 446.0), Vector2(282.0, 204.0))
		&"4-4":
			_add_regional_structure(&"abyssal_night", &"sanctuary_reliquary_support", Vector2(560.0, 446.0), Vector2(252.0, 206.0))
			_add_regional_structure(&"abyssal_night", &"sanctuary_phase_buttress", Vector2(2020.0, 446.0), Vector2(246.0, 226.0), true)
			_add_regional_structure(&"abyssal_night", &"sanctuary_reliquary_support", Vector2(3620.0, 446.0), Vector2(278.0, 194.0))
		&"4-5":
			_add_regional_structure(&"abyssal_night", &"void_heart_buttress", Vector2(1900.0, 446.0), Vector2(276.0, 220.0))
			_add_regional_structure(&"abyssal_night", &"void_heart_buttress", Vector2(3260.0, 446.0), Vector2(300.0, 250.0), true)


func _add_structure(asset_id: StringName, surface_anchor: Vector2, scale_factor: float, surface_y: float, flip_horizontal := false) -> void:
	var asset_path := String(ASSET_PATHS.get(asset_id, ""))
	if asset_path.is_empty() or not ResourceLoader.exists(asset_path, "Texture2D"):
		push_error("Stage architecture asset is missing: %s" % asset_id)
		return
	var texture := load(asset_path) as Texture2D
	if texture == null:
		push_error("Stage architecture asset failed to load: %s" % asset_path)
		return
	var resolved_anchor := _resolve_static_surface(surface_anchor)
	var sprite := Sprite2D.new()
	sprite.name = "%sSupport" % String(asset_id).to_pascal_case()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = -1
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.flip_h = flip_horizontal
	var scaled_size := texture.get_size() * scale_factor
	var left := resolved_anchor.x - scaled_size.x * 0.5
	if flip_horizontal:
		left = resolved_anchor.x + scaled_size.x * 0.5
	sprite.position = Vector2(left, resolved_anchor.y - surface_y * scale_factor)
	sprite.set_meta(&"asset_id", String(asset_id))
	sprite.set_meta(&"surface_anchor", resolved_anchor)
	add_child(sprite)


func _add_regional_structure(environment_id: StringName, motif_id: StringName, surface_anchor: Vector2, dimensions: Vector2, flip_horizontal := false) -> void:
	var resolved_anchor := _resolve_static_surface(surface_anchor)
	var support := RegionalStageSupport.new()
	support.configure(environment_id, motif_id, dimensions, flip_horizontal)
	support.position = resolved_anchor
	support.z_index = -1
	support.set_meta(&"asset_id", "procedural_%s" % String(motif_id))
	support.set_meta(&"surface_anchor", resolved_anchor)
	support.set_meta(&"environment_id", String(environment_id))
	add_child(support)


func _resolve_static_surface(preferred_anchor: Vector2) -> Vector2:
	if stage == null or terrain == null or terrain.tile_set == null:
		return preferred_anchor
	var target_global := stage.to_global(preferred_anchor)
	var tile_size := Vector2(terrain.tile_set.tile_size)
	var best_anchor := preferred_anchor
	var best_score := INF
	for cell: Vector2i in terrain.get_used_cells():
		# Only an exposed tile may be the visible upper face of a platform.
		if terrain.get_cell_source_id(cell + Vector2i.UP) != -1:
			continue
		var cell_global := terrain.to_global(terrain.map_to_local(cell))
		var surface_global := cell_global - Vector2(0.0, tile_size.y * 0.5)
		# Favor the intended route x-coordinate while still attaching a support to
		# the closest real platform face instead of leaving it floating in space.
		var score := absf(surface_global.x - target_global.x) * 0.5 + absf(surface_global.y - target_global.y)
		if score < best_score:
			best_score = score
			best_anchor = stage.to_local(surface_global)
	return best_anchor
