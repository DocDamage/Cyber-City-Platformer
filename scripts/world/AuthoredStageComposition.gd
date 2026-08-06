extends Node2D

var _bounds := Rect2()
var _platforms: Array = []
var _connections: Array = []
var _profile: Dictionary = {}
var _room_id := ""
var _spatial_rhythm := ""


func configure(bounds: Rect2, definition: Dictionary, art_profile: Dictionary) -> void:
	_bounds = bounds
	_platforms = (definition.get("platforms", []) as Array).duplicate(true)
	_connections = (definition.get("connections", []) as Array).duplicate(true)
	_profile = art_profile.duplicate(true)
	_room_id = String(definition.get("id", ""))
	_spatial_rhythm = String(definition.get("spatial_rhythm", ""))
	set_meta(&"composition_source", "native_stage_mass_v2")
	set_meta(&"room_id", _room_id)
	set_meta(&"spatial_rhythm", _spatial_rhythm)
	queue_redraw()


func _draw() -> void:
	if not _bounds.has_area():
		return
	var architecture := DistrictArtCatalog.profile_color(_profile, "architecture_color", Color("17324b"))
	var foreground := DistrictArtCatalog.profile_color(_profile, "foreground_color", Color("0b2439"))
	var trim := DistrictArtCatalog.profile_color(_profile, "trim_color", Color("32d9f5"))
	var accent := DistrictArtCatalog.profile_color(_profile, "accent_color", Color("ff72c6"))
	_draw_backdrop_masses(architecture, foreground, trim)
	_draw_platform_supports(architecture, foreground, trim)
	_draw_connection_frames(foreground, trim, accent)


func _draw_backdrop_masses(architecture: Color, foreground: Color, trim: Color) -> void:
	var heights := _profile.get("backdrop_heights", []) as Array
	if heights.is_empty():
		return
	var module_width := _bounds.size.x / float(heights.size())
	var baseline := _bounds.end.y - 36.0
	for index: int in range(heights.size()):
		var normalized_height := clampf(float(heights[index]), 0.18, 0.9)
		var width := module_width + (14.0 if index % 2 == 0 else -8.0)
		var height := _bounds.size.y * normalized_height
		var rect := Rect2(_bounds.position.x + float(index) * module_width - 4.0, baseline - height, width, height)
		var body_color := architecture.darkened(0.18)
		body_color.a = 0.46
		draw_rect(rect, body_color)
		var cap_color := foreground
		cap_color.a = 0.72
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5.0)), cap_color)
		var window_color := trim
		window_color.a = 0.18
		for window_y: float in range(int(rect.position.y + 22.0), int(rect.end.y - 18.0), 34):
			var inset := 13.0 + float((index * 7 + int(window_y)) % 11)
			draw_rect(Rect2(Vector2(rect.position.x + inset, window_y), Vector2(maxf(rect.size.x - inset * 2.0, 8.0), 2.0)), window_color)
	_draw_landmark_shadow(architecture)


func _draw_landmark_shadow(architecture: Color) -> void:
	var values := _profile.get("landmark_points", []) as Array
	if values.size() < 3:
		return
	var points := PackedVector2Array()
	for value: Variant in values:
		if value is Array and (value as Array).size() >= 2:
			points.append(_bounds.get_center() + Vector2(float((value as Array)[0]), float((value as Array)[1]) + 42.0))
	if points.size() >= 3:
		var color := architecture.lightened(0.05)
		color.a = 0.32
		draw_colored_polygon(points, color)


func _draw_platform_supports(architecture: Color, foreground: Color, trim: Color) -> void:
	var rects: Array[Rect2] = []
	for value: Variant in _platforms:
		var rect := _rect(value)
		if rect.has_area():
			rects.append(rect)
	for index: int in range(rects.size()):
		var platform := rects[index]
		if platform.size.y >= 96.0 or platform.position.y >= _bounds.end.y - 48.0:
			continue
		var support_bottom := _support_bottom(platform, rects)
		var support_height := support_bottom - platform.end.y
		if support_height < 12.0:
			continue
		var column_width := clampf(platform.size.x * 0.42, 22.0, 76.0)
		var column := Rect2(Vector2(platform.get_center().x - column_width * 0.5, platform.end.y), Vector2(column_width, support_height))
		var shadow := foreground
		shadow.a = 0.88
		draw_rect(column, shadow)
		var inset := architecture.lightened(0.05)
		inset.a = 0.58
		draw_rect(column.grow(-5.0), inset)
		var edge := trim
		edge.a = 0.28
		draw_line(column.position + Vector2(4.0, 0.0), Vector2(column.position.x + 4.0, column.end.y), edge, 2.0)
		draw_line(Vector2(column.end.x - 4.0, column.position.y), column.end - Vector2(4.0, 0.0), edge, 2.0)
		if platform.size.x >= 132.0:
			var brace_color := architecture.lightened(0.12)
			brace_color.a = 0.5
			var brace_drop := minf(support_height, 54.0)
			draw_line(Vector2(platform.position.x + 8.0, platform.end.y), Vector2(column.position.x, platform.end.y + brace_drop), brace_color, 5.0)
			draw_line(Vector2(platform.end.x - 8.0, platform.end.y), Vector2(column.end.x, platform.end.y + brace_drop), brace_color, 5.0)


func _draw_connection_frames(foreground: Color, trim: Color, accent: Color) -> void:
	for value: Variant in _connections:
		if value is not Dictionary:
			continue
		var rect := _rect((value as Dictionary).get("rect", []))
		if not rect.has_area():
			continue
		var frame := rect.grow(9.0)
		var frame_color := foreground.darkened(0.18)
		frame_color.a = 0.96
		draw_rect(frame, frame_color, false, 7.0)
		var light := accent if not String((value as Dictionary).get("required_ability", "")).is_empty() else trim
		light.a = 0.72
		if rect.size.y >= rect.size.x:
			draw_line(Vector2(frame.position.x, frame.position.y), Vector2(frame.position.x, frame.end.y), light, 2.0)
			draw_line(Vector2(frame.end.x, frame.position.y), Vector2(frame.end.x, frame.end.y), light, 2.0)
		else:
			draw_line(Vector2(frame.position.x, frame.position.y), Vector2(frame.end.x, frame.position.y), light, 2.0)
			draw_line(Vector2(frame.position.x, frame.end.y), Vector2(frame.end.x, frame.end.y), light, 2.0)


func _support_bottom(platform: Rect2, rects: Array[Rect2]) -> float:
	var bottom := _bounds.end.y
	for candidate: Rect2 in rects:
		if candidate.position.y < platform.end.y - 0.1:
			continue
		var center_x := platform.get_center().x
		if center_x >= candidate.position.x and center_x <= candidate.end.x:
			bottom = minf(bottom, candidate.position.y)
	return bottom


func _rect(value: Variant) -> Rect2:
	if value is not Array or (value as Array).size() != 4:
		return Rect2()
	var values := value as Array
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))
