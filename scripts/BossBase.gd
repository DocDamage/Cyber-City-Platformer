class_name BossBase
extends CharacterBody2D

signal encounter_started
signal intro_started(title: String)
signal intro_finished
signal encounter_reset
signal health_changed(current: int, maximum: int, percentage: float)
signal phase_changed(previous: State, current: State)
signal boss_defeated

enum State {
	PHASE_1,
	PHASE_2,
	PHASE_3,
}

const PROJECTILE_SCENE := preload("res://scenes/BossProjectile.tscn")

@export var boss_name := "STAGE GUARDIAN"
@export_range(1, 4, 1) var act_number := 1
@export_range(1, 999, 1) var max_health := 30
@export_range(0, 50000, 100) var score_value := 5000
@export_range(0.1, 0.9, 0.05) var phase_two_threshold := 0.5
@export_range(0.05, 0.5, 0.05) var phase_three_threshold := 0.2
@export_range(100.0, 1200.0, 10.0) var activation_range := 720.0
@export_range(40.0, 500.0, 5.0) var arena_half_width := 330.0
@export_range(20.0, 400.0, 5.0) var pattern_speed := 80.0
@export_range(100.0, 900.0, 10.0) var dash_speed := 470.0
@export_range(0.1, 2.0, 0.05) var dash_duration := 0.42
@export_range(0.2, 5.0, 0.1) var dash_interval := 1.25
@export_range(0.2, 5.0, 0.1) var projectile_interval := 1.15
@export_range(0.2, 5.0, 0.1) var laser_duration := 1.4
@export_range(0.2, 5.0, 0.1) var laser_interval := 0.75
@export_range(0.1, 1.5, 0.05) var laser_sweep_angle := 0.78
@export_range(0.0, 3.0, 0.05) var intro_duration := 0.7
@export var animation_library: SpriteFrames
@export var idle_animation: StringName = &"idle"
@export var move_animation: StringName = &"run"
@export var attack_animation: StringName = &"attack"
@export var hurt_animation: StringName = &"hurt"
@export var death_animation: StringName = &"death"
@export var sprite_visual_scale := Vector2.ONE
@export var accent_color := Color(1.0, 0.1, 0.55)

var health := 0
var state: State = State.PHASE_1
var encounter_active := false
var is_defeated := false
var intro_active := false

var _target: Node2D
var _arena_origin := Vector2.ZERO
var _pattern_direction := -1.0
var _attack_cooldown := 0.0
var _dash_time_remaining := 0.0
var _laser_elapsed := -1.0
var _laser_base_angle := 0.0
var _laser_direction := 1.0
var _intro_remaining := 0.0
var _spawned_attack_nodes: Array[Node] = []

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var slash_hitbox: Hitbox = $SlashHitbox
@onready var muzzle: Marker2D = $Muzzle
@onready var laser_pivot: Node2D = $LaserPivot
@onready var laser_hitbox: Hitbox = $LaserPivot/LaserHitbox
@onready var laser_visual: Line2D = $LaserPivot/LaserHitbox/LaserVisual
@onready var point_light: PointLight2D = $PointLight2D


func _ready() -> void:
	add_to_group(&"bosses")
	health = max_health
	_arena_origin = global_position
	if animation_library != null:
		sprite.sprite_frames = animation_library
	sprite.scale = sprite_visual_scale
	point_light.color = accent_color
	slash_hitbox.deactivate()
	laser_hitbox.deactivate()
	laser_visual.visible = false
	_play_animation(idle_animation)
	_find_target.call_deferred()
	_lock_stage_exits.call_deferred()


func _physics_process(delta: float) -> void:
	if is_defeated:
		return
	if not is_instance_valid(_target):
		_find_target()
	if not encounter_active:
		velocity = Vector2.ZERO
		if _target != null and absf(_target.global_position.x - global_position.x) <= activation_range:
			start_encounter()
		return
	if intro_active:
		_intro_remaining = maxf(_intro_remaining - delta, 0.0)
		velocity = Vector2.ZERO
		if is_zero_approx(_intro_remaining):
			complete_intro()
		return

	_face_target()
	match state:
		State.PHASE_1:
			_update_phase_one(delta)
		State.PHASE_2:
			_update_phase_two(delta)
		State.PHASE_3:
			_update_phase_three(delta)
	move_and_slide()


