class_name AuthoredTraversal
extends Node2D


class SafetyStripArt extends Node2D:
	var deck_size := Vector2(128.0, 18.0)
	var environment_id: StringName = &"cyber_city"

	func configure(size: Vector2, environment: StringName) -> void:
		deck_size = size
		environment_id = environment
		queue_redraw()

	func _draw() -> void:
		var half := deck_size * 0.5
		var stripe_color := Color("f6b445")
		var band_height := minf(5.0, maxf(3.0, deck_size.y - 5.0))
		var band_y := -half.y + 2.0
		var segment_width := 18.0 if environment_id == &"robot_factory" else 24.0
		var segment_count := maxi(int(floor(deck_size.x / segment_width)), 1)
		for index: int in range(segment_count):
			var left := -half.x + float(index) * segment_width + 3.0
			var right := minf(left + segment_width - 5.0, half.x - 3.0)
			if right - left < 5.0:
				continue
			draw_line(Vector2(left, band_y), Vector2(minf(left + 7.0, right), band_y + band_height), stripe_color, 2.0, false)
			draw_line(Vector2(maxf(right - 7.0, left), band_y), Vector2(right, band_y + band_height), stripe_color, 2.0, false)


class RegionalTraversalAssembly extends Node2D:
	var environment_id: StringName
	var architecture_id: StringName
	var section_kind: StringName
	var layout_height := 420.0

	func configure(environment: StringName, architecture: StringName, kind: StringName, height: float) -> void:
		environment_id = environment
		architecture_id = architecture
		section_kind = kind
		layout_height = height
		name = "%sTraversalAssembly" % String(architecture_id).to_pascal_case()
		set_meta(&"environment_id", String(environment_id))
		set_meta(&"architecture_id", String(architecture_id))
		queue_redraw()

	func _draw() -> void:
		if environment_id == &"neon_moon":
			_draw_lunar_assembly()
		elif environment_id == &"abyssal_night":
			_draw_abyssal_assembly()

	func _draw_lunar_assembly() -> void:
		var span := 400.0 if section_kind != &"wall_jump_shaft" else 196.0
		var top := -minf(layout_height, 430.0)
		var deep_blue := Color("102850")
		var plate_blue := Color("20487c")
		var cyan := Color("80f4ff")
		var mint := Color("a7ffe2")
		var magenta := Color("d486ff")
		if section_kind == &"wall_jump_shaft":
			for side: float in [-82.0, 82.0]:
				draw_rect(Rect2(side - 11.0, top, 22.0, -top + 18.0), deep_blue)
				draw_line(Vector2(side - 7.0, top), Vector2(side - 7.0, 8.0), cyan, 2.0)
				draw_line(Vector2(side + 7.0, top), Vector2(side + 7.0, 8.0), cyan, 2.0)
			for index: int in range(maxi(int((-top) / 82.0), 1)):
				var y := top + 32.0 + float(index) * 82.0
				draw_line(Vector2(-82.0, y), Vector2(82.0, y), plate_blue, 5.0)
				if index % 2 == 0:
					draw_circle(Vector2(0.0, y), 7.0, mint)
			return
		var rail_y := -50.0
		draw_rect(Rect2(-span * 0.5, rail_y, span, 20.0), deep_blue)
		draw_line(Vector2(-span * 0.5, rail_y), Vector2(span * 0.5, rail_y), cyan, 3.0)
		draw_line(Vector2(-span * 0.5 + 18.0, rail_y + 14.0), Vector2(span * 0.5 - 18.0, rail_y + 14.0), plate_blue.lightened(0.2), 2.0)
		for index: int in range(5):
			var x := -span * 0.42 + float(index) * span * 0.21
			var drop := 42.0 + float((index + int(String(architecture_id).length())) % 3) * 20.0
			draw_line(Vector2(x, rail_y + 18.0), Vector2(x + 18.0, rail_y + drop), plate_blue, 6.0)
			draw_line(Vector2(x + 18.0, rail_y + drop), Vector2(x + 38.0, rail_y + 18.0), plate_blue, 4.0)
			if index % 2 == 1:
				draw_circle(Vector2(x + 18.0, rail_y - 12.0), 9.0, Color("163763"))
				draw_arc(Vector2(x + 18.0, rail_y - 12.0), 12.0, 0.0, TAU, 14, mint, 2.0)
		if section_kind == &"low_gravity_gap" or section_kind == &"long_gap":
			var emitter := Vector2(0.0, rail_y - 84.0)
			draw_circle(emitter, 20.0, Color("315a97", 0.72))
			draw_arc(emitter, 29.0, 0.0, TAU, 20, cyan, 3.0)
			draw_arc(emitter, 39.0, 0.0, TAU, 20, magenta, 1.5)
		elif section_kind == &"moving_platform_route":
			draw_line(Vector2(-span * 0.18, top * 0.42), Vector2(-span * 0.18, rail_y), cyan, 2.0)
			draw_line(Vector2(span * 0.18, top * 0.42), Vector2(span * 0.18, rail_y), cyan, 2.0)
			draw_arc(Vector2(0.0, top * 0.42), 34.0, 0.0, TAU, 18, mint, 2.0)

	func _draw_abyssal_assembly() -> void:
		var span := 410.0 if section_kind != &"wall_jump_shaft" else 190.0
		var top := -minf(layout_height, 430.0)
		var black := Color("150919")
		var stone := Color("3b193d")
		var wine := Color("652748")
		var red := Color("f04f7f")
		var sickly := Color("a7ed64")
		if section_kind == &"wall_jump_shaft":
			for side: float in [-82.0, 82.0]:
				draw_rect(Rect2(side - 15.0, top, 30.0, -top + 20.0), black)
				draw_line(Vector2(side, top), Vector2(side, 5.0), wine, 8.0)
				draw_line(Vector2(side + (7.0 if side < 0.0 else -7.0), top), Vector2(side + (7.0 if side < 0.0 else -7.0), 5.0), red, 2.0)
			for index: int in range(maxi(int((-top) / 76.0), 1)):
				var y := top + 34.0 + float(index) * 76.0
				draw_arc(Vector2(0.0, y), 78.0, PI, TAU, 16, stone, 6.0)
			return
		var base_y := -48.0
		draw_rect(Rect2(-span * 0.5, base_y, span, 21.0), black)
		draw_line(Vector2(-span * 0.5, base_y + 3.0), Vector2(span * 0.5, base_y + 3.0), red, 2.0)
		for index: int in range(4):
			var x := -span * 0.38 + float(index) * span * 0.255
			var rib_height := 58.0 + float((index + int(String(architecture_id).length())) % 3) * 18.0
			var points := PackedVector2Array([
				Vector2(x - 22.0, base_y + 19.0),
				Vector2(x, base_y - rib_height),
				Vector2(x + 24.0, base_y + 19.0),
			])
			draw_polyline(points, stone, 10.0, true)
			draw_polyline(points, wine, 4.0, true)
			if index % 2 == 0:
				draw_circle(Vector2(x, base_y - rib_height * 0.58), 9.0, Color("477438"))
				draw_arc(Vector2(x, base_y - rib_height * 0.58), 12.0, 0.0, TAU, 14, sickly, 2.0)
		if section_kind == &"moving_platform_route" or section_kind == &"dash_gap":
			draw_arc(Vector2(0.0, base_y - 86.0), 62.0, PI * 1.08, TAU * 0.92, 20, red, 3.0)
			draw_arc(Vector2(0.0, base_y - 86.0), 78.0, PI * 1.12, TAU * 0.88, 20, wine.lightened(0.2), 2.0)
		if "sanctuary" in String(architecture_id):
			draw_line(Vector2(-span * 0.32, top * 0.36), Vector2(-span * 0.32, base_y), Color("bda4ff", 0.64), 3.0)
			draw_line(Vector2(span * 0.32, top * 0.36), Vector2(span * 0.32, base_y), Color("bda4ff", 0.64), 3.0)


