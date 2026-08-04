extends CharacterBody2D

signal damaged(amount: int, health_remaining: int)
signal died
signal energy_changed(current: float, maximum: float)

const SPEED := 160.0
const ACCELERATION := 1200.0
const FRICTION := 1000.0
const JUMP_VELOCITY := -320.0
const WALL_SLIDE_SPEED := 40.0
const WALL_JUMP_VELOCITY := Vector2(200.0, -280.0)
const ATTACK_LOCK_TIME := 0.28
const MELEE_ACTIVE_TIME := 0.1
const DASH_SPEED := 420.0
const DASH_DURATION := 0.16
const DASH_COST := 30.0
const SHOT_COST := 12.0
const ENERGY_REGENERATION := 22.0
const BULLET_SCENE := preload("res://scenes/Bullet.tscn")
const DUST_VFX := preload("res://scenes/vfx/DustBurst.tscn")

@export var max_health := 5
@export var max_energy := 100.0
@export_range(0.1, 5.0, 0.05) var invincibility_duration := 1.0
@export_range(0.02, 0.5, 0.01) var flash_interval := 0.08

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_wall_sliding := false
var facing_direction := 1.0
var attack_lock := 0.0
var health := 0
var energy := 0.0
var is_invincible := false
var is_dead := false
var dash_time_remaining := 0.0
var _level_scene_path := ""
var _default_spawn := Vector2.ZERO
var _player_sheet: Texture2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var wall_detector: RayCast2D = $RayCast2D
@onready var muzzle: Marker2D = $Muzzle
@onready var melee_hitbox: Hitbox = $MeleeHitbox
@onready var game_camera: DynamicCamera = $Camera2D


func _ready() -> void:
	add_to_group(&"player")
	_default_spawn = global_position
	_level_scene_path = _get_level_scene_path()
	var manager := _game_manager()
	if manager != null:
		manager.call(&"register_player", self, max_health, max_energy, _level_scene_path, _default_spawn)
		health = manager.get("player_health")
		energy = manager.get("player_energy")
	else:
		health = max_health
		energy = max_energy
	_player_sheet = _get_character_texture("Player", "Player 96X96 (1)")
	_build_sprite_frames()
	sprite.play("Idle")
	game_camera.set_facing_direction(facing_direction)


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	attack_lock = maxf(attack_lock - delta, 0.0)
	dash_time_remaining = maxf(dash_time_remaining - delta, 0.0)
	if dash_time_remaining <= 0.0:
		_set_energy(minf(energy + ENERGY_REGENERATION * delta, max_energy))

	if Input.is_action_just_pressed("slide_dash") and dash_time_remaining <= 0.0 and energy >= DASH_COST:
		_start_dash()

	if dash_time_remaining > 0.0:
		velocity = Vector2(facing_direction * DASH_SPEED, 0.0)
		move_and_slide()
		if not was_on_floor and is_on_floor():
			_spawn_dust(Vector2.UP)
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	is_wall_sliding = false
	if not is_on_floor() and is_on_wall() and velocity.y > 0.0:
		is_wall_sliding = true
		velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)

	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			_play_sfx(&"jump")
		elif is_wall_sliding:
			var wall_normal := get_wall_normal()
			velocity.x = wall_normal.x * WALL_JUMP_VELOCITY.x
			velocity.y = WALL_JUMP_VELOCITY.y
			_spawn_dust(-wall_normal)
			_play_sfx(&"jump")

	var direction := Input.get_axis("ui_left", "ui_right")
	if not is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		var new_facing_direction := signf(direction)
		if not is_equal_approx(facing_direction, new_facing_direction):
			facing_direction = new_facing_direction
			game_camera.set_facing_direction(facing_direction)
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
	if not was_on_floor and is_on_floor():
		_spawn_dust(Vector2.UP)
	update_animations(direction)


func shoot_projectile() -> void:
	if energy < SHOT_COST or is_dead:
		return
	_set_energy(energy - SHOT_COST)
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.direction = -1.0 if sprite.flip_h else 1.0
	var projectile_parent := get_tree().current_scene
	if projectile_parent == null:
		projectile_parent = get_parent()
	projectile_parent.add_child(bullet)
	_play_sfx(&"laser", muzzle.global_position, -4.0)


