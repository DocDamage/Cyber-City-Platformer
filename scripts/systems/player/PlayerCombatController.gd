class_name PlayerCombatController
extends Node

signal phase_changed(phase: StringName)
signal action_finished(kind: StringName)
signal hit_confirmed(target: Node)

const BULLET_SCENE := preload("res://scenes/Player/Bullet.tscn")
const WEAPON_ARC_SCRIPT := preload("res://scripts/systems/player/WeaponArc.gd")

var _player: CharacterBody2D
var _hitbox: Hitbox
var _muzzle: Marker2D
var _busy := false
var _generation := 0
var _fire_cooldown := 0.0
var _facing_direction := 1.0
var _weapon_family: StringName = &"sword"
var _phase: StringName = &"ready"
var _active_profile: Dictionary = {}


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


func get_phase() -> StringName:
	return _phase


func can_movement_cancel() -> bool:
	return _busy and _phase == &"recovery"


func set_weapon_family(family_id: StringName) -> void:
	_weapon_family = family_id if WeaponCatalog.has_family(family_id) else &"sword"


func get_weapon_family() -> StringName:
	return _weapon_family


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
	_phase = &"cancelled"
	_active_profile.clear()
	if _hitbox != null:
		_hitbox.deactivate()
	phase_changed.emit(&"cancelled")


func _run_melee(airborne: bool, combo_step: int, damage: int, generation: int) -> void:
	var profile := WeaponCatalog.attack_profile(_weapon_family, airborne, combo_step)
	profile = _enrich_attack_profile(profile, combo_step, airborne)
	_active_profile = profile
	var startup := float(profile.get("startup", 0.08))
	var active := float(profile.get("active", 0.1))
	var recovery := float(profile.get("recovery", 0.16))
	_apply_hitbox_profile(profile)
	_set_phase(&"startup")
	await get_tree().create_timer(startup, true, false, true).timeout
	if not _is_current(generation):
		return
	_apply_attack_motion(profile)
	_spawn_weapon_arc(profile)
	_hitbox.damage = maxi(int(round(float(damage) * float(profile.get("damage", 1.0)))), 1)
	_hitbox.activate(active)
	_set_phase(&"active")
	await get_tree().create_timer(active, true, false, true).timeout
	if not _is_current(generation):
		return
	_hitbox.deactivate()
	_set_phase(&"recovery")
	await get_tree().create_timer(recovery, true, false, true).timeout
	_finish(&"melee", generation)


func _apply_hitbox_profile(profile: Dictionary) -> void:
	if _hitbox == null:
		return
	var collision := _hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var dimensions: Array = profile.get("hitbox", [36, 40])
	if collision != null and collision.shape is RectangleShape2D and dimensions.size() == 2:
		(collision.shape as RectangleShape2D).size = Vector2(float(dimensions[0]), float(dimensions[1]))
	var offset := float(profile.get("offset", 26.0))
	_hitbox.position.x = offset * _facing_direction
	_hitbox.position.y = float(profile.get("vertical_offset", -10.0))
	_hitbox.hit_stop_duration = float(profile.get("hit_stop", 0.05))
	_hitbox.camera_shake_strength = float(profile.get("camera_shake", 6.0))
	_hitbox.camera_shake_duration = float(profile.get("camera_shake_duration", 0.12))


func _run_shot(damage: int, generation: int) -> void:
	var technique := WeaponCatalog.technique_profile(_weapon_family)
	technique = _enrich_technique_profile(technique)
	_active_profile = technique
	var startup := float(technique.get("startup", 0.06))
	var active := float(technique.get("active", 0.08))
	var recovery := float(technique.get("recovery", 0.12))
	_set_phase(&"startup")
	await get_tree().create_timer(startup, true, false, true).timeout
	if not _is_current(generation):
		return
	var scaled_damage := maxi(roundi(float(damage) * float(technique.get("damage", 1.0))), 1)
	if String(technique.get("kind", "projectile")) == "hitbox":
		_apply_hitbox_profile(technique)
		_apply_attack_motion(technique)
		_spawn_weapon_arc(technique)
		_hitbox.damage = scaled_damage
		_hitbox.activate(active)
	else:
		var count := maxi(int(technique.get("count", 1)), 1)
		var spread := float(technique.get("spread", 0.0))
		var speed := float(technique.get("speed", 400.0))
		for index: int in range(count):
			var angle := (float(index) - float(count - 1) * 0.5) * spread
			var direction := Vector2(_facing_direction, 0.0).rotated(angle)
			_spawn_projectile(scaled_damage, direction, speed, _projectile_scale())
	_set_phase(&"active")
	await get_tree().create_timer(active, true, false, true).timeout
	if not _is_current(generation):
		return
	if String(technique.get("kind", "projectile")) == "hitbox":
		_hitbox.deactivate()
	_set_phase(&"recovery")
	await get_tree().create_timer(recovery, true, false, true).timeout
	_finish(&"shoot", generation)


func _spawn_projectile(damage: int, projectile_direction := Vector2.ZERO, speed := 400.0, visual_scale := Vector2.ONE) -> void:
	var bullet := BULLET_SCENE.instantiate() as Hitbox
	if bullet == null:
		return
	bullet.damage = damage
	bullet.set("direction", projectile_direction if not projectile_direction.is_zero_approx() else Vector2(_facing_direction, 0.0))
	bullet.set("speed", speed)
	(bullet as Node2D).scale = visual_scale
	(bullet as CanvasItem).modulate = _projectile_color()
	var parent := get_tree().current_scene if get_tree().current_scene != null else _player.get_parent()
	parent.add_child(bullet)
	(bullet as Node2D).global_position = _muzzle.global_position


