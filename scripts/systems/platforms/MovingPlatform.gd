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
@export var presentation_id: StringName

const PRESENTATION_ASSETS := {
	&"city_elevator": {"path": "res://assets/runtime/props/TraversalKits/Generated/cyber_elevator_cage_v1.png", "scale": 0.29, "surface_y": 250.0},
	&"spire_carriage": {"path": "res://assets/runtime/props/TraversalKits/Generated/cyber_elevator_cage_v1.png", "scale": 0.31, "surface_y": 250.0},
	&"skybridge_carriage": {"path": "res://assets/runtime/props/TraversalKits/Generated/cyber_skybridge_truss_v1.png", "scale": 0.32, "surface_y": 48.0},
	&"factory_cargo_lift": {"path": "res://assets/runtime/props/TraversalKits/Generated/factory_cargo_lift_v1.png", "scale": 0.42, "surface_y": 235.0},
}

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
		var visual := TerrainPlatform.create_surface_art(platform_size, TerrainPlatform.region_for_node(self), 0, TerrainPlatform.prefers_traversal_skin(self))
		if visual != null:
			visual.name = "Visual"
			visual.set_meta(&"mechanic_role", "moving_platform")
			add_child(visual)
	_ensure_architecture()


func _ensure_architecture() -> void:
	if presentation_id.is_empty() or get_node_or_null("MechanicArchitecture") != null:
		return
	var specification := PRESENTATION_ASSETS.get(presentation_id, {}) as Dictionary
	var path := String(specification.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"):
		push_error("Moving platform presentation is missing: %s" % presentation_id)
		return
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("Moving platform presentation failed to load: %s" % path)
		return
	var scale_factor := float(specification.get("scale", 0.3))
	var surface_y := float(specification.get("surface_y", 0.0))
	var surface_anchor := Vector2(0.0, -platform_size.y * 0.5)
	var sprite := Sprite2D.new()
	sprite.name = "MechanicArchitecture"
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = -1
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position = Vector2(surface_anchor.x - texture.get_width() * scale_factor * 0.5, surface_anchor.y - surface_y * scale_factor)
	sprite.set_meta(&"presentation_id", String(presentation_id))
	sprite.set_meta(&"surface_anchor", surface_anchor)
	add_child(sprite)