class TraversalDeckPresentation extends Node2D:
	var deck_size := Vector2(128.0, 18.0)
	var environment_id: StringName = &"cyber_city"
	var architecture_id: StringName = &"rooftop_steps"
	var deck_role: StringName
	var show_hazard_marks := false

	func configure(size: Vector2, environment: StringName, architecture: StringName, traversal_kind: StringName, role: StringName) -> void:
		deck_size = size
		environment_id = environment
		architecture_id = architecture
		deck_role = role
		show_hazard_marks = traversal_kind == &"hazard_steps" or traversal_kind == &"dash_gap" or traversal_kind == &"long_gap" or traversal_kind == &"low_gravity_gap"
		set_meta(&"environment_id", String(environment_id))
		set_meta(&"architecture_id", String(architecture_id))
		set_meta(&"deck_role", String(deck_role))
		set_meta(&"collision_surface_size", deck_size)
		if deck_role != &"shaft_wall":
			var visual_depth_cells := 1 if environment_id == &"robot_factory" else 2
			var terrain_art := TerrainPlatform.create_surface_art(deck_size, String(environment_id), visual_depth_cells, environment_id == &"cyber_city")
			if terrain_art != null:
				terrain_art.name = "SurfaceTiles"
				add_child(terrain_art)
		if show_hazard_marks:
			var safety_strip := SafetyStripArt.new()
			safety_strip.name = "SafetyMarks"
			safety_strip.configure(deck_size, environment_id)
			add_child(safety_strip)


