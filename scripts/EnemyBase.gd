class_name EnemyBase
extends CharacterBody2D

signal damaged(amount: int, health_remaining: int)
signal died
signal state_changed(previous: State, current: State)

enum State {
	IDLE,
	PATROL,
	CHASE,
	TELEGRAPH,
	ATTACK,
	RECOVERY,
	HURT,
	STUNNED,
	DEAD,
}

const SMOKE_VFX := preload("res://scenes/vfx/SmokeBurst.tscn")
const PROJECTILE_SCENE := preload("res://scenes/systems/security/EnemyProjectile.tscn")

@export var enemy_id: StringName = &"goblin"
@export var archetype: StringName = &"ground_chaser"
@export var animation_library: SpriteFrames
@export_range(0.0, 400.0, 1.0) var patrol_speed := 70.0
@export_range(0.0, 600.0, 1.0) var chase_speed := 115.0
@export_range(32.0, 1200.0, 1.0) var patrol_distance := 220.0
@export_range(0.0, 3.0, 0.05) var idle_duration := 0.55
@export_range(1, 100, 1) var max_health := 3
@export_range(0, 10000, 10) var score_value := 250
@export var initial_state: State = State.IDLE
@export_enum("Left:-1", "Right:1") var starting_direction := -1
@export var uses_gravity := true
@export var movement_animation: StringName
@export var death_animation: StringName
@export var sprite_visual_scale := Vector2.ONE

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var health := 0
var direction := -1
var state: State = State.IDLE
var is_dead := false
var attack_damage := 1
var attack_range := 52.0
var attack_cooldown := 1.0
var _attack_cooldown_remaining := 0.0
var _idle_time_remaining := 0.0
var _patrol_origin := Vector2.ZERO
var _flight_phase := 0.0
var _hurt_generation := 0
var _chase_target: Node2D
var _attack_controller: EnemyAttackController

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contact_hitbox: Hitbox = $ContactHitbox
@onready var floor_check: RayCast2D = $FloorCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var detection_area: Area2D = get_node_or_null("DetectionArea") as Area2D


func _ready() -> void:
	add_to_group(&"enemies")
	_apply_library_configuration()
	health = max_health
	direction = 1 if starting_direction > 0 else -1
	_patrol_origin = global_position
	if animation_library == null:
		animation_library = _get_enemy_sprite_frames(enemy_id)
	if animation_library != null:
		sprite.sprite_frames = animation_library
	sprite.scale = sprite_visual_scale
	_configure_runtime_components()
	_face_direction()
	_connect_detection_area()
	_build_attack_controller()
	_change_state(initial_state, true)
	_scan_for_player.call_deferred()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	if uses_gravity and not is_on_floor():
		velocity.y += gravity * delta
	if not is_instance_valid(_chase_target):
		_chase_target = null
		if state == State.CHASE:
			_change_state(State.IDLE)
	match state:
		State.IDLE:
			_update_idle(delta)
		State.PATROL:
			_update_patrol(delta)
		State.CHASE:
			_update_chase()
		State.TELEGRAPH, State.ATTACK, State.RECOVERY, State.HURT, State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	move_and_slide()
	if state == State.PATROL and uses_gravity and is_on_wall():
		_turn_around()
		_change_state(State.IDLE)


func take_damage(amount: int) -> bool:
	if is_dead or amount <= 0:
		return false
	var applied_damage := amount
	if archetype == &"shielded_enemy":
		applied_damage = maxi(amount - 1, 1)
	health = maxi(health - applied_damage, 0)
	damaged.emit(applied_damage, health)
	if health == 0:
		_die()
	else:
		_enter_hurt_state()
	return true


func apply_knockback(force: Vector2) -> void:
	if not is_dead:
		velocity += force


func set_state(next_state: State) -> void:
	_change_state(next_state)


func get_chase_target() -> Node2D:
	return _chase_target


func get_archetype() -> StringName:
	return archetype


func _update_idle(delta: float) -> void:
	velocity.x = 0.0
	if _chase_target != null:
		_change_state(State.CHASE)
		return
	_idle_time_remaining = maxf(_idle_time_remaining - delta, 0.0)
	if is_zero_approx(_idle_time_remaining):
		_change_state(State.PATROL)


func _update_patrol(delta: float) -> void:
	if _chase_target != null:
		_change_state(State.CHASE)
		return
	if not uses_gravity:
		_flight_phase += delta * 2.2
		velocity.y = sin(_flight_phase) * 22.0
		if absf(global_position.x - _patrol_origin.x) >= patrol_distance:
			_turn_around()
			_change_state(State.IDLE)
			return
	elif is_on_floor() and (not floor_check.is_colliding() or wall_check.is_colliding()):
		_turn_around()
		_change_state(State.IDLE)
		return
	velocity.x = direction * patrol_speed


