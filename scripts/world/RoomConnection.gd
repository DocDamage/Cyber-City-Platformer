class_name RoomConnection
extends Area2D

var connection_id := ""
var target_room_id := ""
var target_connection_id := ""
var preserve_velocity := false
var required_ability: StringName = &""
var barrier_id := ""
var _triggered := false
var _barrier: StaticBody2D
var _barrier_visual: Node2D


func configure(data: Dictionary) -> void:
	connection_id = String(data.get("id", ""))
	target_room_id = String(data.get("target_room", ""))
	target_connection_id = String(data.get("target_connection", ""))
	required_ability = StringName(data.get("required_ability", ""))
	barrier_id = String(data.get("barrier_id", "%s_%s" % [target_room_id, connection_id]))
	var values: Array = data.get("rect", [0, 0, 16, 100])
	# Side exits form the continuous critical path. Carry locomotion through them
	# by default so crossing a room boundary does not feel like hitting a brake.
	preserve_velocity = bool(data.get("preserve_velocity", float(values[3]) > float(values[2])))
	position = Vector2(float(values[0]) + float(values[2]) * 0.5, float(values[1]) + float(values[3]) * 0.5)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(float(values[2]), float(values[3]))
	collision.shape = rectangle
	add_child(collision)
	if not required_ability.is_empty():
		_build_barrier(rectangle.size)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	body_entered.connect(_on_body_entered)
	var manager := get_node_or_null("/root/GameManager")
	if manager != null and not manager.ability_unlocked.is_connected(_on_ability_unlocked):
		manager.ability_unlocked.connect(_on_ability_unlocked)
	_refresh_barrier()


func is_locked() -> bool:
	if required_ability.is_empty():
		return false
	var manager := get_node_or_null("/root/GameManager")
	return manager == null or not manager.abilities.has(required_ability)


func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group(&"player"):
		return
	if is_locked():
		var manager := get_node_or_null("/root/GameManager")
		if manager != null:
			var room_id := String(manager.world_progress.current_room_id)
			manager.call(&"discover_locked_barrier", barrier_id, room_id, required_ability)
		return
	_triggered = true
	var world_manager := get_node_or_null("/root/WorldManager")
	if world_manager != null:
		world_manager.call(&"transition_to", target_room_id, target_connection_id, preserve_velocity)
	else:
		_triggered = false


func _build_barrier(size: Vector2) -> void:
	_barrier = StaticBody2D.new()
	_barrier.name = "AbilityBarrier"
	_barrier.add_to_group(&"ability_barriers")
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	_barrier.add_child(collision)
	var visual := Node2D.new()
	visual.name = "AbilityBarrierGrid"
	visual.z_index = 8
	var half := size * 0.5
	var outline_points := PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y),
		Vector2(-half.x, half.y), Vector2(-half.x, -half.y),
	])
	_add_barrier_line(visual, outline_points, 2.0, Color(0.35, 0.92, 1.0, 0.86))
	var vertical := size.y >= size.x
	for rail_index: int in range(1, 4):
		var ratio := float(rail_index) / 4.0
		var points := PackedVector2Array()
		if vertical:
			var y := lerpf(-half.y, half.y, ratio)
			points = PackedVector2Array([Vector2(-half.x, y), Vector2(half.x, y)])
		else:
			var x := lerpf(-half.x, half.x, ratio)
			points = PackedVector2Array([Vector2(x, -half.y), Vector2(x, half.y)])
		_add_barrier_line(visual, points, 1.5, Color(0.3, 0.82, 1.0, 0.62))
	_barrier.add_child(visual)
	_barrier_visual = visual
	var label := Label.new()
	label.text = "MAG-RAIL LOCK" if required_ability == &"magnetic_rail" else String(required_ability).replace("_", " ").to_upper()
	label.position = Vector2(-68.0, 12.0 if size.x > size.y else -half.y - 24.0)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("8ff5ff"))
	label.z_index = 9
	_barrier.add_child(label)
	add_child(_barrier)


func _add_barrier_line(parent: Node2D, points: PackedVector2Array, width: float, color: Color) -> void:
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	line.antialiased = false
	parent.add_child(line)


func _refresh_barrier() -> void:
	if _barrier == null:
		return
	var locked := is_locked()
	_barrier.collision_layer = 1 if locked else 0
	_barrier.collision_mask = 0
	_barrier.process_mode = Node.PROCESS_MODE_INHERIT if locked else Node.PROCESS_MODE_DISABLED
	_barrier.visible = locked


func _on_ability_unlocked(ability_id: StringName, _level: int) -> void:
	if ability_id == required_ability:
		_refresh_barrier()