class ArchitecturePresentation extends Node2D:
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

	var architecture_id: StringName
	var environment_id: StringName
	var section_kind: StringName
	var layout_height := 420.0

	func configure(architecture: StringName, environment: StringName, kind: StringName, height: float) -> void:
		architecture_id = architecture
		environment_id = environment
		section_kind = kind
		layout_height = height
		name = "Architecture"
		set_meta(&"architecture_id", String(architecture_id))
		set_meta(&"environment_id", String(environment_id))
		_build()

	func _build() -> void:
		if environment_id == &"neon_moon" or environment_id == &"abyssal_night":
			_add_regional_assembly()
			return
		match architecture_id:
			&"rooftop_steps":
				_add_structure(&"cyber_rooftop_catwalk", Vector2(-150.0, -54.0), 0.33, 56.0)
				_add_structure(&"cyber_rooftop_catwalk", Vector2(0.0, -104.0), 0.33, 56.0)
				_add_structure(&"cyber_rooftop_catwalk", Vector2(150.0, -54.0), 0.33, 56.0, true)
			&"service_shaft", &"antenna_shaft":
				_add_structure(&"cyber_antenna_shaft", Vector2(-82.0, -layout_height * 0.48), 0.32, 235.0)
				_add_structure(&"cyber_antenna_shaft", Vector2(82.0, -layout_height * 0.48), 0.32, 235.0, true)
				_add_structure(&"cyber_antenna_perch", Vector2(0.0, -layout_height - 10.0), 0.38, 185.0)
			&"billboard_bypass":
				_add_structure(&"cyber_billboard_gantry", Vector2(-70.0, -164.0), 0.36, 302.0)
				_add_structure(&"cyber_antenna_perch", Vector2(270.0, -134.0), 0.31, 184.0)
			&"billboard_lifts":
				_add_structure(&"cyber_elevator_cage", Vector2(0.0, -92.0), 0.42, 250.0)
				_add_structure(&"cyber_rooftop_catwalk", Vector2(-280.0, -49.0), 0.42, 56.0)
				_add_structure(&"cyber_rooftop_catwalk", Vector2(280.0, -129.0), 0.42, 56.0, true)
			&"broken_skybridge":
				_add_structure(&"cyber_skybridge_truss", Vector2(-210.0, -84.0), 0.48, 48.0)
				_add_structure(&"cyber_skybridge_truss", Vector2(210.0, -84.0), 0.48, 48.0, true)
			&"spire_ascent":
				_add_structure(&"cyber_antenna_shaft", Vector2(0.0, -225.0), 0.60, 260.0)
				_add_structure(&"cyber_antenna_perch", Vector2(150.0, -400.0), 0.34, 184.0)
			&"skybridge_carriage":
				_add_structure(&"cyber_elevator_cage", Vector2(0.0, -118.0), 0.50, 245.0)
				_add_structure(&"cyber_skybridge_truss", Vector2(-280.0, -49.0), 0.44, 48.0)
				_add_structure(&"cyber_skybridge_truss", Vector2(280.0, -129.0), 0.44, 48.0, true)
			&"intake_conveyors", &"reversal_conveyors":
				_add_structure(&"factory_conveyor", Vector2(-210.0, -79.0), 0.35, 0.0)
				_add_structure(&"factory_conveyor", Vector2(0.0, -134.0), 0.31, 0.0)
				_add_structure(&"factory_conveyor", Vector2(210.0, -79.0), 0.35, 0.0, true)
			&"cargo_transfer":
				_add_structure(&"factory_cargo_lift", Vector2(0.0, -120.0), 0.48, 235.0)
				_add_structure(&"factory_maintenance_gantry", Vector2(-280.0, -49.0), 0.39, 95.0)
				_add_structure(&"factory_crane_runway", Vector2(280.0, -129.0), 0.39, 104.0)
			&"furnace_gantry":
				_add_structure(&"factory_furnace_catwalk", Vector2(0.0, -205.0), 0.42, 245.0)
				_add_structure(&"factory_crane_runway", Vector2(150.0, -399.0), 0.36, 100.0)
			&"forge_laser_walk":
				_add_structure(&"factory_furnace_catwalk", Vector2(0.0, -104.0), 0.36, 245.0)
				_add_structure(&"factory_maintenance_gantry", Vector2(-190.0, -49.0), 0.28, 94.0)
				_add_structure(&"factory_maintenance_gantry", Vector2(190.0, -49.0), 0.28, 94.0, true)
			&"crusher_bay":
				_add_structure(&"factory_crusher_bay", Vector2(0.0, -104.0), 0.39, 170.0)
				_add_structure(&"factory_maintenance_gantry", Vector2(-190.0, -49.0), 0.27, 94.0)
				_add_structure(&"factory_maintenance_gantry", Vector2(190.0, -49.0), 0.27, 94.0, true)
			&"maintenance_bypass":
				_add_structure(&"factory_maintenance_gantry", Vector2(-70.0, -164.0), 0.39, 95.0)
				_add_structure(&"factory_crane_runway", Vector2(270.0, -134.0), 0.34, 103.0)
			_:
				if environment_id == &"robot_factory":
					_add_structure(&"factory_maintenance_gantry", Vector2.ZERO, 0.36, 95.0)
				else:
					_add_structure(&"cyber_rooftop_catwalk", Vector2.ZERO, 0.36, 56.0)

	func _add_regional_assembly() -> void:
		var assembly := RegionalTraversalAssembly.new()
		assembly.configure(environment_id, architecture_id, section_kind, layout_height)
		assembly.z_index = -1
		assembly.set_meta(&"asset_id", "procedural_%s" % String(architecture_id))
		assembly.set_meta(&"environment_id", String(environment_id))
		add_child(assembly)

	func _add_structure(asset_id: StringName, surface_anchor: Vector2, scale_factor: float, surface_y: float, flip_horizontal := false) -> void:
		var asset_path := String(ASSET_PATHS.get(asset_id, ""))
		if asset_path.is_empty() or not ResourceLoader.exists(asset_path, "Texture2D"):
			push_error("Traversal architecture asset is missing: %s" % asset_id)
			return
		var texture := load(asset_path) as Texture2D
		if texture == null:
			push_error("Traversal architecture asset failed to load: %s" % asset_path)
			return
		var sprite := Sprite2D.new()
		sprite.name = String(asset_id).to_pascal_case()
		sprite.texture = texture
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.flip_h = flip_horizontal
		var scaled_size := texture.get_size() * scale_factor
		var left := surface_anchor.x - scaled_size.x * 0.5
		if flip_horizontal:
			left = surface_anchor.x + scaled_size.x * 0.5
		sprite.position = Vector2(left, surface_anchor.y - surface_y * scale_factor)
		sprite.set_meta(&"asset_id", String(asset_id))
		sprite.set_meta(&"surface_anchor", surface_anchor)
		add_child(sprite)


