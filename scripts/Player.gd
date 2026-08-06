extends CharacterBody2D

signal damaged(amount: int, health_remaining: int)
signal died
signal energy_changed(current: float, maximum: float)
signal corruption_changed(current: float, maximum: float)
signal state_changed(previous: State, current: State)

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	WALL_SLIDE,
	WALL_JUMP,
	DASH,
	MELEE,
	SHOOT,
	HURT,
	DEAD,
	DISABLED,
	TELEPORT_AIM,
	TELEPORT_THROW,
	TELEPORT_RECOVERY,
	WEAPON_ATTACK,
	CASTING,
	INTERACTION_LOCK,
	CUTSCENE,
	EQUIPMENT_CHANGE,
}

const DUST_VFX := preload("res://scenes/vfx/DustBurst.tscn")

@export_group("Movement")
@export var speed := 180.0
@export var ground_acceleration := 1450.0
@export var ground_friction := 1250.0
@export var air_acceleration := 880.0
@export_range(1.0, 3.0, 0.05) var turn_acceleration_multiplier := 1.7
@export var jump_velocity := -340.0
@export_range(0.5, 1.0, 0.05) var apex_gravity_multiplier := 0.82
@export_range(1.0, 2.5, 0.05) var fall_gravity_multiplier := 1.28
@export_range(10.0, 100.0, 1.0) var apex_velocity_threshold := 38.0
@export_range(200.0, 1200.0, 10.0) var maximum_fall_speed := 620.0
@export var wall_slide_speed := 48.0
@export var wall_jump_velocity := Vector2(220.0, -310.0)
@export_range(0.01, 0.3, 0.01) var coyote_time := 0.12
@export_range(0.01, 0.3, 0.01) var jump_buffer_time := 0.13
@export_range(0.1, 0.9, 0.05) var jump_cut_multiplier := 0.48
@export_range(0.01, 0.5, 0.01) var wall_jump_lock_time := 0.13
@export_range(0.0, 0.25, 0.01) var wall_coyote_time := 0.1
@export_range(0.0, 0.9, 0.05) var controller_deadzone := 0.2
@export_range(0.0, 12.0, 1.0) var corner_correction_pixels := 7.0

@export_group("Combat")
@export var dash_speed := 440.0
@export var dash_duration := 0.16
@export var dash_cost := 18.0
@export_range(0.5, 1.0, 0.05) var dash_exit_momentum := 0.72
@export var shot_cost := 12.0
@export var shot_interval := 0.28
@export var energy_regeneration := 22.0
@export var melee_damage := 1
@export var ranged_damage := 1

@export_group("Survival")
@export var max_health := 5
@export var max_energy := 100.0
@export var max_corruption := 100.0
@export_range(0.1, 5.0, 0.05) var invincibility_duration := 1.0
@export_range(0.02, 0.5, 0.01) var flash_interval := 0.08

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var gravity_multiplier := 1.0
var current_state: State = State.IDLE
var is_wall_sliding := false
var facing_direction := 1.0
var attack_lock := 0.0
var health := 0
var energy := 0.0
var corruption := 0.0
var is_invincible := false
var is_dead := false
var dash_time_remaining := 0.0

var _coyote_remaining := 0.0
var _jump_buffer_remaining := 0.0
var _wall_jump_lock_remaining := 0.0
var _wall_coyote_remaining := 0.0
var _last_wall_normal := Vector2.ZERO
var _hurt_remaining := 0.0
var _action_buffer_remaining := 0.0
var _buffered_action: StringName = &""
var _combo_step := 0
var _footstep_remaining := 0.0
var _level_scene_path := ""
var _default_spawn := Vector2.ZERO
var _last_safe_grounded_position := Vector2.ZERO
var _teleport_recovery_remaining := 0.0
var _dash_started_grounded := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_visual: PlayerVisual = $PlayerVisual
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var wall_detector: RayCast2D = $RayCast2D
@onready var muzzle: Marker2D = $Muzzle
@onready var melee_hitbox: Hitbox = $MeleeHitbox
@onready var combat: PlayerCombatController = $CombatController
@onready var teleport_controller: TeleportController = $TeleportController
@onready var voice_barks: VoiceBarkPlayer = $VoiceBarkPlayer
@onready var game_camera: DynamicCamera = $Camera2D
@onready var wall_slide_dust: GPUParticles2D = $WallSlideDust