func _projectile_scale() -> Vector2:
	match _weapon_family:
		&"dagger": return Vector2(0.65, 0.65)
		&"bow": return Vector2(1.5, 0.65)
		&"staff": return Vector2(1.25, 1.25)
		_: return Vector2.ONE


func _projectile_color() -> Color:
	match _weapon_family:
		&"dagger": return Color("ff75c8")
		&"bow": return Color("ffe66b")
		&"staff": return Color("a879ff")
		_: return Color("58f0ff")


func _finish(kind: StringName, generation: int) -> void:
	if not _is_current(generation):
		return
	_busy = false
	_active_profile.clear()
	_set_phase(&"finished")
	action_finished.emit(kind)


func _is_current(generation: int) -> bool:
	return generation == _generation and _busy and is_instance_valid(_player)


func _on_hit_landed(hurtbox: Hurtbox) -> void:
	var target := hurtbox.get_parent()
	if target != null and target.has_method(&"apply_knockback"):
		var knockback_x := float(_active_profile.get("knockback_x", 180.0))
		var knockback_y := float(_active_profile.get("knockback_y", -90.0))
		target.call(&"apply_knockback", Vector2(_facing_direction * knockback_x, knockback_y))
	_spawn_hit_sparks(target)
	hit_confirmed.emit(target)


func _set_phase(next_phase: StringName) -> void:
	_phase = next_phase
	phase_changed.emit(_phase)


func _apply_attack_motion(profile: Dictionary) -> void:
	if _player == null:
		return
	var lunge := float(profile.get("lunge", 0.0))
	if lunge <= 0.0:
		return
	var target_speed := lunge * _facing_direction
	if absf(_player.velocity.x) < absf(target_speed):
		_player.velocity.x = target_speed


func _spawn_weapon_arc(profile: Dictionary) -> void:
	if _player == null:
		return
	var arc := WEAPON_ARC_SCRIPT.new() as Node2D
	arc.name = "WeaponArc"
	arc.call(&"configure", profile, _facing_direction, _attack_color())
	_player.add_child(arc)
	arc.position = Vector2(0.0, -12.0)


func _spawn_hit_sparks(target: Node) -> void:
	var spawner := get_node_or_null("/root/VFXSpawner")
	if spawner == null or target is not Node2D:
		return
	var target_position := (target as Node2D).global_position
	var impact_position := target_position.lerp(_player.global_position, 0.22) if _player != null else target_position
	spawner.call(&"spawn_effect", &"sparks", impact_position, Vector2(_facing_direction, -0.15))


func _attack_color() -> Color:
	match _weapon_family:
		&"dagger": return Color("ff75c8")
		&"spear": return Color("7ee6ff")
		&"heavy": return Color("ffb35b")
		&"bow": return Color("ffe66b")
		&"staff": return Color("b893ff")
		_: return Color("58f0ff")


func _enrich_attack_profile(source: Dictionary, combo_step: int, airborne: bool) -> Dictionary:
	var profile := source.duplicate(true)
	var family_motion := {
		"sword": [155.0, 0.048, 6.0, 190.0],
		"dagger": [125.0, 0.032, 4.0, 135.0],
		"spear": [195.0, 0.052, 6.5, 230.0],
		"heavy": [105.0, 0.085, 10.0, 300.0],
		"bow": [80.0, 0.035, 4.0, 120.0],
		"staff": [95.0, 0.055, 7.0, 170.0],
	}
	var values := family_motion.get(String(_weapon_family), family_motion["sword"]) as Array
	profile["lunge"] = float(profile.get("lunge", float(values[0]) + float(combo_step - 1) * 12.0))
	profile["hit_stop"] = float(profile.get("hit_stop", float(values[1]) + (0.012 if combo_step == 3 else 0.0)))
	profile["camera_shake"] = float(profile.get("camera_shake", float(values[2]) + (2.0 if combo_step == 3 else 0.0)))
	profile["knockback_x"] = float(profile.get("knockback_x", float(values[3]) + float(combo_step - 1) * 25.0))
	profile["knockback_y"] = float(profile.get("knockback_y", -125.0 if airborne else -82.0))
	profile["arc_weight"] = 1.65 if _weapon_family == &"heavy" else (0.82 if _weapon_family == &"dagger" else 1.0)
	return profile


func _enrich_technique_profile(source: Dictionary) -> Dictionary:
	var profile := source.duplicate(true)
	profile["hit_stop"] = float(profile.get("hit_stop", 0.07 if _weapon_family in [&"heavy", &"spear"] else 0.045))
	profile["camera_shake"] = float(profile.get("camera_shake", 9.0 if _weapon_family == &"heavy" else 5.5))
	profile["knockback_x"] = float(profile.get("knockback_x", 260.0 if _weapon_family == &"heavy" else 190.0))
	profile["knockback_y"] = float(profile.get("knockback_y", -110.0))
	profile["lunge"] = float(profile.get("lunge", 115.0 if String(profile.get("kind", "projectile")) == "hitbox" else 0.0))
	profile["arc_weight"] = 1.5 if _weapon_family == &"heavy" else 1.0
	return profile