var section_id: StringName
var section_kind: StringName
var architecture_id: StringName
var environment_id: StringName = &"cyber_city"
var optional_route := false
var _platforms: Array[StaticBody2D] = []


func configure(entry: Dictionary, environment: StringName = &"cyber_city") -> void:
	section_id = StringName(entry.get("id", "traversal"))
	section_kind = StringName(entry.get("kind", "jump_steps"))
	architecture_id = StringName(entry.get("architecture", _fallback_architecture()))
	environment_id = environment
	optional_route = bool(entry.get("optional", false))
	name = "Traversal_%s" % section_id
	position = entry.get("position", Vector2.ZERO)
	set_meta(&"architecture_id", String(architecture_id))
	set_meta(&"environment_id", String(environment_id))
	_build_layout(float(entry.get("height", 420.0)))


func get_descriptor() -> Dictionary:
	return {
		"id": String(section_id),
		"kind": String(section_kind),
		"architecture": String(architecture_id),
		"environment": String(environment_id),
		"optional": optional_route,
		"platform_count": _platforms.size(),
	}


func get_route_platforms() -> Array[Dictionary]:
	var platforms: Array[Dictionary] = []
	for platform: StaticBody2D in _platforms:
		var collision := platform.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or collision.shape is not RectangleShape2D:
			continue
		platforms.append({
			"center": collision.global_position,
			"size": (collision.shape as RectangleShape2D).size,
			"role": String(platform.get_meta(&"architecture_role", "")),
		})
	return platforms


