class_name WarpRoom
extends Area2D

signal activated(warp_node_id: String)

var warp_node_id := ""


func configure(data: Dictionary) -> void:
	warp_node_id = String(data.get("id", ""))
	var values: Array = data.get("position", [480, 450])
	position = Vector2(float(values[0]), float(values[1]))


func _ready() -> void:
	add_to_group(&"warp_rooms")
	add_to_group(&"teleport_destination_allowed")
	collision_layer = 0
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 52.0
	collision.shape = shape
	add_child(collision)
	var visual := _WarpVisual.new()
	add_child(visual)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	var manager := get_node_or_null("/root/GameManager")
	if manager != null and manager.call(&"activate_warp_node", warp_node_id):
		activated.emit(warp_node_id)


class _WarpVisual:
	extends Node2D
	var elapsed := 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()

	func _draw() -> void:
		for index: int in range(3):
			var radius := 20.0 + index * 12.0 + sin(elapsed * 2.0 + index) * 3.0
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0.48, 0.95, 1.0, 0.8 - index * 0.18), 3.0)
