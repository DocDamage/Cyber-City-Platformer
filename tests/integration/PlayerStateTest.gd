extends SceneTree

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const BULLET_SCENE := preload("res://scenes/Player/Bullet.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(12.0, true, false, true).timeout.connect(func() -> void:
		push_error("Player state test timed out.")
		quit(1)
	)
	var manager := root.get_node("GameManager")
	manager.call(&"new_game")
	manager.call(&"award_upgrade", &"max_health", 2)
	manager.call(&"award_upgrade", &"energy_regeneration", 1)
	manager.call(&"award_upgrade", &"melee_damage", 1)

	var arena := Node2D.new()
	arena.name = "PlayerStateArena"
	root.add_child(arena)
	_add_world_block(arena, Vector2(0.0, 100.0), Vector2(140.0, 20.0))
	_add_world_block(arena, Vector2(160.0, 20.0), Vector2(20.0, 180.0))
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	player.position = Vector2(0.0, 58.0)
	arena.add_child(player)
	for _frame in range(30):
		await physics_frame
	if not _require(player.is_on_floor(), "Player did not settle on the production collision shape."):
		return
	if not _require(player.max_health == 7, "Maximum-health upgrade did not affect the player."):
		return
	var stats: Dictionary = player.call(&"get_effective_upgrade_stats")
	if not _require(int(stats.get("melee_damage", 0)) == 2 and float(stats.get("energy_regeneration", 0.0)) == 26.0, "Player upgrades are not measurable."):
		return

	player.call(&"set_input_disabled", true)
	if not _require(player.call(&"get_state_name") == &"disabled" and not player.call(&"perform_melee_attack"), "Disabled player accepted combat input."):
		return
	player.call(&"set_input_disabled", false)
	var energy_before: float = player.energy
	if not _require(player.call(&"shoot_projectile"), "Ready player could not shoot."):
		return
	if not _require(player.call(&"get_state_name") == &"shoot" and player.energy < energy_before, "Shoot state or energy cost is incorrect."):
		return
	await create_timer(0.28, true, false, true).timeout
	if not _require(player.call(&"get_state_name") in [&"idle", &"run"], "Shoot recovery did not return to locomotion."):
		return

	if not _require(player.call(&"perform_melee_attack"), "Ready player could not begin melee."):
		return
	if not _require(player.call(&"get_state_name") == &"melee" and not player.melee_hitbox.is_active(), "Melee startup window is not distinct."):
		return
	await create_timer(0.1, true, false, true).timeout
	if not _require(player.melee_hitbox.is_active(), "Melee hitbox did not activate during active frames."):
		return
	await create_timer(0.35, true, false, true).timeout
	if not _require(not player.melee_hitbox.is_active() and player.call(&"get_state_name") in [&"idle", &"run"], "Melee recovery did not finish cleanly."):
		return

	player.global_position = Vector2(0.0, 62.0)
	player.velocity = Vector2.ZERO
	for _frame in range(3):
		await physics_frame
	player.global_position.x = 76.0
	await physics_frame
	player.call(&"request_jump")
	if not _require(player.velocity.y < 0.0 and player.call(&"get_state_name") == &"jump", "Coyote-time jump was not accepted."):
		return

	player.global_position = Vector2(0.0, 42.0)
	player.velocity = Vector2(0.0, 190.0)
	await physics_frame
	player.call(&"request_jump")
	var buffered_jump_fired := false
	for _frame in range(10):
		await physics_frame
		if player.velocity.y < 0.0:
			buffered_jump_fired = true
			break
	if not _require(buffered_jump_fired, "Buffered jump did not fire on landing."):
		return

	player.global_position = Vector2(0.0, 62.0)
	player.velocity = Vector2.ZERO
	player.facing_direction = 1.0
	for _frame in range(3):
		await physics_frame
	if not _require(player.call(&"_start_dash"), "Player could not begin a funded dash."):
		return
	for _frame in range(20):
		await physics_frame
	if not _require(player.global_position.x < 140.0 and player.call(&"get_state_name") != &"dash", "Dash bypassed the collision wall or failed to end."):
		return

	var temporary_bullet := BULLET_SCENE.instantiate()
	temporary_bullet.set("speed", 0.0)
	temporary_bullet.set("max_lifetime", 0.1)
	arena.add_child(temporary_bullet)
	await create_timer(0.2, true, false, true).timeout
	if not _require(not is_instance_valid(temporary_bullet), "Projectile lifetime did not bound off-screen nodes."):
		return

	player.kill()
	if not _require(player.is_dead and player.call(&"get_state_name") == &"dead", "Player death state is inconsistent."):
		return
	await create_timer(0.75, true, false, true).timeout
	if not _require(not player.is_dead and player.call(&"get_state_name") in [&"idle", &"fall"], "Player did not leave DEAD during checkpoint respawn."):
		return
	print("PLAYER_STATE_TEST_OK max_health=", player.max_health, " dash_x=", player.global_position.x)
	arena.queue_free()
	await process_frame
	quit()


func _add_world_block(parent: Node2D, position: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