func _ready() -> void:
	add_to_group(&"authored_traversal")


func _fallback_architecture() -> StringName:
	match section_kind:
		&"wall_jump_shaft": return &"service_shaft"
		&"vertical_route": return &"spire_ascent"
		&"high_route": return &"billboard_bypass"
		&"moving_platform_route": return &"billboard_lifts"
		&"dash_gap", &"long_gap", &"low_gravity_gap": return &"broken_skybridge"
		&"conveyor_route": return &"intake_conveyors"
		&"hazard_steps": return &"crusher_bay"
		_: return &"rooftop_steps"


func _build_layout(height: float) -> void:
	var architecture := ArchitecturePresentation.new()
	architecture.configure(architecture_id, environment_id, section_kind, height)
	add_child(architecture)
	if _build_architecture_specific_layout(height):
		_add_optional_route_marker()
		return
	match section_kind:
		&"wall_jump_shaft":
			_add_platform(Vector2(-82, -height * 0.5), Vector2(24, height), &"shaft_wall")
			_add_platform(Vector2(82, -height * 0.5), Vector2(24, height), &"shaft_wall")
			_add_platform(Vector2(0, -height), Vector2(190, 20), &"shaft_cap")
		&"vertical_route":
			_add_platform(Vector2(-145, -80), Vector2(150, 18), &"ascent_ledge")
			_add_platform(Vector2(90, -180), Vector2(135, 18), &"ascent_ledge")
			_add_platform(Vector2(-90, -290), Vector2(135, 18), &"ascent_ledge")
			_add_platform(Vector2(150, -390), Vector2(160, 18), &"ascent_cap")
		&"high_route":
			_add_platform(Vector2(-240, -80), Vector2(150, 18), &"perch")
			_add_platform(Vector2(-70, -155), Vector2(130, 18), &"perch")
			_add_platform(Vector2(105, -205), Vector2(130, 18), &"perch")
			_add_platform(Vector2(270, -125), Vector2(150, 18), &"perch")
		&"dash_gap", &"long_gap", &"low_gravity_gap":
			_add_platform(Vector2(-160, -75), Vector2(190, 18), &"bridge_segment")
			_add_platform(Vector2(160, -75), Vector2(190, 18), &"bridge_segment")
		&"moving_platform_route":
			_add_platform(Vector2(-280, -40), Vector2(180, 18), &"terminal_platform")
			_add_platform(Vector2(280, -120), Vector2(180, 18), &"terminal_platform")
		&"conveyor_route":
			_add_platform(Vector2(-210, -70), Vector2(170, 18), &"conveyor_bay")
			_add_platform(Vector2(0, -125), Vector2(150, 18), &"conveyor_bay")
			_add_platform(Vector2(210, -70), Vector2(170, 18), &"conveyor_bay")
		&"hazard_steps":
			_add_platform(Vector2(-190, -40), Vector2(115, 18), &"hazard_bay")
			_add_platform(Vector2(0, -95), Vector2(115, 18), &"hazard_bay")
			_add_platform(Vector2(190, -40), Vector2(115, 18), &"hazard_bay")
		_:
			_add_platform(Vector2(-150, -45), Vector2(130, 18), &"roof_step")
			# Keep the first teaching rise inside the normal jump envelope rather
			# than asking for a frame-perfect apex from a standing start.
			_add_platform(Vector2(0, -92), Vector2(130, 18), &"roof_step")
			_add_platform(Vector2(150, -45), Vector2(130, 18), &"roof_step")
	_add_optional_route_marker()