func _ready() -> void:
	add_to_group(&"player")
	_default_spawn = global_position
	_level_scene_path = _get_level_scene_path()
	var manager := _game_manager()
	if manager != null:
		manager.call(&"register_player", self, max_health, max_energy, _level_scene_path, _default_spawn)
		max_health = int(manager.get("player_max_health"))
		max_energy = float(manager.get("player_max_energy"))
		health = int(manager.get("player_health"))
		energy = float(manager.get("player_energy"))
	else:
		health = max_health
		energy = max_energy
	var sheet := _get_character_texture("Player", "Player 96X96 (1)")
	sprite.sprite_frames = PlayerAnimationFactory.build(sheet)
	sprite.visible = false
	if manager != null and manager.get("character_profile") is CharacterProfile:
		player_visual.apply_profile(manager.get("character_profile") as CharacterProfile)
		voice_barks.set_voice_profile((manager.get("character_profile") as CharacterProfile).voice_profile_id)
	combat.configure(self, melee_hitbox, muzzle)
	teleport_controller.configure(self)
	_last_safe_grounded_position = global_position
	if manager != null and manager.get("equipment") is EquipmentState:
		combat.set_weapon_family((manager.get("equipment") as EquipmentState).weapon_family_id)
	if manager != null and manager.has_signal("equipment_changed") and not manager.equipment_changed.is_connected(_on_equipment_changed):
		manager.equipment_changed.connect(_on_equipment_changed)
	combat.phase_changed.connect(_on_combat_phase_changed)
	combat.action_finished.connect(_on_combat_action_finished)
	combat.hit_confirmed.connect(_on_hit_confirmed)
	game_camera.set_facing_direction(facing_direction)
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null:
		controller_deadzone = float(settings.call(&"get_setting", &"controller_deadzone", controller_deadzone))
	_set_state(State.IDLE, true)


func _physics_process(delta: float) -> void:
	if current_state in [State.DEAD, State.DISABLED]:
		return
	var was_on_floor := is_on_floor()
	_update_timers(delta, was_on_floor)
	_read_buffered_inputs()
	_regenerate_energy(delta)
	if current_state == State.HURT:
		_update_hurt(delta)
		return
	if current_state == State.TELEPORT_AIM:
		_apply_gravity(delta)
		move_and_slide()
		return
	if current_state == State.TELEPORT_RECOVERY:
		_teleport_recovery_remaining = maxf(_teleport_recovery_remaining - delta, 0.0)
		move_and_slide()
		if is_zero_approx(_teleport_recovery_remaining):
			_update_locomotion_state(0.0)
		return
	if current_state == State.DASH:
		_update_dash(was_on_floor)
		return
	_apply_gravity(delta)
	var direction := _get_move_axis()
	_update_wall_slide()
	_try_consume_jump()
	_update_horizontal_velocity(direction, delta)
	_apply_corner_correction(delta)
	move_and_slide()
	if is_on_floor() and current_state not in [State.HURT, State.DASH, State.TELEPORT_AIM, State.TELEPORT_THROW, State.TELEPORT_RECOVERY]:
		_last_safe_grounded_position = global_position
	if not was_on_floor and is_on_floor():
		_spawn_dust(Vector2.UP)
		_vibrate(0.12, 0.06)
		_play_sfx(&"land", global_position, -8.0)
	_update_footsteps(direction, delta)
	_update_wall_slide_dust()
	if current_state not in [State.MELEE, State.SHOOT, State.WALL_JUMP]:
		_update_locomotion_state(direction)


func request_jump() -> void:
	if current_state in [State.DEAD, State.DISABLED, State.HURT]:
		return
	if current_state == State.DASH:
		if not _dash_started_grounded:
			return
		_end_dash(true)
	elif current_state in [State.MELEE, State.SHOOT]:
		combat.cancel()
	_jump_buffer_remaining = jump_buffer_time
	_try_consume_jump()


func perform_melee_attack() -> bool:
	if current_state in [State.DEAD, State.DISABLED, State.HURT]:
		return false
	if current_state == State.DASH:
		_end_dash(true)
	if combat.is_busy():
		_buffer_action(&"melee")
		return false
	return _start_melee(false)