func start_encounter() -> void:
	if encounter_active or is_defeated:
		return
	encounter_active = true
	intro_active = intro_duration > 0.0
	_intro_remaining = intro_duration
	_attack_cooldown = 0.35
	encounter_started.emit()
	intro_started.emit(boss_name)
	health_changed.emit(health, max_health, get_health_percentage())
	if _target != null and _target.has_method(&"set_input_disabled"):
		_target.call(&"set_input_disabled", true)
	if not intro_active:
		complete_intro()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call(&"play_boss_bgm", act_number)


func take_damage(amount: int) -> bool:
	if is_defeated or amount <= 0:
		return false
	if not encounter_active:
		start_encounter()
	if intro_active:
		return false
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health, get_health_percentage())
	if health == 0:
		_die()
		return true
	_update_health_gate()
	_flash_damage()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call(&"play_sfx", &"armor_hit", global_position, -7.0)
	return true


func complete_intro() -> void:
	if not encounter_active:
		return
	intro_active = false
	_intro_remaining = 0.0
	if _target != null and _target.has_method(&"set_input_disabled"):
		_target.call(&"set_input_disabled", false)
	intro_finished.emit()


func get_attack_roster() -> Array[StringName]:
	return [&"projectile_volley", &"dash", &"laser_sweep"]


func reset_encounter() -> void:
	if is_defeated:
		return
	_cleanup_spawned_attacks()
	health = max_health
	state = State.PHASE_1
	encounter_active = false
	intro_active = false
	_intro_remaining = 0.0
	velocity = Vector2.ZERO
	global_position = _arena_origin
	_attack_cooldown = 0.0
	_dash_time_remaining = 0.0
	_stop_laser()
	slash_hitbox.deactivate()
	hurtbox.set_invincible(false)
	health_changed.emit(health, max_health, 1.0)
	_lock_stage_exits()
	encounter_reset.emit()


func get_health_percentage() -> float:
	return float(health) / float(maxi(max_health, 1))


func get_phase_number() -> int:
	return int(state) + 1


func _update_health_gate() -> void:
	var percentage := get_health_percentage()
	var next_state := state
	if percentage <= phase_three_threshold:
		next_state = State.PHASE_3
	elif percentage <= phase_two_threshold:
		next_state = State.PHASE_2
	if next_state != state:
		_change_phase(next_state)


func _change_phase(next_state: State) -> void:
	var previous := state
	state = next_state
	velocity = Vector2.ZERO
	_dash_time_remaining = 0.0
	_stop_laser()
	slash_hitbox.deactivate()
	_attack_cooldown = 0.45
	phase_changed.emit(previous, state)
	var vfx := get_node_or_null("/root/VFXSpawner")
	if vfx != null:
		vfx.call(&"spawn_effect", &"explosion_ring", global_position + Vector2(0.0, -36.0))
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call(&"play_sfx", &"phase_change", global_position, -5.0)
	var feedback := get_node_or_null("/root/CombatFeedback")
	if feedback != null:
		feedback.call(&"camera_shake", 6.0 + float(state) * 2.0, 0.22)


func _update_phase_one(delta: float) -> void:
	_play_animation(move_animation)
	_attack_cooldown -= delta
	if global_position.x <= _arena_origin.x - arena_half_width:
		_pattern_direction = 1.0
	elif global_position.x >= _arena_origin.x + arena_half_width:
		_pattern_direction = -1.0
	velocity.x = _pattern_direction * pattern_speed
	if is_on_wall():
		_pattern_direction *= -1.0
	if _attack_cooldown <= 0.0:
		_fire_projectile_volley(1, 0.0)
		_attack_cooldown = projectile_interval


