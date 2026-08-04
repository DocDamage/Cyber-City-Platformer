class_name EnemyBase
extends CharacterBody2D

signal damaged(amount: int, health_remaining: int)
signal died

const GUARD_SHEET := preload("res://assets/Characters/Heroes/Spaceman/Character 60x60(2).png")
const FRAME_SIZE := 60
const IDLE_ROW := 14
const RUN_ROW := 15
const DEATH_ROW := 19

@export var patrol_speed := 70.0
@export var max_health := 3
@export_enum("Left:-1", "Right:1") var starting_direction := -1

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var health := 0
var direction := -1
var is_dead := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var floor_check: RayCast2D = $FloorCheck
@onready var wall_check: RayCast2D = $WallCheck


func _ready() -> void:
	health = max_health
	direction = starting_direction
	_build_sprite_frames()
	_face_direction()
	sprite.play(&"run")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_on_floor() and not floor_check.is_colliding():
		_turn_around()
	elif wall_check.is_colliding():
		_turn_around()

	velocity.x = direction * patrol_speed
	move_and_slide()

	if is_on_wall():
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
	velocity = Vector2.ZERO
	set_physics_process(false)
	body_collision.set_deferred("disabled", true)
	hurtbox.set_deferred("monitorable", false)
	sprite.play(&"death")
	await sprite.animation_finished
	queue_free()


func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, &"idle", IDLE_ROW, 0, 7, 8.0, true)
	_add_animation(frames, &"run", RUN_ROW, 0, 11, 12.0, true)
	_add_animation(frames, &"death", DEATH_ROW, 0, 8, 14.0, false)
	sprite.sprite_frames = frames


func _add_animation(
		frames: SpriteFrames,
		animation_name: StringName,
		row: int,
		first_column: int,
		last_column: int,
		fps: float,
		loops: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loops)
	for column in range(first_column, last_column + 1):
		var frame := AtlasTexture.new()
		frame.atlas = GUARD_SHEET
		frame.region = Rect2(column * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(animation_name, frame)
