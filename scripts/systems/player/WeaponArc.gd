extends Node2D

var _duration := 0.13
var _elapsed := 0.0
var _reach := 42.0
var _height := 34.0
var _facing := 1.0
var _color := Color("8ff5ff")
var _weight := 1.0


func configure(profile: Dictionary, facing: float, color: Color) -> void:
	_facing = signf(facing) if not is_zero_approx(facing) else 1.0
	_color = color
	var hitbox := profile.get("hitbox", [42, 36]) as Array
	if hitbox.size() >= 2:
		_reach = maxf(float(hitbox[0]), 24.0)
		_height = maxf(float(hitbox[1]), 24.0)
	_weight = clampf(float(profile.get("arc_weight", 1.0)), 0.7, 2.2)
	_duration = clampf(float(profile.get("arc_duration", 0.13)), 0.08, 0.22)
	z_index = 12
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	modulate.a = 1.0 - progress
	scale = Vector2.ONE * lerpf(0.86, 1.12, progress)
	if progress >= 1.0:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var points := PackedVector2Array()
	var start_angle := -1.05
	var end_angle := 0.95
	for index: int in range(10):
		var angle := lerpf(start_angle, end_angle, float(index) / 9.0)
		points.append(Vector2(cos(angle) * _reach * _facing, sin(angle) * _height - 9.0))
	var glow := _color
	glow.a = 0.22
	draw_polyline(points, glow, 8.0 * _weight, false)
	var core := _color.lightened(0.48)
	core.a = 0.92
	draw_polyline(points, core, 2.0 * _weight, false)