func _build_architecture_specific_layout(height: float) -> bool:
	match architecture_id:
		&"billboard_bypass":
			# An asymmetric billboard climb: each cantilever looks forward to the
			# next sign rather than repeating a neutral stair pattern.
			_add_platform(Vector2(-260, -72), Vector2(160, 18), &"sign_approach")
			_add_platform(Vector2(-100, -120), Vector2(130, 18), &"sign_cantilever")
			_add_platform(Vector2(60, -168), Vector2(126, 18), &"sign_cantilever")
			_add_platform(Vector2(220, -120), Vector2(170, 18), &"sign_exit")
			return true
		&"billboard_lifts":
			# The lift route has a clear embark, transfer, and disembark rhythm.
			_add_platform(Vector2(-305, -42), Vector2(178, 18), &"lift_embark")
			_add_platform(Vector2(-24, -102), Vector2(132, 18), &"lift_transfer")
			_add_platform(Vector2(300, -152), Vector2(178, 18), &"lift_disembark")
			return true
		&"skybridge_carriage":
			_add_platform(Vector2(-315, -48), Vector2(186, 18), &"carriage_embark")
			_add_platform(Vector2(0, -94), Vector2(132, 18), &"carriage_transfer")
			_add_platform(Vector2(315, -48), Vector2(186, 18), &"carriage_disembark")
			return true
		&"spire_ascent":
			# A climbing rhythm deliberately alternates sides of the antenna mast.
			_add_platform(Vector2(-120, -55), Vector2(150, 18), &"mast_landing")
			_add_platform(Vector2(0, -103), Vector2(130, 18), &"mast_landing")
			_add_platform(Vector2(120, -151), Vector2(130, 18), &"mast_landing")
			_add_platform(Vector2(0, -199), Vector2(130, 18), &"mast_landing")
			_add_platform(Vector2(-120, -247), Vector2(130, 18), &"mast_landing")
			_add_platform(Vector2(0, -295), Vector2(130, 18), &"mast_landing")
			_add_platform(Vector2(120, -343), Vector2(130, 18), &"mast_landing")
			_add_platform(Vector2(0, maxf(-391.0, -height + 24.0)), Vector2(178, 18), &"mast_crown")
			return true
		&"intake_conveyors":
			_add_platform(Vector2(-225, -68), Vector2(184, 18), &"intake_belt")
			_add_platform(Vector2(-65, -116), Vector2(146, 18), &"sorter_belt")
			_add_platform(Vector2(100, -68), Vector2(176, 18), &"outfeed_belt")
			return true
		&"reversal_conveyors":
			# Alternating elevations produce visible direction changes instead of a
			# copy of the intake route.
			_add_platform(Vector2(-272, -64), Vector2(156, 18), &"reversal_entry")
			_add_platform(Vector2(-112, -112), Vector2(138, 18), &"reversal_lane")
			_add_platform(Vector2(48, -64), Vector2(148, 18), &"reversal_lane")
			_add_platform(Vector2(220, -112), Vector2(130, 18), &"reversal_exit")
			return true
		&"cargo_transfer":
			_add_platform(Vector2(-270, -46), Vector2(172, 18), &"cargo_loading_dock")
			_add_platform(Vector2(-110, -94), Vector2(140, 18), &"cargo_lift_dock")
			_add_platform(Vector2(50, -142), Vector2(140, 18), &"cargo_lift_dock")
			_add_platform(Vector2(210, -94), Vector2(172, 18), &"cargo_unloading_dock")
			return true
		&"furnace_gantry":
			_add_platform(Vector2(-115, -52), Vector2(146, 18), &"furnace_landing")
			_add_platform(Vector2(0, -100), Vector2(132, 18), &"furnace_landing")
			_add_platform(Vector2(115, -148), Vector2(132, 18), &"furnace_landing")
			_add_platform(Vector2(0, -196), Vector2(132, 18), &"furnace_landing")
			_add_platform(Vector2(-115, -244), Vector2(132, 18), &"furnace_landing")
			_add_platform(Vector2(0, -292), Vector2(132, 18), &"furnace_landing")
			_add_platform(Vector2(115, -340), Vector2(132, 18), &"furnace_landing")
			_add_platform(Vector2(0, maxf(-388.0, -height + 18.0)), Vector2(178, 18), &"furnace_crown")
			return true
		&"forge_laser_walk":
			_add_platform(Vector2(-228, -42), Vector2(124, 18), &"laser_entry")
			_add_platform(Vector2(-84, -88), Vector2(108, 18), &"laser_safe_island")
			_add_platform(Vector2(71, -42), Vector2(106, 18), &"laser_safe_island")
			_add_platform(Vector2(216, -88), Vector2(124, 18), &"laser_exit")
			return true
		&"crusher_bay":
			_add_platform(Vector2(-224, -42), Vector2(144, 18), &"crusher_entry")
			_add_platform(Vector2(-84, -90), Vector2(104, 18), &"crusher_safe_island")
			_add_platform(Vector2(64, -42), Vector2(104, 18), &"crusher_safe_island")
			_add_platform(Vector2(212, -90), Vector2(138, 18), &"crusher_exit")
			return true
		&"maintenance_bypass":
			_add_platform(Vector2(-266, -82), Vector2(150, 18), &"maintenance_access")
			_add_platform(Vector2(-116, -130), Vector2(126, 18), &"maintenance_perch")
			_add_platform(Vector2(34, -82), Vector2(128, 18), &"maintenance_perch")
			_add_platform(Vector2(184, -130), Vector2(156, 18), &"maintenance_exit")
			return true
	return false


func _add_optional_route_marker() -> void:
	if optional_route:
		var label := Label.new()
		label.name = "OptionalRouteMarker"
		label.text = "OPTIONAL ACCESS"
		label.position = Vector2(-58, -250)
		label.add_theme_color_override("font_color", Color("f6b445"))
		label.add_theme_color_override("font_shadow_color", Color("10141c"))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(label)


func _add_platform(local_position: Vector2, size: Vector2, role: StringName) -> void:
	var platform := StaticBody2D.new()
	platform.name = "TraversalDeck"
	platform.position = local_position
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	platform.add_child(collision)
	var deck_art := TraversalDeckPresentation.new()
	deck_art.name = "DeckArt"
	deck_art.configure(size, environment_id, architecture_id, section_kind, role)
	platform.add_child(deck_art)
	platform.set_meta(&"traversal_size", size)
	platform.set_meta(&"traversal_kind", section_kind)
	platform.set_meta(&"architecture_role", String(role))
	add_child(platform)
	_platforms.append(platform)
