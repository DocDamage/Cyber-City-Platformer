class_name HazardPatternArt
extends Node2D

var hazard_size := Vector2(80.0, 64.0)
var style := "hazard"
var active := false
var telegraphing := false


func configure(size: Vector2, hazard_style: String) -> void:
	hazard_size = size
	style = hazard_style
	set_meta(&"hazard_style", style)
	set_meta(&"visual_rect", Rect2(-hazard_size * 0.5, hazard_size))
	queue_redraw()


func set_state(is_active: bool, is_telegraphing: bool) -> void:
	active = is_active
	telegraphing = is_telegraphing
	queue_redraw()


func _draw() -> void:
	var half := hazard_size * 0.5
	var rect := Rect2(-half, hazard_size)
	var signal_color := Color("ffd45a") if telegraphing else _style_color()
	var strength := 0.78 if active else (0.5 if telegraphing else 0.2)
	match style:
		"electrical_floor":
			draw_rect(Rect2(Vector2(-half.x, half.y - 10.0), Vector2(hazard_size.x, 10.0)), Color("142e45"), true)
			for index: int in range(maxi(floori(hazard_size.x / 24.0), 1)):
				var left := -half.x + float(index) * 24.0
				var bolt := PackedVector2Array([Vector2(left, half.y - 4.0), Vector2(left + 8.0, -half.y + 8.0), Vector2(left + 13.0, 2.0), Vector2(left + 22.0, -half.y + 3.0)])
				draw_polyline(bolt, Color(signal_color, strength), 2.0, false)
		"laser_grid":
			_draw_frame(rect, Color(signal_color, strength))
			for index: int in range(1, 5):
				var x := lerpf(-half.x, half.x, float(index) / 5.0)
				draw_line(Vector2(x, -half.y), Vector2(x, half.y), Color(signal_color, strength), 2.0, false)
		"steam_vent":
			draw_rect(Rect2(Vector2(-half.x, half.y - 14.0), Vector2(hazard_size.x, 14.0)), Color("334552"), true)
			for index: int in range(3):
				var x := lerpf(-half.x + 12.0, half.x - 12.0, float(index) / 2.0)
				var plume := PackedVector2Array([Vector2(x - 5.0, half.y - 14.0), Vector2(x + 4.0, 8.0), Vector2(x - 3.0, -half.y + 10.0)])
				draw_polyline(plume, Color(signal_color, strength), 3.0, false)
		"toxic_pool":
			draw_rect(Rect2(Vector2(-half.x, -half.y * 0.15), Vector2(hazard_size.x, half.y * 1.15)), Color(signal_color, strength * 0.55), true)
			for index: int in range(5):
				var x := lerpf(-half.x + 9.0, half.x - 9.0, float(index) / 4.0)
				draw_circle(Vector2(x, -half.y * (0.1 + float(index % 2) * 0.25)), 3.0 + float(index % 3), Color(signal_color, strength), false, 1.5, false)
		"void_pit":
			draw_rect(rect, Color(0.01, 0.0, 0.05, 0.9 if active else 0.55), true)
			draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color(signal_color, strength), 3.0, false)
		"corruption_zone":
			var root_color := Color(signal_color, strength * 0.7)
			draw_line(Vector2(-half.x, half.y - 2.0), Vector2(half.x, half.y - 2.0), root_color, 3.0, false)
			for index: int in range(7):
				var x := lerpf(-half.x + 10.0, half.x - 10.0, float(index) / 6.0)
				var rise := 18.0 + float(index % 3) * 12.0
				var sway := -7.0 if index % 2 == 0 else 7.0
				var tendril := PackedVector2Array([
					Vector2(x, half.y - 2.0),
					Vector2(x + sway, half.y - rise * 0.55),
					Vector2(x - sway * 0.4, half.y - rise),
				])
				draw_polyline(tendril, Color(signal_color, strength * 0.58), 2.0, false)
				var mote_position := tendril[tendril.size() - 1]
				draw_circle(mote_position, 3.0 + float(index % 2), Color(signal_color, strength * 0.48), false, 1.5, false)
		_:
			draw_rect(rect, Color(signal_color, strength * 0.18), true)
			_draw_frame(rect, Color(signal_color, strength))


func _style_color() -> Color:
	match style:
		"electrical_floor": return Color("48e8ff")
		"laser_grid": return Color("ff3cae")
		"steam_vent": return Color("d5f5ff")
		"toxic_pool": return Color("ad48e8")
		"void_pit": return Color("7d5cff")
		"corruption_zone": return Color("e932a2")
		_: return Color("ff405f")


func _draw_frame(rect: Rect2, color: Color) -> void:
	draw_polyline(PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
		rect.position,
	]), color, 2.0, false)
