class_name VoidCerberus
extends BossBase


func get_attack_roster() -> Array[StringName]:
	return [&"multi_head_spread", &"corruption_zone", &"dash_attack", &"breath_sweep", &"desperation"]


func _update_phase_one(delta: float) -> void:
	_play_animation(move_animation)
	_attack_cooldown -= delta
	velocity.x = _pattern_direction * pattern_speed
	if absf(global_position.x - _arena_origin.x) >= arena_half_width:
		_pattern_direction *= -1.0
	if _attack_cooldown <= 0.0:
		_fire_projectile_volley(3, 0.34)
		_attack_cooldown = projectile_interval


func _update_phase_two(delta: float) -> void:
	if _dash_time_remaining <= 0.0 and _attack_cooldown <= 0.0 and _target != null:
		_spawn_arena_hazard(_target.global_position + Vector2(0.0, 28.0), Vector2(130.0, 52.0), 1.45)
	super(delta)


func _update_phase_three(delta: float) -> void:
	if _laser_elapsed < 0.0 and _attack_cooldown <= 0.0:
		_fire_projectile_volley(7, 0.17)
		_spawn_arena_hazard(_arena_origin, Vector2(arena_half_width * 1.35, 44.0), 1.2)
	super(delta)
