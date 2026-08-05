class_name BossArenaController
extends Node2D

var arena_bounds := Rect2()
var _barriers: Array[StaticBody2D] = []
var _camera: DynamicCamera
var _normal_camera_bounds := Rect2()
var _normal_vertical_offset := -80.0


func configure(bounds: Rect2, boss: BossBase, camera: DynamicCamera = null) -> void:
	arena_bounds = bounds
	_camera = camera
	if _camera != null:
		_normal_camera_bounds = _camera.get_configured_bounds()
		_normal_vertical_offset = _camera.vertical_offset
	name = "BossArena"
	position = Vector2.ZERO
	_build_barriers()
	_set_barriers_active(false)
	if boss != null:
		boss.encounter_started.connect(_on_encounter_started)
		boss.encounter_reset.connect(_on_encounter_reset)
		boss.boss_defeated.connect(_on_boss_defeated)


func _ready() -> void:
	add_to_group(&"boss_arenas")


func _on_encounter_started() -> void:
	_set_barriers_active(true)
	if _camera != null:
		_camera.configure_bounds(arena_bounds, arena_bounds.get_center().y - 270.0)


func _on_encounter_reset() -> void:
	_set_barriers_active(false)
	_restore_camera()


func _on_boss_defeated() -> void:
	_set_barriers_active(false)
	_restore_camera()


func _restore_camera() -> void:
	if _camera != null:
		_camera.configure_bounds(_normal_camera_bounds, _normal_vertical_offset)


func _build_barriers() -> void:
	for x_position: float in [arena_bounds.position.x, arena_bounds.end.x]:
		var barrier := StaticBody2D.new()
		barrier.position = Vector2(x_position, arena_bounds.get_center().y)
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(28.0, arena_bounds.size.y)
		collision.shape = shape
		barrier.add_child(collision)
		var line := Line2D.new()
		line.width = 7.0
		line.default_color = Color(0.95, 0.08, 0.5, 0.82)
		line.points = PackedVector2Array([Vector2(0, -arena_bounds.size.y * 0.5), Vector2(0, arena_bounds.size.y * 0.5)])
		barrier.add_child(line)
		add_child(barrier)
		_barriers.append(barrier)


func _set_barriers_active(value: bool) -> void:
	for barrier: StaticBody2D in _barriers:
		barrier.process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
		barrier.visible = value