func _update_phase_two(delta: float) -> void:
	if _dash_time_remaining > 0.0:
		_dash_time_remaining -= delta
		if _dash_time_remaining <= 0.0 or is_on_wall():
			_dash_time_remaining = 0.0
			velocity.x = 0.0
			slash_hitbox.deactivate()
			_attack_cooldown = dash_interval
			_play_animation(idle_animation)
		return

	velocity.x = move_toward(velocity.x, 0.0, dash_speed * 5.0 * delta)
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		_begin_dash_slash()


func _begin_dash_slash() -> void:
	var dash_direction := _pattern_direction
	if _target != null:
		dash_direction = signf(_target.global_position.x - global_position.x)
	if is_zero_approx(dash_direction):
		dash_direction = 1.0
	_pattern_direction = dash_direction
	velocity.x = dash_direction * dash_speed
	_dash_time_remaining = dash_duration
	slash_hitbox.position.x = 42.0 * dash_direction
	slash_hitbox.activate(dash_duration)
	_play_animation(attack_animation)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call(&"play_sfx", &"sword_slash", global_position, -2.0)


func _update_phase_three(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * 6.0 * delta)
	if _laser_elapsed >= 0.0:
		_laser_elapsed += delta
		var progress := clampf(_laser_elapsed / laser_duration, 0.0, 1.0)
		var sweep_offset := lerpf(-laser_sweep_angle, laser_sweep_angle, progress) * _laser_direction
		laser_pivot.rotation = _laser_base_angle + sweep_offset
		if progress >= 1.0:
			_stop_laser()
			_attack_cooldown = laser_interval
		return

	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		_start_laser_sweep()


func _start_laser_sweep() -> void:
	_laser_elapsed = 0.0
	_laser_direction *= -1.0
	_laser_base_angle = PI if _target != null and _target.global_position.x < global_position.x else 0.0
	laser_visual.default_color = accent_color
	laser_visual.visible = true
	laser_hitbox.activate(laser_duration)
	_play_animation(attack_animation)
	_fire_projectile_volley(3, 0.2)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call(&"play_sfx", &"laser_shot", global_position, -1.0)


func _stop_laser() -> void:
	_laser_elapsed = -1.0
	laser_hitbox.deactivate()
	laser_visual.visible = false
	laser_pivot.rotation = 0.0


func _fire_projectile_volley(projectile_count: int, spread_radians: float) -> void:
	if _target == null:
		return
	var aim_direction := (_target.global_position - muzzle.global_position).normalized()
	var first_angle := -spread_radians * float(projectile_count - 1) * 0.5
	for index in range(projectile_count):
		_spawn_projectile(aim_direction.rotated(first_angle + spread_radians * index))
	_play_animation(attack_animation)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call(&"play_sfx", &"laser_shot", muzzle.global_position, -4.0)


func _face_target() -> void:
	if _target == null:
		return
	var facing_left := _target.global_position.x < global_position.x
	sprite.flip_h = facing_left
	muzzle.position.x = -36.0 if facing_left else 36.0


func _find_target() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		if node is Node2D:
			_target = node as Node2D
			if _target.has_signal(&"died") and not _target.is_connected(&"died", _on_player_died):
				_target.connect(&"died", _on_player_died)
			return
	_target = null


func _flash_damage() -> void:
	_play_animation(hurt_animation)
	sprite.modulate = Color(1.0, 0.35, 0.55)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)


func _die() -> void:
	if is_defeated:
		return
	is_defeated = true
	encounter_active = false
	intro_active = false
	velocity = Vector2.ZERO
	set_physics_process(false)
	body_collision.set_deferred("disabled", true)
	hurtbox.set_invincible(true)
	slash_hitbox.deactivate()
	_stop_laser()
	_play_animation(death_animation)
	boss_defeated.emit()
	_unlock_stage_exits()
	_cleanup_spawned_attacks()
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		if score_value > 0:
			manager.call(&"add_score", score_value)
		manager.call(&"mark_boss_defeated", StringName(boss_name.to_snake_case()))
		var rewards := [&"max_health", &"max_energy", &"energy_regeneration", &"melee_damage"]
		manager.call(&"award_upgrade", rewards[act_number - 1])
	var vfx := get_node_or_null("/root/VFXSpawner")
	if vfx != null:
		for offset in [Vector2(0.0, -36.0), Vector2(-28.0, -18.0), Vector2(30.0, -48.0)]:
			vfx.call(&"spawn_effect", &"explosion_ring", global_position + offset)
		vfx.call(&"spawn_effect", &"smoke", global_position + Vector2(0.0, -30.0))
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call(&"play_sfx", &"explosion", global_position, 0.0)
	var feedback := get_node_or_null("/root/CombatFeedback")
	if feedback != null:
		feedback.call(&"hit_stop", 0.1)
		feedback.call(&"camera_shake", 16.0, 0.5)
	_finish_death()


