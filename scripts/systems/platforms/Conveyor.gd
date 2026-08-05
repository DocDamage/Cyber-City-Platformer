class_name Conveyor
extends StaticBody2D

@export_range(-400.0, 400.0, 10.0) var speed := 115.0
@export var reversible := false
@export_range(0.5, 10.0, 0.1) var reverse_interval := 3.0
@export var conveyor_size := Vector2(180.0, 22.0)

var _elapsed := 0.0
var _direction := 1.0


func _ready() -> void:
	add_to_group(&"conveyors")
	_ensure_components()
	_apply_velocity()


func _physics_process(delta: float) -> void:
	if not reversible:
		return
	_elapsed += delta
	if _elapsed >= reverse_interval:
		_elapsed = 0.0
		_direction *= -1.0
		_apply_velocity()


func _apply_velocity() -> void:
	constant_linear_velocity = Vector2(speed * _direction, 0.0)
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		visual.color = Color("ff4fd8") if _direction > 0.0 else Color("7a5cff")


func _ensure_components() -> void:
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = conveyor_size
	collision.shape = shape
	add_child(collision)
	var half := conveyor_size * 0.5
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	visual.color = Color("ff4fd8")
	add_child(visual)
