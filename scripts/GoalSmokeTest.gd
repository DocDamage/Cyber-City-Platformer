extends SceneTree

const LEVEL_SCENE := preload("res://scenes/Level.tscn")
const ENEMY_SCENE := preload("res://scenes/EnemyBase.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	for frame in range(20):
		await physics_frame

	var player: CharacterBody2D = level.get_node("Player")
	var patrol_enemy: CharacterBody2D = level.get_node("Cyber Guard")
	assert(player.is_on_floor(), "Player did not settle on the rooftop TileMap collision.")
	assert(patrol_enemy.is_on_floor(), "Enemy did not settle on the rooftop TileMap collision.")

	var game_camera: DynamicCamera = player.get_node("Camera2D")
	assert(game_camera.position_smoothing_enabled, "Camera position smoothing is not enabled.")
	assert(is_equal_approx(game_camera.position_smoothing_speed, 5.0), "Camera smoothing speed is not 5.0.")

	var melee_target := ENEMY_SCENE.instantiate()
	level.add_child(melee_target)
	melee_target.global_position = Vector2(player.global_position.x + 40.0, 320.0)
	await physics_frame
	player.perform_melee_attack()
	assert(melee_target.health == melee_target.max_health - 1, "Melee hitbox did not damage the enemy hurtbox.")
	assert(is_zero_approx(Engine.time_scale), "Melee impact did not start hit stop.")
	await create_timer(0.08, true, false, true).timeout
	assert(is_equal_approx(Engine.time_scale, 1.0), "Hit stop did not restore the game time scale.")
	melee_target.queue_free()

	player.shoot_projectile()
	player.shoot_projectile()
	player.shoot_projectile()
	for frame in range(60):
		await physics_frame

	assert(not is_instance_valid(patrol_enemy), "Bullets did not finish the enemy death sequence.")

	game_camera.set_facing_direction(-1.0)
	for frame in range(20):
		await process_frame
	assert(game_camera.position.x < 0.0, "Camera look-ahead did not move toward the facing direction.")
	game_camera.set_facing_direction(1.0)
	root.get_node("CombatFeedback").camera_shake(6.0, 0.1)
	await process_frame
	assert(game_camera.offset.length() > 0.0, "Camera shake did not produce a screen offset.")

	player.invincibility_duration = 0.12
	var starting_health: int = player.health
	assert(player.take_damage(1), "Player rejected the initial damage hit.")
	assert(not player.take_damage(1), "Player took damage again during i-frames.")
	assert(player.health == starting_health - 1, "I-frames did not prevent repeated player damage.")
	assert(player.hurtbox.is_invincible(), "Player hurtbox collision remained enabled during recovery.")
	await create_timer(0.25, true, false, true).timeout
	assert(not player.is_invincible, "Player i-frames did not end after the recovery duration.")
	assert(not player.hurtbox.is_invincible(), "Player hurtbox collision was not restored after recovery.")
	player.invincibility_duration = 1.0

	var edge_patrol := ENEMY_SCENE.instantiate()
	level.add_child(edge_patrol)
	edge_patrol.global_position = Vector2(384.0, 318.0)
	var wall_patrol := ENEMY_SCENE.instantiate()
	wall_patrol.starting_direction = 1
	level.add_child(wall_patrol)
	wall_patrol.global_position = Vector2(850.0, 446.0)
	for frame in range(180):
		await physics_frame

	assert(edge_patrol.is_on_floor(), "Edge patrol fell off its rooftop.")
	assert(edge_patrol.direction == 1, "Edge floor check did not reverse patrol direction.")
	assert(wall_patrol.direction == -1, "Wall check did not reverse patrol direction.")
	print("GOAL_SMOKE_TEST_OK player=", player.global_position)
	quit()
