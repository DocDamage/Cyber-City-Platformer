class_name Hazard
extends Area2D

signal active_changed(active: bool)
signal telegraph_started

@export var hazard_id: StringName = &"hazard"
@export_range(0, 99, 1) var damage := 1
@export var instant_kill := false
@export var active_on_ready := true
@export var starts_enabled := true
@export_range(0.0, 10.0, 0.1) var active_duration := 1.4
@export_range(0.0, 10.0, 0.1) var inactive_duration := 1.1
@export_range(0.0, 3.0, 0.05) var telegraph_duration := 0.35
@export_range(0.0, 10.0, 0.05) var phase_offset := 0.0
@export var hazard_size := Vector2(80.0, 64.0)
@export var knockback := Vector2(180.0, -150.0)
@export var affects_enemies := false

var is_active := false
var is_telegraphing := false
var _elapsed := 0.0
var _enabled := true
var _damage_cooldowns: Dictionary = {}
var _visual: Polygon2D
var _warning: Label


func _ready() -> void:
	add_to_group(&"hazards")
	collision_layer = 0
	collision_mask = 6 if affects_enemies else 2
	monitorable = false
	_enabled = starts_enabled
	_elapsed = phase_offset
	_build_components()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_active(active_on_ready)


func _physics_process(delta: float) -> void:
	if not _enabled:
		return
	_elapsed += delta
	for body: Variant in _damage_cooldowns.keys():
		_damage_cooldowns[body] = maxf(float(_damage_cooldowns[body]) - delta, 0.0)
	if active_duration > 0.0 and inactive_duration > 0.0:
		var period := active_duration + inactive_duration
		var cycle_time := fposmod(_elapsed, period)
		var next_active := cycle_time < active_duration
		var next_telegraph := not next_active and cycle_time >= period - minf(telegraph_duration, inactive_duration)
		set_telegraphing(next_telegraph)
		set_active(next_active)
	if is_active:
		for body: Node2D in get_overlapping_bodies():
			_damage_body(body)


func set_active(value: bool) -> void:
	value = value and _enabled
	if is_active == value:
		return
	is_active = value
	if value:
		set_telegraphing(false)
	if _visual != null:
		_visual.color = Color(1.0, 0.12, 0.3, 0.86) if value else Color(0.25, 0.3, 0.42, 0.35)
	if _warning != null:
		_warning.text = "! ACTIVE !" if value else "SAFE WINDOW"
		_warning.modulate.a = 1.0 if value else 0.55
	if value:
		for body: Node2D in get_overlapping_bodies():
			if body.is_in_group(&"player"):
				var audio := get_node_or_null("/root/AudioManager")
				if audio != null:
					audio.call(&"play_sfx", &"hazard_warning", global_position, -6.0)
				break
	active_changed.emit(value)


func set_telegraphing(value: bool) -> void:
	if is_telegraphing == value or is_active:
		return
	is_telegraphing = value
	if _visual != null:
		_visual.color = Color(1.0, 0.75, 0.08, 0.58) if value else Color(0.25, 0.3, 0.42, 0.35)
	if _warning != null:
		_warning.text = "⚠ CHARGING" if value else "SAFE WINDOW"
	if value:
		telegraph_started.emit()


func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		set_telegraphing(false)
		set_active(false)
	else:
		reset_hazard()


func reset_hazard() -> void:
	_elapsed = phase_offset
	_damage_cooldowns.clear()
	set_telegraphing(false)
	set_active(active_on_ready and _enabled)


func _on_body_entered(body: Node2D) -> void:
	if is_active:
		_damage_body(body)


func _on_body_exited(body: Node2D) -> void:
	_damage_cooldowns.erase(body)


func _damage_body(body: Node2D) -> void:
	var valid_target := body.is_in_group(&"player") or (affects_enemies and body.is_in_group(&"enemies"))
	if not valid_target or float(_damage_cooldowns.get(body, 0.0)) > 0.0:
		return
	_damage_cooldowns[body] = 0.55
	if instant_kill and body.has_method(&"kill"):
		body.call(&"kill")
	elif body.has_method(&"take_damage"):
		var accepted: Variant = body.call(&"take_damage", damage)
		if accepted is bool and not accepted:
			_damage_cooldowns.erase(body)
			return
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
	_warning = Label.new()
	_warning.position = Vector2(-42.0, -half.y - 25.0)
	_warning.text = "! ACTIVE !"
	_warning.add_theme_color_override("font_color", Color.WHITE)
	add_child(_warning)