func shoot_projectile() -> bool:
	if current_state in [State.DEAD, State.DISABLED, State.HURT] or energy < _effective_shot_cost():
		return false
	if current_state == State.DASH:
		_end_dash(true)
	if combat.is_busy():
		_buffer_action(&"shoot")
		return false
	if not combat.start_shot(_effective_ranged_damage(), facing_direction, shot_interval):
		return false
	_set_energy(energy - _effective_shot_cost())
	attack_lock = 0.22
	_set_state(State.SHOOT)
	_play_visual(&"cast_1", true)
	return true


func take_damage(amount: int) -> bool:
	if is_dead or is_invincible or amount <= 0 or current_state == State.DISABLED:
		return false
	health = maxi(health - amount, 0)
	_set_manager_health()
	damaged.emit(amount, health)
	_play_sfx(&"hurt", global_position, -4.0)
	voice_barks.play_bark(&"damage")
	teleport_controller.cancel_all()
	combat.cancel()
	dash_time_remaining = 0.0
	if health == 0:
		_die()
	else:
		velocity = Vector2(-facing_direction * 130.0, -125.0)
		_hurt_remaining = 0.24
		_set_state(State.HURT)
		_begin_invincibility()
	return true


func kill() -> void:
	if is_dead:
		return
	health = 0
	_set_manager_health()
	_die()


func respawn_at(spawn_position: Vector2) -> void:
	combat.cancel()
	teleport_controller.cancel_all()
	global_position = spawn_position
	velocity = Vector2.ZERO
	health = max_health
	energy = max_energy
	corruption = 0.0
	corruption_changed.emit(corruption, max_corruption)
	is_dead = false
	is_invincible = false
	dash_time_remaining = 0.0
	_combo_step = 0
	_buffered_action = &""
	_set_wall_slide_dust(false)
	sprite.modulate = Color.WHITE
	player_visual.set_visual_modulate(Color.WHITE)
	player_visual.visible = true
	hurtbox.set_invincible(false)
	_set_manager_health()
	_set_manager_energy()
	set_physics_process(true)
	_set_state(State.IDLE, true)
	_last_safe_grounded_position = spawn_position


func restore_from_checkpoint() -> void:
	health = max_health
	energy = max_energy
	corruption = 0.0
	_set_manager_health()
	_set_manager_energy()
	corruption_changed.emit(corruption, max_corruption)


func set_gravity_multiplier(value: float) -> void:
	gravity_multiplier = clampf(value, -2.0, 3.0)


func apply_corruption(amount: float) -> void:
	if amount <= 0.0 or is_dead:
		return
	var manager := _game_manager()
	var multiplier := 0.35 if manager != null and manager.abilities.has(&"corruption_resistance") else 1.0
	corruption = clampf(corruption + amount * multiplier, 0.0, max_corruption)
	corruption_changed.emit(corruption, max_corruption)
	if corruption >= max_corruption:
		corruption = max_corruption * 0.55
		corruption_changed.emit(corruption, max_corruption)
		take_damage(1)


func cleanse_corruption(amount := -1.0) -> void:
	corruption = 0.0 if amount < 0.0 else maxf(corruption - amount, 0.0)
	corruption_changed.emit(corruption, max_corruption)


func set_input_disabled(disabled: bool) -> void:
	if disabled:
		combat.cancel()
		teleport_controller.cancel_all()
		velocity = Vector2.ZERO
		_set_state(State.DISABLED)
	else:
		_set_state(State.IDLE)


func get_state_name() -> StringName:
	return StringName(State.keys()[current_state].to_lower())


func get_effective_upgrade_stats() -> Dictionary:
	return {
		"energy_regeneration": _effective_energy_regeneration(),
		"melee_damage": _effective_melee_damage(),
		"ranged_damage": _effective_ranged_damage(),
		"dash_duration": _effective_dash_duration(),
		"dash_cost": _effective_dash_cost(),
	}


func update_animations(direction: float) -> void:
	if current_state not in [State.MELEE, State.SHOOT, State.HURT, State.DEAD, State.DISABLED, State.DASH]:
		_update_locomotion_state(direction)


func _update_timers(delta: float, was_on_floor: bool) -> void:
	attack_lock = maxf(attack_lock - delta, 0.0)
	dash_time_remaining = maxf(dash_time_remaining - delta, 0.0)
	_wall_jump_lock_remaining = maxf(_wall_jump_lock_remaining - delta, 0.0)
	_wall_coyote_remaining = maxf(_wall_coyote_remaining - delta, 0.0)
	_jump_buffer_remaining = maxf(_jump_buffer_remaining - delta, 0.0)
	_action_buffer_remaining = maxf(_action_buffer_remaining - delta, 0.0)
	if is_zero_approx(_action_buffer_remaining):
		_buffered_action = &""
	_coyote_remaining = coyote_time if was_on_floor else maxf(_coyote_remaining - delta, 0.0)


