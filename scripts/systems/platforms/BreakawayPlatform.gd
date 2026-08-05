class_name BreakawayPlatform
extends StaticBody2D

@export var platform_size := Vector2(96.0, 18.0)
@export_range(0.1, 3.0, 0.1) var collapse_delay := 0.6
@export_range(0.5, 8.0, 0.1) var reset_delay := 2.5

var _collapsing := false
var _generation := 0
var _collision: CollisionShape2D
var _visual: Polygon2D


func _ready() -> void:
	add_to_group(&"breakaway_platforms")
	_build_components()


func _on_body_entered(body: Node) -> void:
	if not _collapsing and body.is_in_group(&"player"):
		_collapse_cycle()


func _collapse_cycle() -> void:
	_collapsing = true
	_generation += 1
	var generation := _generation
	_visual.color = Color("ff405f")
	await get_tree().create_timer(collapse_delay).timeout
	if generation != _generation:
		return
	_collision.set_deferred("disabled", true)
	_visual.visible = false
	await get_tree().create_timer(reset_delay).timeout
	if generation != _generation:
		return
	_collision.set_deferred("disabled", false)
	_visual.visible = true
	_visual.color = Color("ffc857")
	_collapsing = false


func reset_platform() -> void:
	_generation += 1
	_collapsing = false
	if _collision != null:
		_collision.set_deferred("disabled", false)
	if _visual != null:
		_visual.visible = true
		_visual.color = Color("ffc857")


func _build_components() -> void:
	_collision = CollisionShape2D.new()
	_collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = platform_size
	_collision.shape = shape
	add_child(_collision)
	var half := platform_size * 0.5
	_visual = Polygon2D.new()
	_visual.name = "Visual"
	_visual.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	_visual.color = Color("ffc857")
	add_child(_visual)
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	var sensor_shape := CollisionShape2D.new()
	var sensor_rectangle := RectangleShape2D.new()
	sensor_rectangle.size = platform_size + Vector2(0.0, 10.0)
	sensor_shape.shape = sensor_rectangle
	sensor.add_child(sensor_shape)
	add_child(sensor)
	sensor.body_entered.connect(_on_body_entered)
