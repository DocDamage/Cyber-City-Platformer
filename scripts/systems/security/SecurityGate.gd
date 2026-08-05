class_name SecurityGate
extends StaticBody2D

signal opened

@export var gate_size := Vector2(34.0, 180.0)
var is_open := false
var _collision: CollisionShape2D
var _visual: Polygon2D


func _ready() -> void:
	add_to_group(&"security_gates")
	_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = gate_size
	_collision.shape = shape
	add_child(_collision)
	var half := gate_size * 0.5
	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	_visual.color = Color(1.0, 0.1, 0.42, 0.72)
	add_child(_visual)


func open_gate() -> void:
	if is_open:
		return
	is_open = true
	_collision.set_deferred("disabled", true)
	create_tween().set_parallel(true).tween_property(_visual, "modulate:a", 0.1, 0.3)
	opened.emit()
