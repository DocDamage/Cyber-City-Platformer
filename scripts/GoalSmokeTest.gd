extends SceneTree

const SUBSTAGE_SCENE := preload("res://scenes/Act1_CyberCity/SubStage_1_1.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		push_error("Enemy/combat/HUD smoke test timed out before completion.")
		quit(1)
	)
	var manager := root.get_node("GameManager")
	manager.reset_run()
	var stage := SUBSTAGE_SCENE.instantiate()
	root.add_child(stage)
	for _frame in range(40):
		await physics_frame

	var player := stage.get_node("Player") as CharacterBody2D
	var guard := stage.get_node("Enemies/Cyber Guard Alpha") as EnemyBase
	var target := stage.get_node("Enemies/Cyber Guard Omega") as EnemyBase
	var drone := stage.get_node("Enemies/Security Drone") as EnemyBase
	var hud := stage.get_node("HUD") as CanvasLayer
	assert(player != null and player.is_on_floor(), "StageBase did not spawn the player on mapped terrain.")
	assert(guard != null and guard.is_on_floor(), "Ground patrol did not settle on mapped terrain.")
	assert(drone != null and not drone.uses_gravity, "Security drone was not configured as an airborne patrol.")
	assert(hud.get_node("Layout/StatusPanel/Margin/Readouts/HealthBar") is ProgressBar, "HUD health readout is not a ProgressBar.")
	assert(hud.get_node("Layout/ScorePanel/Margin/Readouts/ScoreLabel") is Label, "HUD score readout is not a Label.")

	player.global_position = Vector2(guard.global_position.x - 120.0, guard.global_position.y)
	player.velocity = Vector2.ZERO
	for _frame in range(4):
		await physics_frame
	assert(guard.state == EnemyBase.State.CHASE, "DetectionArea did not switch the enemy to CHASE.")
	assert(guard.get_chase_target() == player, "CHASE did not retain the detected player target.")

	player.global_position = Vector2(32.0, 448.0)
	player.velocity = Vector2.ZERO
	for _frame in range(6):
		await physics_frame
	assert(guard.state != EnemyBase.State.CHASE, "Enemy did not leave CHASE after the player exited detection.")
	guard.detection_area.set_deferred("monitoring", false)
	await physics_frame

	guard.global_position = Vector2(42.0, 448.0)
	guard.direction = -1
	guard.call(&"_face_direction")
	guard.set_state(EnemyBase.State.PATROL)
	var saw_edge_turn := false
	var starting_direction: int = guard.direction
	for _frame in range(90):
		await physics_frame
		if guard.direction != starting_direction:
			saw_edge_turn = true
	assert(guard.is_on_floor(), "Floor-edge RayCast2D did not keep the patrol on its platform.")
	assert(saw_edge_turn, "Patrol never reversed at an edge or patrol boundary.")

	target.set_physics_process(false)
	player.global_position = target.global_position - Vector2(96.0, 0.0)
	player.velocity = Vector2.ZERO
	player.facing_direction = 1.0
	player.sprite.flip_h = false
	for expected_health in [2, 1, 0]:
		var energy_before: float = player.energy
		player.shoot_projectile()
		assert(player.energy < energy_before, "Projectile did not consume weapon energy.")
		for _frame in range(50):
			await physics_frame
			if not is_instance_valid(target) or target.health <= expected_health:
				break
		assert(not is_instance_valid(target) or target.health == expected_health, "Projectile Hitbox did not damage the enemy Hurtbox.")
		await create_timer(0.14, true, false, true).timeout

	for _frame in range(30):
		await physics_frame
		if not is_instance_valid(target):
			break
	assert(not is_instance_valid(target), "Enemy did not complete its death sequence.")
	assert(manager.current_score == 250, "Enemy defeat did not increment GameManager score.")
	var score_label := hud.get_node("Layout/ScorePanel/Margin/Readouts/ScoreLabel") as Label
	assert(score_label.text == "000250", "HUD score label did not refresh from GameManager.")

	player.invincibility_duration = 0.1
	var starting_health: int = player.health
	assert(player.take_damage(1), "Player rejected initial damage.")
	assert(not player.take_damage(1), "Player accepted damage during invincibility frames.")
	assert(player.hurtbox.is_invincible(), "Hurtbox did not enter invincibility.")
	await create_timer(0.2, true, false, true).timeout
	assert(not player.hurtbox.is_invincible(), "Hurtbox invincibility did not expire.")
	var health_bar := hud.get_node("Layout/StatusPanel/Margin/Readouts/HealthBar") as ProgressBar
	assert(int(health_bar.value) == starting_health - 1, "HUD health bar did not refresh from GameManager.")

	print("GOAL_SMOKE_TEST_OK state=", EnemyBase.State.keys()[guard.state], " score=", manager.current_score)
	stage.queue_free()
	root.get_node("AudioManager").stop_all_sfx()
	await process_frame
	await create_timer(0.2, true, false, true).timeout
	quit()
