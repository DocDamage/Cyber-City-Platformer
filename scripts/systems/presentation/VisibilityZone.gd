class_name VisibilityZone
extends Area2D

@export var zone_size := Vector2(900.0, 500.0)
@export_range(0.15, 1.0, 0.05) var visibility_multiplier := 0.42

var _overlay: ColorRect


func _ready() -> void:
	add_to_group(&"visibility_zones")
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
	if not body.is_in_group(&"player") or _overlay != null:
		return
	_overlay = ColorRect.new()
	_overlay.name = "LimitedVisibilityOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color(0.015, 0.0, 0.045, 1.0 - visibility_multiplier)
	var layer := CanvasLayer.new()
	layer.layer = 18
	layer.add_child(_overlay)
	get_tree().root.add_child(layer)
	_overlay.set_meta(&"owner_layer", layer)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group(&"player"):
		_clear_overlay()


func _exit_tree() -> void:
	_clear_overlay()


func _clear_overlay() -> void:
	if _overlay == null:
		return
	var layer := _overlay.get_meta(&"owner_layer") as CanvasLayer
	if is_instance_valid(layer):
		layer.queue_free()
	_overlay = null
