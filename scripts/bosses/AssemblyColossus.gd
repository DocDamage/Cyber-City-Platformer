class_name AssemblyColossus
extends BossBase

var vulnerability_open := true
var _vulnerability_remaining := 0.0


func get_attack_roster() -> Array[StringName]:
	return [&"slam", &"shockwave", &"machinery_dash", &"vulnerability_window"]


func take_damage(amount: int) -> bool:
	if state == State.PHASE_3 and not vulnerability_open:
		return false
	return super(amount)


func open_vulnerability(duration := 0.85) -> void:
	vulnerability_open = true
	_vulnerability_remaining = duration
	hurtbox.set_invincible(false)
	point_light.energy = 1.6


func _change_phase(next_state: State) -> void:
	super(next_state)
	if next_state == State.PHASE_3:
		open_vulnerability()


func _update_phase_one(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		_spawn_shockwave()
		slash_hitbox.activate(0.2)
		_attack_cooldown = 1.45


func _update_phase_two(delta: float) -> void:
	if _dash_time_remaining <= 0.0 and _attack_cooldown <= 0.0:
		_spawn_shockwave()
	super(delta)


func _update_phase_three(delta: float) -> void:
	velocity.x = 0.0
	_attack_cooldown -= delta
	_vulnerability_remaining = maxf(_vulnerability_remaining - delta, 0.0)
	if vulnerability_open and is_zero_approx(_vulnerability_remaining):
		vulnerability_open = false
		hurtbox.set_invincible(true)
		point_light.energy = 0.55
	if _attack_cooldown <= 0.0:
		_spawn_shockwave()
		_spawn_arena_hazard(_arena_origin, Vector2(210.0, 46.0), 1.1)
		open_vulnerability()
		_attack_cooldown = 1.7
