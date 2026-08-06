class_name TeleportDestinationResolver
extends Node

@export var world_collision_mask := 1
@export var clearance_margin := 3.0
@export var maximum_search_distance := 22.0
@export var world_bounds := Rect2()

var _player: CharacterBody2D
var _shape: Shape2D
var _shape_offset := Vector2.ZERO
var last_debug_result: Dictionary = {}


func configure(player: CharacterBody2D) -> bool:
	_player = player
	var collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or collision.shape == null:
		_shape = null
		return false
	_shape = collision.shape.duplicate(true) as Shape2D
	_shape_offset = collision.position
	return true


func resolve(anchor_position: Vector2, surface_normal: Vector2) -> Dictionary:
	if _player == null or _shape == null or not is_instance_valid(_player):
		return _result(false, Vector2.ZERO, &"not_configured", anchor_position, surface_normal)
	var normal := surface_normal.normalized()
	if normal.is_zero_approx():
		normal = Vector2.UP
	var extent := _normal_extent(normal)
	var tangent := Vector2(-normal.y, normal.x)
	var normal_offsets: Array[float] = [extent + clearance_margin, extent + 7.0, extent + 12.0, extent + maximum_search_distance]
	var tangent_offsets: Array[float] = [0.0, 4.0, -4.0, 8.0, -8.0]
	for normal_distance: float in normal_offsets:
		for tangent_distance: float in tangent_offsets:
			var candidate := anchor_position + normal * normal_distance + tangent * tangent_distance - _shape_offset
			var reason := _candidate_rejection(candidate)
			if reason.is_empty():
				last_debug_result = _result(true, candidate, &"valid", anchor_position, normal)
				return last_debug_result
	last_debug_result = _result(false, Vector2.ZERO, &"no_clearance", anchor_position, normal)
	return last_debug_result


func validate_position(candidate: Vector2) -> Dictionary:
	var reason := _candidate_rejection(candidate)
	last_debug_result = _result(reason.is_empty(), candidate if reason.is_empty() else Vector2.ZERO, &"valid" if reason.is_empty() else reason, candidate, Vector2.UP)
	return last_debug_result


func _candidate_rejection(candidate: Vector2) -> StringName:
	if world_bounds.has_area() and not world_bounds.grow(-2.0).has_point(candidate):
		return &"out_of_bounds"
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _shape
	query.transform = Transform2D(0.0, candidate + _shape_offset)
	query.collision_mask = world_collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.margin = 1.0
	query.exclude = [_player.get_rid()]
	var collisions := _player.get_world_2d().direct_space_state.intersect_shape(query, 16)
	for collision: Dictionary in collisions:
		var collider := collision.get("collider") as Node
		if collider != null and (collider.is_in_group(&"teleport_anchor") or collider.is_in_group(&"teleport_destination_allowed")):
			continue
		return &"blocked"
	var point_query := PhysicsPointQueryParameters2D.new()
	point_query.position = candidate
	point_query.collision_mask = 0x7FFFFFFF
	point_query.collide_with_areas = true
	point_query.collide_with_bodies = false
	for collision: Dictionary in _player.get_world_2d().direct_space_state.intersect_point(point_query, 32):
		var collider := collision.get("collider") as Node
		if collider != null and (collider.is_in_group(&"teleport_forbidden") or collider.is_in_group(&"kill_volume") or collider.get_script() != null and collider.get_script().resource_path.ends_with("DeathZone.gd")):
			return &"forbidden_volume"
	return &""


func _normal_extent(normal: Vector2) -> float:
	if _shape is CapsuleShape2D:
		var capsule := _shape as CapsuleShape2D
		return capsule.height * 0.5 if absf(normal.y) >= absf(normal.x) else capsule.radius
	if _shape is RectangleShape2D:
		var rectangle := _shape as RectangleShape2D
		return absf(normal.x) * rectangle.size.x * 0.5 + absf(normal.y) * rectangle.size.y * 0.5
	if _shape is CircleShape2D:
		return (_shape as CircleShape2D).radius
	return 28.0


func _result(valid: bool, position: Vector2, reason: StringName, anchor: Vector2, normal: Vector2) -> Dictionary:
	return {"valid": valid, "position": position, "reason": reason, "anchor": anchor, "normal": normal}
