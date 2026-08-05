class_name PlayerCombatController
extends Node

signal phase_changed(phase: StringName)
signal action_finished(kind: StringName)
signal hit_confirmed(target: Node)

const BULLET_SCENE := preload("res://scenes/Player/Bullet.tscn")

var _player: CharacterBody2D
var _hitbox: Hitbox
var _muzzle: Marker2D
var _busy := false
var _generation := 0
var _fire_cooldown := 0.0
var _facing_direction := 1.0


func _process(delta: float) -> void:
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)


func configure(player: CharacterBody2D, hitbox: Hitbox, muzzle: Marker2D) -> void:
	_player = player
	_hitbox = hitbox
	_muzzle = muzzle
	if not _hitbox.hit_landed.is_connected(_on_hit_landed):
		_hitbox.hit_landed.connect(_on_hit_landed)


func is_busy() -> bool:
	return _busy


func can_shoot() -> bool:
	return not _busy and is_zero_approx(_fire_cooldown)


func start_melee(airborne: bool, combo_step: int, damage: int, facing_direction: float) -> bool:
	if _busy or _player == null:
		return false
	_busy = true
	_generation += 1
	_facing_direction = facing_direction
	_run_melee(airborne, clampi(combo_step, 1, 3), maxi(damage, 1), _generation)
	return true


func start_shot(damage: int, facing_direction: float, fire_interval: float) -> bool:
	if not can_shoot() or _player == null or _muzzle == null:
		return false
	_busy = true
	_generation += 1
	_facing_direction = facing_direction
	_fire_cooldown = maxf(fire_interval, 0.05)
	_run_shot(maxi(damage, 1), _generation)
	return true


func cancel() -> void:
	_generation += 1
	_busy = false
	if _hitbox != null:
		_hitbox.deactivate()
	phase_changed.emit(&"cancelled")


func _run_melee(airborne: bool, combo_step: int, damage: int, generation: int) -> void:
	var startup: float = 0.07 if airborne else float([0.08, 0.07, 0.11][combo_step - 1])
	var active: float = 0.13 if airborne else float([0.1, 0.11, 0.14][combo_step - 1])
	var recovery: float = 0.18 if airborne else float([0.16, 0.17, 0.24][combo_step - 1])
	phase_changed.emit(&"startup")
	await get_tree().create_timer(startup, true, false, true).timeout
	if not _is_current(generation):
		return
	_hitbox.damage = damage
	_hitbox.activate(active)
	phase_changed.emit(&"active")
	await get_tree().create_timer(active, true, false, true).timeout
	if not _is_current(generation):
		return
	_hitbox.deactivate()
	phase_changed.emit(&"recovery")
	await get_tree().create_timer(recovery, true, false, true).timeout
	_finish(&"melee", generation)


func _run_shot(damage: int, generation: int) -> void:
	phase_changed.emit(&"startup")
	await get_tree().create_timer(0.06, true, false, true).timeout
	if not _is_current(generation):
		return
	_spawn_projectile(damage)
	phase_changed.emit(&"active")
	await get_tree().create_timer(0.04, true, false, true).timeout
	if not _is_current(generation):
		return
	phase_changed.emit(&"recovery")
	await get_tree().create_timer(0.12, true, false, true).timeout
	_finish(&"shoot", generation)


func _spawn_projectile(damage: int) -> void:
	var bullet := BULLET_SCENE.instantiate() as Hitbox
	if bullet == null:
		return
	bullet.damage = damage
	bullet.set("direction", -1 if _facing_direction < 0.0 else 1)
	var parent := get_tree().current_scene if get_tree().current_scene != null else _player.get_parent()
	parent.add_child(bullet)
	(bullet as Node2D).global_position = _muzzle.global_position


func _finish(kind: StringName, generation: int) -> void:
	if not _is_current(generation):
		return
	_busy = false
	phase_changed.emit(&"finished")
	action_finished.emit(kind)


func _is_current(generation: int) -> bool:
	return generation == _generation and _busy and is_instance_valid(_player)


func _on_hit_landed(hurtbox: Hurtbox) -> void:
	var target := hurtbox.get_parent()
	if target != null and target.has_method(&"apply_knockback"):
		target.call(&"apply_knockback", Vector2(_facing_direction * 180.0, -90.0))
	hit_confirmed.emit(target)
