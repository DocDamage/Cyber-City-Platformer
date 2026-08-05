class_name LunarOracle
extends BossBase

var _teleport_direction := -1.0
var _gravity_generation := 0


func get_attack_roster() -> Array[StringName]:
	return [&"teleport", &"gravity_inversion", &"projectile_pattern", &"laser_sweep"]


func _update_phase_one(delta: float) -> void:
	velocity = Vector2.ZERO
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		_teleport_direction *= -1.0
		_teleport_to_arena_offset(_teleport_direction * arena_half_width * 0.72, -90.0)
		_fire_projectile_volley(3, 0.28)
		_attack_cooldown = 1.2


func _update_phase_two(delta: float) -> void:
	velocity = Vector2.ZERO
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		_trigger_gravity_inversion()
		_fire_projectile_volley(5, 0.2)
		_attack_cooldown = 1.4


func _update_phase_three(delta: float) -> void:
	if _laser_elapsed < 0.0 and _attack_cooldown <= 0.0:
		_teleport_direction *= -1.0
		_teleport_to_arena_offset(_teleport_direction * arena_half_width * 0.6, -120.0)
	super(delta)


func _trigger_gravity_inversion() -> void:
	if _target == null or not _target.has_method(&"set_gravity_multiplier"):
		return
	_gravity_generation += 1
	var generation := _gravity_generation
	_target.call(&"set_gravity_multiplier", -0.48)
	_restore_gravity(generation)


func _restore_gravity(generation: int) -> void:
	await get_tree().create_timer(0.85, true, false, true).timeout
	if generation == _gravity_generation and is_instance_valid(_target):
		_target.call(&"set_gravity_multiplier", 1.0)
