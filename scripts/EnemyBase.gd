class_name EnemyBase
extends CharacterBody2D

signal damaged(amount: int, health_remaining: int)
signal died
signal state_changed(previous: State, current: State)

enum State {
	IDLE,
	PATROL,
	CHASE,
}

const SMOKE_VFX := preload("res://scenes/vfx/SmokeBurst.tscn")

@export var enemy_id: StringName = &"goblin"
@export var animation_library: SpriteFrames
@export_range(0.0, 400.0, 1.0) var patrol_speed := 70.0
@export_range(0.0, 600.0, 1.0) var chase_speed := 115.0
@export_range(32.0, 1200.0, 1.0) var patrol_distance := 220.0
@export_range(0.0, 3.0, 0.05) var idle_duration := 0.55
@export_range(0.0, 96.0, 1.0) var chase_stop_distance := 18.0
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
var _idle_time_remaining := 0.0
var _patrol_origin_x := 0.0
var _chase_target: Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var floor_check: RayCast2D = $FloorCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var detection_area: Area2D = get_node_or_null("DetectionArea") as Area2D


func _ready() -> void:
	health = max_health
	direction = 1 if starting_direction > 0 else -1
	_patrol_origin_x = global_position.x
	if animation_library == null:
		animation_library = _get_enemy_sprite_frames(enemy_id)
	if animation_library != null:
		sprite.sprite_frames = animation_library
	sprite.scale = sprite_visual_scale
	_face_direction()
	_connect_detection_area()
	_change_state(initial_state, true)
	_scan_for_player.call_deferred()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
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
			_update_patrol()
		State.CHASE:
			_update_chase()

	move_and_slide()
	if state == State.PATROL and uses_gravity and is_on_wall():
		_turn_around()
		_change_state(State.IDLE)


func take_damage(amount: int) -> bool:
	if is_dead or amount <= 0:
		return false

	health = maxi(health - amount, 0)
	damaged.emit(amount, health)
	if health == 0:
		_die()
	else:
		_flash_damage()
	return true


func set_state(next_state: State) -> void:
	_change_state(next_state)


func get_chase_target() -> Node2D:
	return _chase_target


func _update_idle(delta: float) -> void:
	velocity.x = 0.0
	if _chase_target != null:
		_change_state(State.CHASE)
		return
	_idle_time_remaining = maxf(_idle_time_remaining - delta, 0.0)
	if is_zero_approx(_idle_time_remaining):
		_change_state(State.PATROL)


func _update_patrol() -> void:
	if _chase_target != null:
		_change_state(State.CHASE)
		return

	if not uses_gravity:
		if (
			(direction > 0 and global_position.x >= _patrol_origin_x + patrol_distance)
			or (direction < 0 and global_position.x <= _patrol_origin_x - patrol_distance)
		):
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

	var horizontal_distance := _chase_target.global_position.x - global_position.x
	if absf(horizontal_distance) <= chase_stop_distance:
		velocity.x = 0.0
		return

	var chase_direction := 1 if horizontal_distance > 0.0 else -1
	if chase_direction != direction:
		direction = chase_direction
		_face_direction()
		floor_check.force_raycast_update()
		wall_check.force_raycast_update()

	# A ground enemy will not chase across an unsupported gap or through a wall.
	if uses_gravity and is_on_floor() and (not floor_check.is_colliding() or wall_check.is_colliding()):
		velocity.x = 0.0
		return
	velocity.x = direction * chase_speed


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
	state_changed.emit(previous, state)


func _turn_around() -> void:
	direction *= -1
	_face_direction()


func _face_direction() -> void:
	sprite.flip_h = direction < 0
	floor_check.position.x = 14.0 * direction
	wall_check.target_position.x = 18.0 * direction


func _connect_detection_area() -> void:
	if detection_area == null:
		return
	if not detection_area.body_entered.is_connected(_on_detection_body_entered):
		detection_area.body_entered.connect(_on_detection_body_entered)
	if not detection_area.body_exited.is_connected(_on_detection_body_exited):
		detection_area.body_exited.connect(_on_detection_body_exited)


func _scan_for_player() -> void:
	if detection_area == null:
		return
	for body in detection_area.get_overlapping_bodies():
		if body is Node2D and body.is_in_group(&"player"):
			_on_detection_body_entered(body)
			return


func _on_detection_body_entered(body: Node2D) -> void:
	if is_dead or not body.is_in_group(&"player"):
		return
	_chase_target = body
	_change_state(State.CHASE)


func _on_detection_body_exited(body: Node2D) -> void:
	if body != _chase_target:
		return
	_chase_target = null
	_change_state(State.IDLE)


func _flash_damage() -> void:
	sprite.modulate = Color(1.0, 0.25, 0.45)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)


func _die() -> void:
	is_dead = true
	died.emit()
	var manager := get_node_or_null("/root/GameManager")
	if manager != null and score_value > 0:
		manager.call(&"add_score", score_value)
	_spawn_explosion_vfx()
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.call(&"play_sfx", &"explosion", global_position, -2.0)
	var feedback := get_node_or_null("/root/CombatFeedback")
	if feedback != null:
		feedback.call(&"camera_shake", 8.0, 0.22)
	velocity = Vector2.ZERO
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


func _idle_candidates() -> Array[StringName]:
	var candidates: Array[StringName] = [&"idle", &"idle_walk"]
	for candidate: StringName in _movement_candidates():
		if not candidates.has(candidate):
			candidates.append(candidate)
	return candidates


func _movement_candidates() -> Array[StringName]:
	var candidates: Array[StringName] = []
	if not movement_animation.is_empty():
		candidates.append(movement_animation)
	for candidate: StringName in [&"run", &"walk", &"move", &"flying", &"idle"]:
		if not candidates.has(candidate):
			candidates.append(candidate)
	return candidates


func _death_candidates() -> Array[StringName]:
	var candidates: Array[StringName] = []
	if not death_animation.is_empty():
		candidates.append(death_animation)
	for candidate: StringName in [&"death", &"die", &"hurt", &"idle"]:
		if not candidates.has(candidate):
			candidates.append(candidate)
	return candidates


func _play_first_available(candidates: Array[StringName]) -> StringName:
	if sprite.sprite_frames == null:
		return &""
	for candidate: StringName in candidates:
		if sprite.sprite_frames.has_animation(candidate):
			sprite.play(candidate)
			return candidate
	var names := sprite.sprite_frames.get_animation_names()
	if not names.is_empty():
		var first: StringName = names[0]
		sprite.play(first)
		return first
	return &""


func _get_enemy_sprite_frames(requested_enemy_id: StringName) -> SpriteFrames:
	var registry := get_node_or_null("/root/AssetRegistry")
	if registry == null:
		push_error("EnemyBase requires the AssetRegistry autoload.")
		return null
	return registry.call(&"get_enemy_sprite_frames", requested_enemy_id) as SpriteFrames