func _read_buffered_inputs() -> void:
	if Input.is_action_just_pressed(&"teleport"):
		teleport_controller.handle_teleport_pressed()
	if Input.is_action_just_released(&"teleport"):
		teleport_controller.handle_teleport_released()
	if Input.is_action_just_pressed(&"teleport_cancel"):
		teleport_controller.cancel_all()
	if Input.is_action_just_pressed(&"ui_accept"):
		request_jump()
	if Input.is_action_just_released(&"ui_accept") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier
	if Input.is_action_just_pressed(&"slide_dash"):
		_start_dash()
	if Input.is_action_just_pressed(&"attack_melee"):
		perform_melee_attack()
	elif Input.is_action_just_pressed(&"attack_shoot"):
		shoot_projectile()


func _try_consume_jump() -> bool:
	if is_zero_approx(_jump_buffer_remaining):
		return false
	if not is_on_floor() and (is_wall_sliding or is_on_wall() or _wall_coyote_remaining > 0.0):
		var wall_normal := get_wall_normal() if is_on_wall() else _last_wall_normal
		if wall_normal.is_zero_approx():
			return false
		velocity = Vector2(wall_normal.x * wall_jump_velocity.x, wall_jump_velocity.y)
		_wall_jump_lock_remaining = wall_jump_lock_time
		_wall_coyote_remaining = 0.0
		_jump_buffer_remaining = 0.0
		is_wall_sliding = false
		_set_state(State.WALL_JUMP)
		_spawn_dust(-wall_normal)
		_play_sfx(&"jump")
		return true
	if is_on_floor() or _coyote_remaining > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_remaining = 0.0
		_coyote_remaining = 0.0
		_set_state(State.JUMP)
		_play_sfx(&"jump")
		return true
	return false


func _start_dash() -> bool:
	if current_state in [State.DEAD, State.DISABLED, State.HURT] or dash_time_remaining > 0.0:
		return false
	if current_state in [State.MELEE, State.SHOOT] and not combat.can_movement_cancel():
		return false
	var cost := _effective_dash_cost()
	if energy < cost:
		return false
	combat.cancel()
	_dash_started_grounded = is_on_floor()
	dash_time_remaining = _effective_dash_duration()
	attack_lock = dash_time_remaining
	_set_energy(energy - cost)
	velocity = Vector2(facing_direction * dash_speed, 0.0)
	_set_state(State.DASH)
	_spawn_dust(Vector2(-facing_direction, 0.0))
	_play_sfx(&"dash", global_position, -4.0)
	return true


func _update_dash(was_on_floor: bool) -> void:
	_set_wall_slide_dust(false)
	velocity = Vector2(facing_direction * dash_speed, 0.0)
	move_and_slide()
	if is_on_wall() or dash_time_remaining <= 0.0:
		_end_dash(false)
	if not was_on_floor and is_on_floor():
		_spawn_dust(Vector2.UP)


func _end_dash(preserve_momentum: bool) -> void:
	if current_state != State.DASH:
		return
	dash_time_remaining = 0.0
	# Airborne dash routes need a readable follow-through arc; grounded exits
	# settle closer to run speed so they still feel controllable in corridors.
	var exit_speed := speed * (1.65 if not is_on_floor() else (1.24 if preserve_momentum else 1.12))
	velocity.x = clampf(velocity.x * dash_exit_momentum, -exit_speed, exit_speed)
	_dash_started_grounded = false
	_update_locomotion_state(_get_move_axis())


func _update_hurt(delta: float) -> void:
	_hurt_remaining = maxf(_hurt_remaining - delta, 0.0)
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, ground_friction * 0.45 * delta)
	move_and_slide()
	if is_zero_approx(_hurt_remaining):
		_update_locomotion_state(0.0)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor() or gravity_multiplier < 0.0:
		var shaped_multiplier := gravity_multiplier
		if gravity_multiplier > 0.0:
			if absf(velocity.y) <= apex_velocity_threshold:
				shaped_multiplier *= apex_gravity_multiplier
			elif velocity.y > 0.0:
				shaped_multiplier *= fall_gravity_multiplier
		velocity.y = minf(velocity.y + gravity * shaped_multiplier * delta, maximum_fall_speed)


