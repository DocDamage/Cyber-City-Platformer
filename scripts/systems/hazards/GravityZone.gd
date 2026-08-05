class_name GravityZone
extends Area2D

@export_range(-2.0, 3.0, 0.1) var gravity_multiplier := 0.38
@export var zone_size := Vector2(420.0, 360.0)


func _ready() -> void:
	add_to_group(&"gravity_zones")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = zone_size
	collision.shape = shape
	add_child(collision)
	var visual := Polygon2D.new()
	var half := zone_size * 0.5
	visual.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	visual.color = Color(0.18, 0.55, 1.0, 0.09)
	add_child(visual)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.has_method(&"set_gravity_multiplier"):
		body.call(&"set_gravity_multiplier", gravity_multiplier)


func _on_body_exited(body: Node) -> void:
	if body.has_method(&"set_gravity_multiplier"):
		body.call(&"set_gravity_multiplier", 1.0)
