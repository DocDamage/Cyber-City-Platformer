class_name SecurityTurret
extends Node2D

enum FireMode { TRACKING, BURST, ROTATING_LASER }

const PROJECTILE_SCENE := preload("res://scenes/systems/security/EnemyProjectile.tscn")

@export var security_id: StringName = &"turret"
@export var fire_mode := FireMode.TRACKING
@export_range(80.0, 800.0, 10.0) var detection_radius := 380.0
@export_range(0.2, 5.0, 0.1) var fire_interval := 1.35
@export_range(2, 8, 1) var burst_count := 3
@export_range(0.05, 0.8, 0.05) var burst_gap := 0.16
@export_range(0.1, 5.0, 0.05) var rotation_speed := 0.75
@export var destructible := true
@export_range(1, 20, 1) var max_health := 4
@export var starts_enabled := true
@export_enum("encounter", "checkpoint", "save") var persistence := "checkpoint"

var _target: Node2D
var _cooldown := 0.0
var _burst_remaining := 0
var _burst_gap_remaining := 0.0
var _enabled := true
var _health := 0
var _telegraph: Line2D


func _ready() -> void:
	add_to_group(&"turrets")
	_enabled = starts_enabled and not _get_persisted_disabled()
	_health = max_health
	_build_visual()
	if destructible:
		_build_hurtbox()
	_apply_enabled_visual()


func _physics_process(delta: float) -> void:
	if not _enabled:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	_burst_gap_remaining = maxf(_burst_gap_remaining - delta, 0.0)
	if fire_mode == FireMode.ROTATING_LASER:
		rotation += rotation_speed * delta
		_set_telegraph(Vector2(detection_radius, 0.0), true)
		if is_zero_approx(_cooldown):
			_fire_direction(Vector2.RIGHT.rotated(rotation))
			_cooldown = fire_interval
		return
	if not is_instance_valid(_target) or global_position.distance_to(_target.global_position) > detection_radius:
		_set_telegraph(Vector2(detection_radius, 0.0), false)
		return
	var aim := _target.global_position - global_position
	rotation = aim.angle()
	var has_sight := _has_line_of_sight(_target)
	_set_telegraph(Vector2(minf(aim.length(), detection_radius), 0.0), has_sight)
	if not has_sight:
		return
	if fire_mode == FireMode.BURST:
		_update_burst()
	elif is_zero_approx(_cooldown):
		_fire_direction(aim.normalized())
		_cooldown = fire_interval


func set_target(target: Node2D) -> void:
	_target = target


func set_enabled(value: bool) -> void:
	_enabled = value
	_burst_remaining = 0
	_apply_enabled_visual()
	if not value:
		_persist_disabled()


func is_enabled() -> bool:
	return _enabled


func take_damage(amount: int) -> bool:
	if not destructible or not _enabled or amount <= 0:
		return false
	_health = maxi(_health - amount, 0)
	if _health == 0:
		set_enabled(false)
	return true


func reset_security() -> void:
	_health = max_health
	_cooldown = 0.0
	_burst_remaining = 0
	set_enabled(starts_enabled and not _get_persisted_disabled())


func _update_burst() -> void:
	if _burst_remaining == 0 and is_zero_approx(_cooldown):
		_burst_remaining = burst_count
	if _burst_remaining <= 0 or _burst_gap_remaining > 0.0:
		return
	_fire_direction((_target.global_position - global_position).normalized())
	_burst_remaining -= 1
	_burst_gap_remaining = burst_gap
	if _burst_remaining == 0:
		_cooldown = fire_interval


func _has_line_of_sight(target: Node2D) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 3)
	query.collide_with_areas = false
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == target


func _fire_direction(direction: Vector2) -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as EnemyProjectile
	var parent := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	parent.add_child(projectile)
	projectile.global_position = global_position + direction * 30.0
	projectile.launch(direction)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call(&"play_sfx", &"laser_shot", global_position, -6.0)


func _build_visual() -> void:
	var base := Polygon2D.new()
	base.name = "TurretBody"
	base.polygon = PackedVector2Array([Vector2(-20, -14), Vector2(20, -14), Vector2(24, 14), Vector2(-24, 14)])
	base.color = Color("7548ff")
	add_child(base)
	var barrel := Polygon2D.new()
	barrel.polygon = PackedVector2Array([Vector2(0, -4), Vector2(30, -4), Vector2(30, 4), Vector2(0, 4)])
	barrel.color = Color("ff4fa3")
	add_child(barrel)
	_telegraph = Line2D.new()
	_telegraph.name = "AimTelegraph"
	_telegraph.width = 2.0
	_telegraph.default_color = Color(1.0, 0.2, 0.5, 0.34)
	_telegraph.points = PackedVector2Array([Vector2.ZERO, Vector2(detection_radius, 0.0)])
	add_child(_telegraph)


func _build_hurtbox() -> void:
	var hurtbox := Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 4
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(54, 42)
	collision.shape = shape
	hurtbox.add_child(collision)
	add_child(hurtbox)


func _set_telegraph(endpoint: Vector2, clear: bool) -> void:
	if _telegraph == null:
		return
	_telegraph.points = PackedVector2Array([Vector2.ZERO, endpoint])
	_telegraph.default_color = Color(0.15, 1.0, 0.8, 0.5) if clear else Color(1.0, 0.2, 0.5, 0.2)


func _apply_enabled_visual() -> void:
	modulate = Color.WHITE if _enabled else Color(0.3, 0.32, 0.4, 0.55)
	set_physics_process(_enabled)


func _persist_disabled() -> void:
	if persistence not in ["checkpoint", "save"]:
		return
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.call(&"set_stage_flag", _stage_scene_path(), security_id, true, persistence == "save")


func _get_persisted_disabled() -> bool:
	if persistence not in ["checkpoint", "save"]:
		return false
	var manager := get_node_or_null("/root/GameManager")
	return bool(manager.call(&"get_stage_flag", _stage_scene_path(), security_id, false)) if manager != null else false


func _stage_scene_path() -> String:
	var node: Node = self
	while node.get_parent() != null and node.get_parent() != get_tree().root:
		node = node.get_parent()
	return node.scene_file_path
