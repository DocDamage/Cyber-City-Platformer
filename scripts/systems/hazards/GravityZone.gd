class_name GravityZone
extends Area2D

@export_range(-2.0, 3.0, 0.1) var gravity_multiplier := 0.38
@export var zone_size := Vector2(420.0, 360.0)

var _original_multipliers: Dictionary = {}


func _ready() -> void:
	add_to_group(&"gravity_zones")
	collision_layer = 0
	collision_mask = 6
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
	visual.name = "GravityField"
	add_child(visual)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.has_method(&"set_gravity_multiplier"):
		var current_value: Variant = body.get("gravity_multiplier")
		_original_multipliers[body] = float(current_value) if current_value != null else 1.0
		body.call(&"set_gravity_multiplier", gravity_multiplier)
		if body.has_signal(&"died") and not body.is_connected(&"died", _on_body_died.bind(body)):
			body.connect(&"died", _on_body_died.bind(body))


func _on_body_exited(body: Node) -> void:
	if body.has_method(&"set_gravity_multiplier"):
		body.call(&"set_gravity_multiplier", float(_original_multipliers.get(body, 1.0)))
	_original_multipliers.erase(body)


func reset_zone() -> void:
	for body_value: Variant in _original_multipliers.keys():
		var body := body_value as Node
		if is_instance_valid(body) and body.has_method(&"set_gravity_multiplier"):
			body.call(&"set_gravity_multiplier", float(_original_multipliers[body]))
	_original_multipliers.clear()


func _on_body_died(body: Node) -> void:
	if is_instance_valid(body) and body.has_method(&"set_gravity_multiplier"):
		body.call(&"set_gravity_multiplier", float(_original_multipliers.get(body, 1.0)))
	_original_multipliers.erase(body)


func _exit_tree() -> void:
	reset_zone()