func _apply_corner_correction(delta: float) -> void:
	if velocity.y >= -apex_velocity_threshold or corner_correction_pixels <= 0.0:
		return
	var upward_motion := Vector2(0.0, velocity.y * delta)
	if not test_move(global_transform, upward_motion):
		return
	var preferred := signf(_get_move_axis())
	for distance: int in range(1, int(corner_correction_pixels) + 1):
		for direction: float in ([preferred, -preferred] if not is_zero_approx(preferred) else [1.0, -1.0]):
			var offset := Vector2(direction * float(distance), 0.0)
			if not test_move(global_transform.translated(offset), upward_motion):
				global_position += offset
				return


func _update_wall_slide() -> void:
	is_wall_sliding = gravity_multiplier > 0.0 and not is_on_floor() and is_on_wall() and velocity.y > 0.0
	if not is_on_floor() and is_on_wall():
		_last_wall_normal = get_wall_normal()
		_wall_coyote_remaining = wall_coyote_time
	if is_wall_sliding:
		velocity.y = minf(velocity.y, wall_slide_speed)
		if current_state not in [State.MELEE, State.SHOOT]:
			_set_state(State.WALL_SLIDE)


func _update_horizontal_velocity(direction: float, delta: float) -> void:
	if _wall_jump_lock_remaining > 0.0:
		return
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	if not is_zero_approx(direction):
		if not is_zero_approx(velocity.x) and signf(velocity.x) != signf(direction):
			acceleration *= turn_acceleration_multiplier if is_on_floor() else lerpf(1.0, turn_acceleration_multiplier, 0.45)
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		_set_facing(direction)
	else:
		var friction := ground_friction if is_on_floor() else air_acceleration * 0.28
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _update_footsteps(direction: float, delta: float) -> void:
	_footstep_remaining = maxf(_footstep_remaining - delta, 0.0)
	if not is_on_floor() or absf(direction) < controller_deadzone or absf(velocity.x) < 45.0:
		return
	if is_zero_approx(_footstep_remaining):
		_play_sfx(&"footstep", global_position, -13.0)
		_footstep_remaining = 0.32


func _get_move_axis() -> float:
	var direction := Input.get_axis(&"ui_left", &"ui_right")
	return 0.0 if absf(direction) < controller_deadzone else direction


func _set_facing(direction: float) -> void:
	var next_facing := signf(direction)
	if is_zero_approx(next_facing) or is_equal_approx(facing_direction, next_facing):
		return
	facing_direction = next_facing
	game_camera.set_facing_direction(facing_direction)
	sprite.flip_h = facing_direction < 0.0
	player_visual.set_facing_left(facing_direction < 0.0)
	wall_detector.target_position.x = 10.0 * facing_direction
	muzzle.position.x = 28.0 * facing_direction
	melee_hitbox.position.x = 26.0 * facing_direction


func _update_locomotion_state(direction: float) -> void:
	if not is_on_floor():
		if is_wall_sliding:
			_set_state(State.WALL_SLIDE)
		elif velocity.y < 0.0:
			_set_state(State.JUMP)
		else:
			_set_state(State.FALL)
	elif is_zero_approx(direction):
		_set_state(State.IDLE)
	else:
		_set_state(State.RUN)


func _start_melee(chain: bool) -> bool:
	var airborne := not is_on_floor()
	_combo_step = 1 if airborne or not chain else mini(_combo_step + 1, 3)
	var damage := _effective_melee_damage() + (1 if airborne or _combo_step == 3 else 0)
	if not combat.start_melee(airborne, _combo_step, damage, facing_direction):
		return false
	attack_lock = 0.45
	_set_state(State.MELEE, current_state == State.MELEE)
	_play_visual((&"air_attack_1" if airborne else StringName("attack_%d" % _combo_step)), true)
	if _combo_step == 1:
		voice_barks.play_bark(&"grunting")
	return true


func _buffer_action(action: StringName) -> void:
	_buffered_action = action
	_action_buffer_remaining = 0.22


func _on_combat_phase_changed(phase: StringName) -> void:
	if phase == &"active":
		if current_state == State.MELEE:
			_play_sfx(&"melee", global_position, -5.0)
		elif current_state == State.SHOOT:
			_play_sfx(&"laser", muzzle.global_position, -4.0)


