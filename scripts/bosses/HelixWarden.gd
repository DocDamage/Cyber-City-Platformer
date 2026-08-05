class_name HelixWarden
extends BossBase

var _hover_time := 0.0


func get_attack_roster() -> Array[StringName]:
	return [&"projectile_arc", &"dash_pass", &"summoned_hazard_zone"]


func _update_phase_one(delta: float) -> void:
	_hover_time += delta
	_attack_cooldown -= delta
	velocity = Vector2(_pattern_direction * pattern_speed, sin(_hover_time * 2.4) * 44.0)
	if absf(global_position.x - _arena_origin.x) >= arena_half_width:
		_pattern_direction *= -1.0
	if _attack_cooldown <= 0.0:
		_fire_projectile_volley(3, 0.22)
		_attack_cooldown = projectile_interval


func _update_phase_two(delta: float) -> void:
	velocity.y = sin(_hover_time * 3.0) * 30.0
	_hover_time += delta
	super(delta)


func _update_phase_three(delta: float) -> void:
	_hover_time += delta
	velocity = Vector2(0.0, sin(_hover_time * 3.6) * 52.0)
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0 and _target != null:
		_fire_projectile_volley(5, 0.18)
		_spawn_arena_hazard(_target.global_position + Vector2(0.0, 24.0), Vector2(150.0, 48.0), 1.8)
		_attack_cooldown = 1.35
