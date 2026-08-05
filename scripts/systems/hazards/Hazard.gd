class_name Hazard
extends Area2D

signal active_changed(active: bool)

@export var hazard_id: StringName = &"hazard"
@export_range(0, 99, 1) var damage := 1
@export var instant_kill := false
@export var active_on_ready := true
@export_range(0.0, 10.0, 0.1) var active_duration := 1.4
@export_range(0.0, 10.0, 0.1) var inactive_duration := 1.1
@export var hazard_size := Vector2(80.0, 64.0)
@export var knockback := Vector2(180.0, -150.0)

var is_active := false
var _elapsed := 0.0
var _damage_cooldowns: Dictionary = {}
var _visual: Polygon2D


func _ready() -> void:
	add_to_group(&"hazards")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_build_components()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_active(active_on_ready)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	for body: Variant in _damage_cooldowns.keys():
		_damage_cooldowns[body] = maxf(float(_damage_cooldowns[body]) - delta, 0.0)
	if active_duration > 0.0 and inactive_duration > 0.0:
		var period := active_duration + inactive_duration
		set_active(fposmod(_elapsed, period) < active_duration)
	if is_active:
		for body: Node2D in get_overlapping_bodies():
			_damage_body(body)


func set_active(value: bool) -> void:
	if is_active == value:
		return
	is_active = value
	if _visual != null:
		_visual.color = Color(1.0, 0.12, 0.3, 0.86) if value else Color(0.25, 0.3, 0.42, 0.35)
	active_changed.emit(value)


func reset_hazard() -> void:
	_elapsed = 0.0
	_damage_cooldowns.clear()
	set_active(active_on_ready)


func _on_body_entered(body: Node2D) -> void:
	if is_active:
		_damage_body(body)


func _on_body_exited(body: Node2D) -> void:
	_damage_cooldowns.erase(body)


func _damage_body(body: Node2D) -> void:
	if not body.is_in_group(&"player") or float(_damage_cooldowns.get(body, 0.0)) > 0.0:
		return
	_damage_cooldowns[body] = 0.55
	if instant_kill and body.has_method(&"kill"):
		body.call(&"kill")
	elif body.has_method(&"take_damage"):
		body.call(&"take_damage", damage)
	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity += knockback


func _build_components() -> void:
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = hazard_size
	collision.shape = shape
	add_child(collision)
	var half := hazard_size * 0.5
	_visual = Polygon2D.new()
	_visual.name = "HazardVisual"
	_visual.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	_visual.color = Color(1.0, 0.12, 0.3, 0.86)
	add_child(_visual)
