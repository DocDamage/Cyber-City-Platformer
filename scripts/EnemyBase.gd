class_name EnemyBase
extends CharacterBody2D

signal damaged(amount: int, health_remaining: int)
signal died

const SMOKE_VFX := preload("res://scenes/vfx/SmokeBurst.tscn")

@export var enemy_id: StringName = &"goblin"
@export var animation_library: SpriteFrames
@export var patrol_speed := 70.0
@export_range(32.0, 1200.0, 1.0) var patrol_distance := 220.0
@export var max_health := 3
@export_enum("Left:-1", "Right:1") var starting_direction := -1
@export var uses_gravity := true
@export var movement_animation: StringName
@export var death_animation: StringName
@export var sprite_visual_scale := Vector2.ONE

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var health := 0
var direction := -1
var is_dead := false
var _patrol_origin_x := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var floor_check: RayCast2D = $FloorCheck
@onready var wall_check: RayCast2D = $WallCheck


func _ready() -> void:
	health = max_health
	direction = starting_direction
	_patrol_origin_x = global_position.x
	if animation_library == null:
		animation_library = _get_enemy_sprite_frames(enemy_id)
	if animation_library != null:
		sprite.sprite_frames = animation_library
	sprite.scale = sprite_visual_scale
	_face_direction()
	_play_first_available(_movement_candidates())


func _physics_process(delta: float) -> void:
	if uses_gravity and not is_on_floor():
		velocity.y += gravity * delta

	if not uses_gravity and (
		(direction > 0 and global_position.x >= _patrol_origin_x + patrol_distance)
		or (direction < 0 and global_position.x <= _patrol_origin_x - patrol_distance)
	):
		_turn_around()
	elif uses_gravity and is_on_floor() and not floor_check.is_colliding():
		_turn_around()
	elif uses_gravity and wall_check.is_colliding():
		_turn_around()

	velocity.x = direction * patrol_speed
	move_and_slide()

	if uses_gravity and is_on_wall():
		_turn_around()


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	health = maxi(health - amount, 0)
	damaged.emit(amount, health)
	if health == 0:
		_die()
	else:
		_flash_damage()


func _turn_around() -> void:
	direction *= -1
	_face_direction()


func _face_direction() -> void:
	sprite.flip_h = direction < 0
	floor_check.position.x = 14.0 * direction
	wall_check.target_position.x = 18.0 * direction


func _flash_damage() -> void:
	sprite.modulate = Color(1.0, 0.25, 0.45)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)


func _die() -> void:
	is_dead = true
	died.emit()
	_spawn_explosion_vfx()
	var sound_manager := get_node_or_null("/root/SoundManager")
	if sound_manager != null:
		sound_manager.call(&"play_sfx", &"explosion", global_position, -2.0)
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
	var smoke := SMOKE_VFX.instantiate()
	smoke.global_position = global_position + Vector2(0.0, -22.0)
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(smoke)


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
