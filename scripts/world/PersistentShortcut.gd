class_name PersistentShortcut
extends Node2D

signal opened(shortcut_id: String)

var shortcut_id := ""
var target_room_id := ""
var target_connection_id := ""
var approach := "right"
var _barrier: StaticBody2D
var _area: Area2D
var _size := Vector2(24.0, 90.0)
var _is_open := false


func configure(data: Dictionary) -> void:
	shortcut_id = String(data.get("id", ""))
	target_room_id = String(data.get("target_room", ""))
	target_connection_id = String(data.get("target_connection", ""))
	approach = String(data.get("approach", "right"))
	var position_values: Array = data.get("position", [0, 0])
	position = Vector2(float(position_values[0]), float(position_values[1]))
	var size_values: Array = data.get("size", [24, 90])
	_size = Vector2(float(size_values[0]), float(size_values[1]))


func _ready() -> void:
	_build()
	var manager := get_node_or_null("/root/GameManager")
	_is_open = manager != null and bool(manager.world_progress.get_object_state(shortcut_id, false))
	_apply_state()


func _build() -> void:
	_barrier = StaticBody2D.new()
	var barrier_collision := CollisionShape2D.new()
	var barrier_shape := RectangleShape2D.new()
	barrier_shape.size = _size
	barrier_collision.shape = barrier_shape
	_barrier.add_child(barrier_collision)
	var visual := Polygon2D.new()
	var half := _size * 0.5
	visual.polygon = PackedVector2Array([Vector2(-half.x,-half.y),Vector2(half.x,-half.y),Vector2(half.x,half.y),Vector2(-half.x,half.y)])
	visual.color = Color("ff4fa3")
	visual.name = "GateVisual"
	_barrier.add_child(visual)
	add_child(_barrier)
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	var area_collision := CollisionShape2D.new()
	var area_shape := RectangleShape2D.new()
	area_shape.size = _size + Vector2(70.0, 20.0)
	area_collision.shape = area_shape
	_area.add_child(area_collision)
	_area.body_entered.connect(_on_body_entered)
	add_child(_area)


func _on_body_entered(body: Node2D) -> void:
	if _is_open or not body.is_in_group(&"player"):
		return
	var relative_x := body.global_position.x - global_position.x
	if (approach == "right" and relative_x < 0.0) or (approach == "left" and relative_x > 0.0):
		return
	_open()


func _open() -> void:
	_is_open = true
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.world_progress.set_object_state(shortcut_id, true)
		var save_manager := get_node_or_null("/root/SaveManager")
		if save_manager != null:
			save_manager.call_deferred(&"save_game")
	_apply_state()
	opened.emit(shortcut_id)


func _apply_state() -> void:
	if _barrier != null:
		_barrier.process_mode = Node.PROCESS_MODE_DISABLED if _is_open else Node.PROCESS_MODE_INHERIT
		_barrier.collision_layer = 0 if _is_open else 1
		_barrier.visible = not _is_open
