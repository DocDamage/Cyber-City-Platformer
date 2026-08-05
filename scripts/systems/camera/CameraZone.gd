class_name CameraZone
extends Area2D

@export var zone_size := Vector2(900.0, 900.0)
@export_range(-300.0, 300.0, 5.0) var vertical_offset := -150.0

var _previous_offsets: Dictionary = {}


func _ready() -> void:
	add_to_group(&"camera_zones")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = zone_size
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(&"player"):
		return
	var camera := body.get_node_or_null("Camera2D") as DynamicCamera
	if camera == null:
		return
	_previous_offsets[camera] = camera.vertical_offset
	camera.configure_bounds(camera.get_configured_bounds(), vertical_offset)


func _on_body_exited(body: Node) -> void:
	var camera := body.get_node_or_null("Camera2D") as DynamicCamera
	if camera != null and _previous_offsets.has(camera):
		camera.configure_bounds(camera.get_configured_bounds(), float(_previous_offsets[camera]))
		_previous_offsets.erase(camera)
