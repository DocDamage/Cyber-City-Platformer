extends CharacterBody2D

const SPEED := 160.0
const ACCELERATION := 1200.0
const FRICTION := 1000.0
const JUMP_VELOCITY := -320.0
const WALL_SLIDE_SPEED := 40.0
const WALL_JUMP_VELOCITY := Vector2(200.0, -280.0)
const ATTACK_LOCK_TIME := 0.28
const MELEE_DAMAGE := 1
const PLAYER_SHEET := preload("res://assets/Characters/Heroes/Female Fighter/Player 96X96 (1).png")
const BULLET_SCENE := preload("res://scenes/Bullet.tscn")

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_wall_sliding := false
var facing_direction := 1.0
var attack_lock := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_detector: RayCast2D = $RayCast2D
@onready var muzzle: Marker2D = $Muzzle
@onready var melee_hitbox: Area2D = $MeleeHitbox


func _ready() -> void:
	_build_sprite_frames()
	sprite.play("Idle")


func _physics_process(delta: float) -> void:
	attack_lock = maxf(attack_lock - delta, 0.0)

	if not is_on_floor():
		velocity.y += gravity * delta

	is_wall_sliding = false
	if not is_on_floor() and is_on_wall() and velocity.y > 0.0:
		is_wall_sliding = true
		velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)

	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_wall_sliding:
			var wall_normal := get_wall_normal()
			velocity.x = wall_normal.x * WALL_JUMP_VELOCITY.x
			velocity.y = WALL_JUMP_VELOCITY.y

	var direction := Input.get_axis("ui_left", "ui_right")
	if not is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		facing_direction = signf(direction)
		sprite.flip_h = direction < 0.0
		wall_detector.target_position.x = 10.0 * facing_direction
		muzzle.position.x = 28.0 * facing_direction
		melee_hitbox.position.x = 26.0 * facing_direction
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	if Input.is_action_just_pressed("attack_melee"):
		attack_lock = ATTACK_LOCK_TIME
		sprite.play("Punch")
		perform_melee_attack()
	elif Input.is_action_just_pressed("attack_shoot"):
		attack_lock = ATTACK_LOCK_TIME
		sprite.play("Shoot")
		shoot_projectile()

	move_and_slide()
	update_animations(direction)


func shoot_projectile() -> void:
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.direction = -1.0 if sprite.flip_h else 1.0
	var projectile_parent := get_tree().current_scene
	if projectile_parent == null:
		projectile_parent = get_parent()
	projectile_parent.add_child(bullet)


func perform_melee_attack() -> void:
	var damaged_enemies := {}
	for area in melee_hitbox.get_overlapping_areas():
		var enemy := area.get_parent()
		if enemy.has_method(&"take_damage") and not damaged_enemies.has(enemy):
			damaged_enemies[enemy] = true
			enemy.call(&"take_damage", MELEE_DAMAGE)


func update_animations(direction: float) -> void:
	if attack_lock > 0.0:
		return
	if is_wall_sliding:
		sprite.play("Defend")
	elif not is_on_floor():
		sprite.play("Jump" if velocity.y < 0.0 else "Fall")
	elif not is_zero_approx(direction):
		sprite.play("Run")
	else:
		sprite.play("Idle")


func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_animation(frames, "Idle", 0, 0, 9, 9.0, true)
	_add_animation(frames, "Punch", 1, 0, 6, 16.0, false)
	_add_animation(frames, "Run", 3, 0, 7, 12.0, true)
	_add_animation(frames, "Jump", 4, 0, 3, 10.0, false)
	_add_animation(frames, "Fall", 4, 4, 7, 10.0, true)
	_add_animation(frames, "Defend", 5, 0, 1, 8.0, true)
	_add_animation(frames, "Shoot", 11, 0, 5, 16.0, false)
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
		frame.atlas = PLAYER_SHEET
		frame.region = Rect2(column * 96, row * 96, 96, 96)
		frames.add_frame(animation_name, frame)