func _update_chase() -> void:
	if _chase_target == null:
		_change_state(State.IDLE)
		return
	var target_delta := _chase_target.global_position - global_position
	if target_delta.length() <= attack_range and is_zero_approx(_attack_cooldown_remaining):
		_begin_attack()
		return
	var chase_direction := 1 if target_delta.x > 0.0 else -1
	if chase_direction != direction:
		direction = chase_direction
		_face_direction()
	if uses_gravity and is_on_floor() and (not floor_check.is_colliding() or wall_check.is_colliding()):
		velocity.x = 0.0
		return
	velocity.x = direction * chase_speed
	if not uses_gravity:
		velocity.y = clampf(target_delta.y * 1.4, -chase_speed * 0.65, chase_speed * 0.65)


func _begin_attack() -> void:
	if _attack_controller == null or state != State.CHASE:
		return
	_change_state(State.TELEGRAPH)
	sprite.modulate = Color(1.0, 0.42, 0.24)
	var kind := _attack_kind()
	var telegraph := 0.2 if archetype == &"fast_melee_attacker" else 0.38
	_attack_controller.start_attack(kind, telegraph, 0.14, 0.32)


func _attack_kind() -> StringName:
	match archetype:
		&"ranged_shooter", &"flying_shooter": return &"ranged"
		&"leaping_enemy": return &"leap"
		&"hazard_spawning_enemy": return &"hazard"
		_: return &"melee"


func _on_attack_committed(kind: StringName) -> void:
	if is_dead:
		return
	_change_state(State.ATTACK)
	sprite.modulate = Color.WHITE
	_play_first_available(_attack_candidates())
	match kind:
		&"ranged": _spawn_projectile(Vector2(direction, 0.0))
		&"hazard":
			_spawn_projectile(Vector2(direction, -0.28))
			_spawn_projectile(Vector2(direction, 0.0))
			_spawn_projectile(Vector2(direction, 0.28))
		&"leap":
			velocity = Vector2(direction * chase_speed * 1.65, -260.0)
			contact_hitbox.activate(0.2)
		_:
			contact_hitbox.activate(0.14)


func _on_recovery_started() -> void:
	if not is_dead:
		_change_state(State.RECOVERY)


func _on_attack_finished() -> void:
	if is_dead:
		return
	_attack_cooldown_remaining = attack_cooldown
	_change_state(State.CHASE if _chase_target != null else State.IDLE)


func _spawn_projectile(projectile_direction: Vector2) -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as EnemyProjectile
	if projectile == null:
		return
	projectile.damage = attack_damage
	var parent := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	parent.add_child(projectile)
	projectile.global_position = global_position + Vector2(direction * 24.0, -24.0)
	projectile.launch(projectile_direction)


func _enter_hurt_state() -> void:
	_hurt_generation += 1
	var generation := _hurt_generation
	_attack_controller.cancel()
	contact_hitbox.deactivate()
	_change_state(State.HURT)
	sprite.modulate = Color(1.0, 0.25, 0.45)
	_recover_from_hurt(generation)


func _recover_from_hurt(generation: int) -> void:
	await get_tree().create_timer(0.2).timeout
	if generation != _hurt_generation or is_dead:
		return
	sprite.modulate = Color.WHITE
	_change_state(State.CHASE if _chase_target != null else State.IDLE)


func _change_state(next_state: State, force := false) -> void:
	if not force and state == next_state:
		return
	var previous := state
	state = next_state
	match state:
		State.IDLE:
			_idle_time_remaining = idle_duration
			velocity.x = 0.0
			_play_first_available(_idle_candidates())
		State.PATROL, State.CHASE:
			_play_first_available(_movement_candidates())
		State.DEAD:
			velocity = Vector2.ZERO
	state_changed.emit(previous, state)


func _turn_around() -> void:
	direction *= -1
	_face_direction()


func _face_direction() -> void:
	sprite.flip_h = direction < 0
	floor_check.position.x = 14.0 * direction
	wall_check.target_position.x = 18.0 * direction


func _configure_runtime_components() -> void:
	floor_check.enabled = uses_gravity
	wall_check.enabled = uses_gravity
	floor_check.collision_mask = 1
	wall_check.collision_mask = 1
	contact_hitbox.damage = attack_damage
	contact_hitbox.deactivate()
	if detection_area == null:
		detection_area = Area2D.new()
		detection_area.name = "DetectionArea"
		detection_area.collision_layer = 0
		detection_area.collision_mask = 2
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		detection_area.add_child(collision)
		add_child(detection_area)
	var detection_collision := detection_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if detection_collision != null:
		var circle := detection_collision.shape as CircleShape2D
		if circle == null:
			circle = CircleShape2D.new()
			detection_collision.shape = circle
		circle.radius = float(_get_enemy_info().get("detection_radius", 210.0))


