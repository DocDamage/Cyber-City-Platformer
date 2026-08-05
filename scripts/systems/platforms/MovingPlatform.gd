class_name MovingPlatform
extends AnimatableBody2D

enum PathMode { PING_PONG, LOOP }

@export var motion_offset := Vector2(220.0, 0.0)
@export_range(0.5, 12.0, 0.1) var travel_time := 2.8
@export_range(0.0, 4.0, 0.1) var phase_offset := 0.0
@export var path_points := PackedVector2Array()
@export var path_mode := PathMode.PING_PONG
@export_range(10.0, 600.0, 5.0) var speed := 110.0
@export_range(0.0, 4.0, 0.05) var wait_time := 0.25
@export var starts_active := true
@export var platform_size := Vector2(112.0, 18.0)

var _origin := Vector2.ZERO
var _route := PackedVector2Array()
var _route_index := 0
var _route_direction := 1
var _wait_remaining := 0.0
var _active := true


func _ready() -> void:
	add_to_group(&"moving_platforms")
	_origin = position
	sync_to_physics = true
	_active = starts_active
	_route = path_points.duplicate()
	if _route.size() < 2:
		_route = PackedVector2Array([Vector2.ZERO, motion_offset])
	if not _route[0].is_zero_approx():
		_route.insert(0, Vector2.ZERO)
	_apply_phase_offset()
	_ensure_components()


func _physics_process(delta: float) -> void:
	if not _active or _route.size() < 2:
		return
	if _wait_remaining > 0.0:
		_wait_remaining = maxf(_wait_remaining - delta, 0.0)
		return
	var target := _origin + _route[_next_route_index()]
	var configured_speed := speed
	if path_points.is_empty():
		configured_speed = maxf(motion_offset.length() / maxf(travel_time, 0.01), 1.0)
	position = position.move_toward(target, configured_speed * delta)
	if position.is_equal_approx(target):
		_route_index = _next_route_index()
		_advance_direction()
		_wait_remaining = wait_time


func set_active(value: bool) -> void:
	_active = value


func activate() -> void:
	set_active(true)


func reset_platform() -> void:
	position = _origin
	_route_index = 0
	_route_direction = 1
	_wait_remaining = 0.0
	_active = starts_active
	_apply_phase_offset()


func get_route_points() -> PackedVector2Array:
	return _route.duplicate()


func _next_route_index() -> int:
	if path_mode == PathMode.LOOP:
		return wrapi(_route_index + 1, 0, _route.size())
	return clampi(_route_index + _route_direction, 0, _route.size() - 1)


func _advance_direction() -> void:
	if path_mode != PathMode.PING_PONG:
		return
	if _route_index == _route.size() - 1:
		_route_direction = -1
	elif _route_index == 0:
		_route_direction = 1


func _apply_phase_offset() -> void:
	if _route.size() < 2 or phase_offset <= 0.0:
		return
	var first_length := _route[0].distance_to(_route[1])
	if first_length <= 0.0:
		return
	position = _origin + _route[0].lerp(_route[1], fposmod(phase_offset * speed, first_length) / first_length)


func _ensure_components() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = platform_size
		collision.shape = shape
		add_child(collision)
	if get_node_or_null("Visual") == null:
		var visual := Polygon2D.new()
		visual.name = "Visual"
		var half := platform_size * 0.5
		visual.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
		visual.color = Color("24d8ff")
		add_child(visual)