func perform_melee_attack() -> void:
	melee_hitbox.activate(MELEE_ACTIVE_TIME)
	_play_sfx(&"melee", global_position, -5.0)


func take_damage(amount: int) -> bool:
	if is_dead or is_invincible or amount <= 0:
		return false

	health = maxi(health - amount, 0)
	_set_manager_health()
	damaged.emit(amount, health)
	_play_sfx(&"hurt", global_position, -4.0)
	if health == 0:
		_die()
	else:
		_begin_invincibility()
	return true


func _begin_invincibility() -> void:
	is_invincible = true
	hurtbox.set_invincible(true)
	_flash_during_invincibility()


func _flash_during_invincibility() -> void:
	var recovery_end := Time.get_ticks_msec() + int(invincibility_duration * 1000.0)
	var dimmed := false
	while not is_dead and Time.get_ticks_msec() < recovery_end:
		dimmed = not dimmed
		sprite.modulate.a = 0.3 if dimmed else 1.0
		await get_tree().create_timer(flash_interval, true, false, true).timeout

	sprite.modulate.a = 1.0
	if not is_dead:
		is_invincible = false
		hurtbox.set_invincible(false)


func _die() -> void:
	is_dead = true
	is_invincible = false
	velocity = Vector2.ZERO
	hurtbox.set_invincible(true)
	set_physics_process(false)
	died.emit()
	var manager := _game_manager()
	if manager != null:
		manager.call(&"request_respawn", self)


func kill() -> void:
	if is_dead:
		return
	health = 0
	_set_manager_health()
	_die()


func respawn_at(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	health = max_health
	energy = max_energy
	is_dead = false
	is_invincible = false
	dash_time_remaining = 0.0
	sprite.modulate = Color.WHITE
	sprite.visible = true
	hurtbox.set_invincible(false)
	_set_manager_health()
	_set_manager_energy()
	set_physics_process(true)
	sprite.play(&"Idle")


func restore_from_checkpoint() -> void:
	health = max_health
	energy = max_energy
	_set_manager_health()
	_set_manager_energy()


func _start_dash() -> void:
	dash_time_remaining = DASH_DURATION
	attack_lock = DASH_DURATION
	_set_energy(energy - DASH_COST)
	_spawn_dust(Vector2(-facing_direction, 0.0))
	_play_sfx(&"dash", global_position, -4.0)


func _set_energy(value: float) -> void:
	var next_energy := clampf(value, 0.0, max_energy)
	if is_equal_approx(energy, next_energy):
		return
	energy = next_energy
	energy_changed.emit(energy, max_energy)
	_set_manager_energy()


func _spawn_dust(direction: Vector2) -> void:
	var dust := DUST_VFX.instantiate()
	dust.global_position = global_position + Vector2(0.0, 22.0)
	dust.rotation = direction.angle() - Vector2.UP.angle()
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(dust)


func _get_level_scene_path() -> String:
	var node: Node = self
	while node.get_parent() != null and node.get_parent() != get_tree().root:
		node = node.get_parent()
	return node.scene_file_path


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _set_manager_health() -> void:
	var manager := _game_manager()
	if manager != null:
		manager.call(&"set_player_health", health, max_health)


func _set_manager_energy() -> void:
	var manager := _game_manager()
	if manager != null:
		manager.call(&"set_player_energy", energy, max_energy)


func _play_sfx(effect: StringName, sound_position := global_position, volume_db := -5.0) -> void:
	var sound_manager := get_node_or_null("/root/SoundManager")
	if sound_manager != null:
		sound_manager.call(&"play_sfx", effect, sound_position, volume_db)


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
		frame.atlas = _player_sheet
		frame.region = Rect2(column * 96, row * 96, 96, 96)
		frames.add_frame(animation_name, frame)


func _get_character_texture(character_folder: String, texture_name: String) -> Texture2D:
	var registry := get_node_or_null("/root/AssetRegistry")
	if registry == null:
		push_error("Player requires the AssetRegistry autoload.")
		return null
	return registry.call(&"get_character_texture", character_folder, texture_name) as Texture2D