func _finish_death() -> void:
	await get_tree().create_timer(0.85, true, false, true).timeout
	queue_free()


func _spawn_projectile(direction: Vector2, speed_scale := 1.0) -> Node:
	var projectile := PROJECTILE_SCENE.instantiate()
	var projectile_parent := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	projectile_parent.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.modulate = accent_color
	projectile.set("speed", float(projectile.get("speed")) * speed_scale)
	projectile.call(&"launch", direction)
	_spawned_attack_nodes.append(projectile)
	return projectile


func _spawn_shockwave() -> void:
	_spawn_projectile(Vector2.LEFT, 1.35)
	_spawn_projectile(Vector2.RIGHT, 1.35)


func _spawn_arena_hazard(hazard_position: Vector2, size := Vector2(120.0, 54.0), lifetime := 2.5) -> Hazard:
	var hazard := Hazard.new()
	hazard.hazard_id = &"boss_arena_hazard"
	hazard.hazard_size = size
	hazard.active_duration = lifetime
	hazard.inactive_duration = 0.0
	var parent := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	parent.add_child(hazard)
	hazard.global_position = hazard_position
	_spawned_attack_nodes.append(hazard)
	_expire_attack_node(hazard, lifetime)
	return hazard


func _teleport_to_arena_offset(offset_x: float, offset_y := 0.0) -> void:
	global_position = _arena_origin + Vector2(clampf(offset_x, -arena_half_width, arena_half_width), offset_y)
	velocity = Vector2.ZERO


func _expire_attack_node(node: Node, lifetime: float) -> void:
	await get_tree().create_timer(lifetime, true, false, true).timeout
	_spawned_attack_nodes.erase(node)
	if is_instance_valid(node):
		node.queue_free()


func _cleanup_spawned_attacks() -> void:
	for node: Node in _spawned_attack_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_spawned_attack_nodes.clear()


func _on_player_died() -> void:
	if encounter_active and not is_defeated:
		reset_encounter()


func _lock_stage_exits() -> void:
	for stage_exit: Node in get_tree().get_nodes_in_group(&"stage_exits"):
		if _shares_stage_root(stage_exit) and stage_exit.has_method(&"set_locked"):
			stage_exit.call(&"set_locked", true)


func _unlock_stage_exits() -> void:
	for stage_exit: Node in get_tree().get_nodes_in_group(&"stage_exits"):
		if _shares_stage_root(stage_exit) and stage_exit.has_method(&"set_locked"):
			stage_exit.call(&"set_locked", false)


func _shares_stage_root(other: Node) -> bool:
	return _top_level_scene_node(self) == _top_level_scene_node(other)


func _top_level_scene_node(node: Node) -> Node:
	var candidate := node
	while candidate.get_parent() != null and candidate.get_parent() != get_tree().root:
		candidate = candidate.get_parent()
	return candidate


func _play_animation(requested: StringName) -> void:
	if sprite.sprite_frames == null:
		return
	if sprite.sprite_frames.has_animation(requested):
		if sprite.animation != requested or not sprite.is_playing():
			sprite.play(requested)
		return
	for fallback: StringName in [&"idle", &"run", &"walk", &"move", &"flying"]:
		if sprite.sprite_frames.has_animation(fallback):
			if sprite.animation != fallback or not sprite.is_playing():
				sprite.play(fallback)
			return
