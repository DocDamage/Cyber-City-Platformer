class_name SaveRoom
extends Area2D

signal activated(save_room_id: String)

var save_room_id := ""
var _activated := false


func configure(data: Dictionary) -> void:
	save_room_id = String(data.get("id", ""))
	var values: Array = data.get("position", [480, 450])
	position = Vector2(float(values[0]), float(values[1]))


func _ready() -> void:
	add_to_group(&"save_rooms")
	collision_layer = 0
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(72.0, 96.0)
	collision.shape = shape
	add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(-25,-45),Vector2(25,-45),Vector2(32,35),Vector2(-32,35)])
	visual.color = Color("27e8ff")
	add_child(visual)
	var label := Label.new()
	label.text = "SAVE\nSYNC"
	label.position = Vector2(-24,-25)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.world_progress.last_safe_save_room_id = save_room_id
		manager.world_progress.discovered_save_rooms[save_room_id] = true
		manager.active_checkpoint_position = body.global_position
		manager.current_checkpoint_id = StringName(save_room_id)
		manager.set_player_health(manager.player_max_health)
		manager.set_player_energy(manager.player_max_energy)
	if body.has_method(&"restore_from_checkpoint"):
		body.call(&"restore_from_checkpoint")
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		save_manager.call_deferred(&"save_game")
	if not _activated:
		_activated = true
		activated.emit(save_room_id)