func _on_combat_action_finished(kind: StringName) -> void:
	attack_lock = 0.0
	if not _buffered_action.is_empty() and _action_buffer_remaining > 0.0:
		var next_action := _buffered_action
		_buffered_action = &""
		_action_buffer_remaining = 0.0
		if next_action == &"melee" and kind == &"melee" and not is_dead:
			if _start_melee(true):
				return
		elif next_action == &"shoot" and shoot_projectile():
			return
	_combo_step = 0
	_update_locomotion_state(_get_move_axis())


func _on_hit_confirmed(_target: Node) -> void:
	_vibrate(0.38, 0.1)


func _set_state(next_state: State, force := false) -> void:
	if not force and current_state == next_state:
		return
	var previous := current_state
	current_state = next_state
	match current_state:
		State.IDLE: _play_visual(&"idle")
		State.RUN: _play_visual(&"run")
		State.JUMP, State.WALL_JUMP: _play_visual(&"jump")
		State.FALL: _play_visual(&"fall")
		State.WALL_SLIDE: _play_visual(&"block")
		State.DASH: _play_visual(&"dash", true)
		State.HURT: _play_visual(&"hurt", true)
		State.DEAD: _play_visual(&"dying", true)
		State.MELEE, State.WEAPON_ATTACK: pass
		State.SHOOT, State.CASTING: _play_visual(&"cast_1", true)
		State.TELEPORT_AIM: _play_visual(&"cast_loop_2")
		State.TELEPORT_THROW: _play_visual(&"cast_2", true)
		State.TELEPORT_RECOVERY: _play_visual(&"roll", true)
		State.DISABLED, State.INTERACTION_LOCK, State.CUTSCENE, State.EQUIPMENT_CHANGE: _play_visual(&"idle")
	state_changed.emit(previous, current_state)


func _begin_invincibility() -> void:
	is_invincible = true
	hurtbox.start_invincibility(invincibility_duration)
	_flash_during_invincibility()


func _flash_during_invincibility() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and bool(settings.call(&"get_setting", &"reduced_flashing", false)):
		await get_tree().create_timer(invincibility_duration, true, false, true).timeout
		if not is_dead:
			is_invincible = false
			hurtbox.set_invincible(false)
		return
	var recovery_end := Time.get_ticks_msec() + int(invincibility_duration * 1000.0)
	var dimmed := false
	while not is_dead and Time.get_ticks_msec() < recovery_end:
		dimmed = not dimmed
		var alpha := 0.3 if dimmed else 1.0
		sprite.modulate.a = alpha
		player_visual.modulate.a = alpha
		await get_tree().create_timer(flash_interval, true, false, true).timeout
	sprite.modulate.a = 1.0
	player_visual.modulate.a = 1.0
	if not is_dead:
		is_invincible = false
		hurtbox.set_invincible(false)


func _die() -> void:
	is_dead = true
	is_invincible = false
	velocity = Vector2.ZERO
	combat.cancel()
	teleport_controller.cancel_all()
	hurtbox.set_invincible(true)
	_set_wall_slide_dust(false)
	_set_state(State.DEAD)
	died.emit()
	set_physics_process(false)
	var manager := _game_manager()
	if manager != null:
		manager.call(&"request_respawn", self)


func _regenerate_energy(delta: float) -> void:
	if current_state != State.DASH:
		_set_energy(minf(energy + _effective_energy_regeneration() * delta, max_energy))


func _set_energy(value: float) -> void:
	var next_energy := clampf(value, 0.0, max_energy)
	if is_equal_approx(energy, next_energy):
		return
	energy = next_energy
	energy_changed.emit(energy, max_energy)
	_set_manager_energy()


func _effective_energy_regeneration() -> float:
	return energy_regeneration + _upgrade_level(&"energy_regeneration") * 4.0


func _effective_melee_damage() -> int:
	var definition := WeaponCatalog.family(combat.get_weapon_family())
	return maxi(int(definition.get("base_damage", melee_damage)), 1) + _upgrade_level(&"melee_damage")


func _effective_ranged_damage() -> int:
	return ranged_damage + _upgrade_level(&"ranged_damage")


func _effective_dash_duration() -> float:
	return dash_duration + _upgrade_level(&"dash_distance") * 0.025


func _effective_dash_cost() -> float:
	return maxf(dash_cost - _upgrade_level(&"dash_efficiency") * 3.0, 12.0)


func _effective_shot_cost() -> float:
	return WeaponCatalog.technique_cost(combat.get_weapon_family())


