class_name BossArenaController
extends Node2D

const LOCKDOWN_GATE_ART := preload("res://scripts/systems/security/LockdownGateArt.gd")

var arena_bounds := Rect2()
var _barriers: Array[StaticBody2D] = []
var _camera: DynamicCamera
var _normal_camera_bounds := Rect2()
var _normal_vertical_offset := -80.0
var _locked := false
var _act_number := 1


func configure(bounds: Rect2, boss: BossBase, camera: DynamicCamera = null, act_number := 1) -> void:
	arena_bounds = bounds
	_camera = camera
	_act_number = clampi(act_number, 1, 4)
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


func is_locked() -> bool:
	return _locked


func _build_barriers() -> void:
	for x_position: float in [arena_bounds.position.x, arena_bounds.end.x]:
		var barrier := StaticBody2D.new()
		barrier.position = Vector2(x_position, arena_bounds.get_center().y)
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(28.0, arena_bounds.size.y)
		collision.shape = shape
		barrier.add_child(collision)
		var presentation := LOCKDOWN_GATE_ART.new()
		presentation.configure(Vector2(28.0, arena_bounds.size.y), _act_number, &"boss")
		barrier.add_child(presentation)
		barrier.set_meta(&"presentation", "framed_lockdown_gate")
		add_child(barrier)
		_barriers.append(barrier)


func _set_barriers_active(value: bool) -> void:
	_locked = value
	for barrier: StaticBody2D in _barriers:
		barrier.process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
		barrier.visible = value
