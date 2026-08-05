class_name SecurityTurret
extends Node2D

const PROJECTILE_SCENE := preload("res://scenes/systems/security/EnemyProjectile.tscn")

@export_range(80.0, 800.0, 10.0) var detection_radius := 380.0
@export_range(0.2, 5.0, 0.1) var fire_interval := 1.35

var _target: Node2D
var _cooldown := 0.0


func _ready() -> void:
	add_to_group(&"turrets")
	_build_visual()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group(&"player") as Node2D
	if _target == null or global_position.distance_to(_target.global_position) > detection_radius:
		return
	rotation = (_target.global_position - global_position).angle()
	if is_zero_approx(_cooldown):
		_fire()
		_cooldown = fire_interval


func _fire() -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as EnemyProjectile
	var parent := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	parent.add_child(projectile)
	projectile.global_position = global_position
	projectile.launch((_target.global_position - global_position).normalized())


func _build_visual() -> void:
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-20.0, -14.0), Vector2(20.0, -14.0),
		Vector2(24.0, 14.0), Vector2(-24.0, 14.0),
	])
	base.color = Color("7548ff")
	add_child(base)
	var barrel := Polygon2D.new()
	barrel.polygon = PackedVector2Array([
		Vector2(0.0, -4.0), Vector2(30.0, -4.0),
		Vector2(30.0, 4.0), Vector2(0.0, 4.0),
	])
	barrel.color = Color("ff4fa3")
	add_child(barrel)
