class_name TeleportMarker
extends CharacterBody2D

signal attached(position: Vector2, surface_normal: Vector2)
signal failed(reason: StringName)

@export var maximum_range := 420.0
@export var lifetime := 3.0

var launch_position := Vector2.ZERO
var surface_normal := Vector2.UP
var is_attached := false
var _age := 0.0


func launch(origin: Vector2, launch_velocity: Vector2, range_limit := maximum_range) -> void:
	global_position = origin
	launch_position = origin
	velocity = launch_velocity
	maximum_range = maxf(range_limit, 32.0)
	is_attached = false
	_age = 0.0
	rotation = velocity.angle()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if is_attached:
		return
	_age += delta
	if _age >= lifetime:
		failed.emit(&"timeout")
		queue_free()
		return
	var collision := move_and_collide(velocity * delta)
	rotation = velocity.angle()
	if collision != null:
		is_attached = true
		velocity = Vector2.ZERO
		surface_normal = collision.get_normal().normalized()
		global_position = collision.get_position() + surface_normal * 2.0
		attached.emit(global_position, surface_normal)
		queue_redraw()
		return
	if global_position.distance_to(launch_position) >= maximum_range:
		failed.emit(&"range")
		queue_free()


func _draw() -> void:
	var color := Color("7cf8ff") if is_attached else Color("ff66c4")
	draw_colored_polygon(PackedVector2Array([Vector2(11, 0), Vector2(-6, -4), Vector2(-3, 0), Vector2(-6, 4)]), color)
	draw_circle(Vector2(-5, 0), 2.0, Color.WHITE)
	if is_attached:
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, Color(0.49, 0.97, 1.0, 0.55), 2.0)
