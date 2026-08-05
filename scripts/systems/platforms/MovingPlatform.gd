class_name MovingPlatform
extends AnimatableBody2D

@export var motion_offset := Vector2(220.0, 0.0)
@export_range(0.5, 12.0, 0.1) var travel_time := 2.8
@export_range(0.0, 4.0, 0.1) var phase_offset := 0.0
@export var platform_size := Vector2(112.0, 18.0)

var _origin := Vector2.ZERO
var _elapsed := 0.0


func _ready() -> void:
	add_to_group(&"moving_platforms")
	_origin = position
	_elapsed = phase_offset
	_ensure_components()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var cycle := fposmod(_elapsed, travel_time * 2.0) / travel_time
	var weight := cycle if cycle <= 1.0 else 2.0 - cycle
	weight = smoothstep(0.0, 1.0, weight)
	position = _origin + motion_offset * weight


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