func _upgrade_level(upgrade_id: StringName) -> int:
	var manager := _game_manager()
	if manager != null and manager.has_method(&"get_upgrade_level"):
		return int(manager.call(&"get_upgrade_level", upgrade_id))
	return 0


func _spawn_dust(direction: Vector2) -> void:
	var vfx := get_node_or_null("/root/VFXSpawner")
	if vfx != null:
		vfx.call(&"spawn_one_shot", DUST_VFX, global_position + Vector2(0.0, 22.0), direction)


func _update_wall_slide_dust() -> void:
	_set_wall_slide_dust(is_wall_sliding and not is_dead)
	if wall_slide_dust.emitting:
		wall_slide_dust.position.x = -get_wall_normal().x * 13.0


func _set_wall_slide_dust(value: bool) -> void:
	if wall_slide_dust != null:
		wall_slide_dust.emitting = value


func _vibrate(strength: float, duration: float) -> void:
	if Input.get_connected_joypads().is_empty() or DisplayServer.get_name() == "headless":
		return
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method(&"get_setting") and not bool(settings.call(&"get_setting", &"controller_vibration")):
		return
	var scale := float(settings.call(&"get_setting", &"controller_vibration_strength", 1.0)) if settings != null else 1.0
	if scale <= 0.0:
		return
	Input.start_joy_vibration(Input.get_connected_joypads()[0], strength * scale, strength * scale, duration)


func _play_sfx(effect: StringName, sound_position := global_position, volume_db := -5.0) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.call(&"play_sfx", effect, sound_position, volume_db)


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


func _get_character_texture(character_folder: String, texture_name: String) -> Texture2D:
	var registry := get_node_or_null("/root/AssetRegistry")
	if registry == null:
		push_error("Player requires the AssetRegistry autoload.")
		return null
	return registry.call(&"get_character_texture", character_folder, texture_name) as Texture2D


func refresh_character_visual() -> void:
	var manager := _game_manager()
	if manager != null and manager.get("character_profile") is CharacterProfile:
		player_visual.apply_profile(manager.get("character_profile") as CharacterProfile)


func enter_teleport_aim() -> void:
	if current_state in [State.DEAD, State.DISABLED, State.HURT, State.CUTSCENE, State.INTERACTION_LOCK]:
		return
	combat.cancel()
	velocity.x = 0.0
	_set_state(State.TELEPORT_AIM)


func exit_teleport_aim(thrown: bool) -> void:
	if current_state != State.TELEPORT_AIM:
		return
	if thrown:
		_set_state(State.TELEPORT_THROW)
		_play_sfx(&"melee", global_position, -9.0)
	_update_locomotion_state(0.0)


func teleport_to_destination(target: Vector2) -> bool:
	if current_state in [State.DEAD, State.DISABLED, State.HURT, State.CUTSCENE, State.INTERACTION_LOCK]:
		return false
	global_position = target
	velocity = Vector2.ZERO
	_teleport_recovery_remaining = 0.12
	_set_state(State.TELEPORT_RECOVERY)
	_play_sfx(&"dash", global_position, -6.0)
	return true


func get_last_safe_grounded_position() -> Vector2:
	return _last_safe_grounded_position


func _on_equipment_changed(slot_id: StringName, _item_id: String) -> void:
	if slot_id != &"main_weapon":
		return
	var manager := _game_manager()
	if manager != null and manager.get("equipment") is EquipmentState:
		combat.set_weapon_family((manager.get("equipment") as EquipmentState).weapon_family_id)
	refresh_character_visual()


func _play_visual(animation_name: StringName, from_start := false) -> void:
	var legacy_map := {
		&"idle": &"Idle", &"run": &"Run", &"jump": &"Jump", &"fall": &"Fall",
		&"block": &"Defend", &"dash": &"Defend", &"hurt": &"Defend", &"dying": &"Defend",
		&"attack_1": &"Punch", &"attack_2": &"Punch", &"attack_3": &"Punch",
		&"air_attack_1": &"Punch", &"air_attack_2": &"Punch",
		&"cast_1": &"Shoot", &"cast_loop_2": &"Shoot", &"cast_2": &"Shoot", &"roll": &"Defend",
	}
	var legacy_animation: StringName = legacy_map.get(animation_name, &"Idle")
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(legacy_animation):
		sprite.play(legacy_animation)
		if from_start:
			sprite.frame = 0
	player_visual.play_animation(animation_name, from_start)