func _build_attack_controller() -> void:
	_attack_controller = EnemyAttackController.new()
	_attack_controller.name = "AttackController"
	add_child(_attack_controller)
	_attack_controller.attack_committed.connect(_on_attack_committed)
	_attack_controller.recovery_started.connect(_on_recovery_started)
	_attack_controller.attack_finished.connect(_on_attack_finished)


func _connect_detection_area() -> void:
	if not detection_area.body_entered.is_connected(_on_detection_body_entered):
		detection_area.body_entered.connect(_on_detection_body_entered)
	if not detection_area.body_exited.is_connected(_on_detection_body_exited):
		detection_area.body_exited.connect(_on_detection_body_exited)


func _scan_for_player() -> void:
	for body: Node2D in detection_area.get_overlapping_bodies():
		if body.is_in_group(&"player"):
			_on_detection_body_entered(body)
			return


func _on_detection_body_entered(body: Node2D) -> void:
	if is_dead or not body.is_in_group(&"player"):
		return
	_chase_target = body
	if state in [State.IDLE, State.PATROL]:
		_change_state(State.CHASE)


func _on_detection_body_exited(body: Node2D) -> void:
	if body != _chase_target:
		return
	_chase_target = null
	if state in [State.CHASE, State.TELEGRAPH]:
		_attack_controller.cancel()
		_change_state(State.IDLE)


func _die() -> void:
	is_dead = true
	_hurt_generation += 1
	_attack_controller.cancel()
	contact_hitbox.deactivate()
	_change_state(State.DEAD)
	died.emit()
	var manager := get_node_or_null("/root/GameManager")
	if manager != null and score_value > 0:
		manager.call(&"add_score", score_value)
	_spawn_explosion_vfx()
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.call(&"play_sfx", &"explosion", global_position, -2.0)
	set_physics_process(false)
	body_collision.set_deferred("disabled", true)
	hurtbox.set_invincible(true)
	var selected_death := _play_first_available(_death_candidates())
	if not selected_death.is_empty() and not sprite.sprite_frames.get_animation_loop(selected_death):
		await sprite.animation_finished
	queue_free()


func _spawn_explosion_vfx() -> void:
	var vfx := get_node_or_null("/root/VFXSpawner")
	if vfx != null:
		vfx.call(&"spawn_one_shot", SMOKE_VFX, global_position + Vector2(0.0, -22.0))
		vfx.call(&"spawn_effect", &"explosion_ring", global_position + Vector2(0.0, -22.0))


func _apply_library_configuration() -> void:
	var info := _get_enemy_info()
	if info.is_empty():
		return
	archetype = StringName(info.get("archetype", archetype))
	max_health = int(info.get("max_health", max_health))
	attack_damage = int(info.get("attack_damage", attack_damage))
	attack_range = float(info.get("attack_range", attack_range))
	attack_cooldown = float(info.get("attack_cooldown", attack_cooldown))
	chase_speed = float(info.get("chase_speed", chase_speed))
	var body_size: Array = info.get("body_size", [])
	if body_size.size() == 2 and body_collision.shape is RectangleShape2D:
		(body_collision.shape as RectangleShape2D).size = Vector2(float(body_size[0]), float(body_size[1]))


func _idle_candidates() -> Array[StringName]:
	return [&"idle", &"idle_walk", movement_animation]


func _movement_candidates() -> Array[StringName]:
	return [movement_animation, &"run", &"walk", &"move", &"flying", &"idle"]


func _attack_candidates() -> Array[StringName]:
	return [&"attack", &"attack_1", &"attack1", &"fwd_swing", &"full_combo", movement_animation]


func _death_candidates() -> Array[StringName]:
	return [death_animation, &"death", &"die", &"hurt", &"idle"]


func _play_first_available(candidates: Array[StringName]) -> StringName:
	if sprite.sprite_frames == null:
		return &""
	for candidate: StringName in candidates:
		if not candidate.is_empty() and sprite.sprite_frames.has_animation(candidate):
			sprite.play(candidate)
			return candidate
	return &""


func _get_enemy_info() -> Dictionary:
	var registry := get_node_or_null("/root/AssetRegistry")
	return registry.call(&"get_enemy_info", enemy_id) if registry != null else {}


func _get_enemy_sprite_frames(requested_enemy_id: StringName) -> SpriteFrames:
	var registry := get_node_or_null("/root/AssetRegistry")
	if registry == null:
		push_error("EnemyBase requires AssetRegistry.")
		return null
	return registry.call(&"get_enemy_sprite_frames", requested_enemy_id) as SpriteFrames
