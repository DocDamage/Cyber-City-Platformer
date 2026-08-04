extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(6.0, true, false, true).timeout.connect(func() -> void:
		push_error("Systems smoke test timed out before completion.")
		quit(1)
	)
	var game_manager: Node = root.get_node_or_null("GameManager")
	if game_manager == null:
		game_manager = load("res://scripts/GameManager.gd").new()
		game_manager.name = "GameManager"
		root.add_child(game_manager)
	var sound_manager: Node = root.get_node_or_null("SoundManager")
	if sound_manager == null:
		sound_manager = load("res://scripts/SoundManager.gd").new()
		sound_manager.name = "SoundManager"
		root.add_child(sound_manager)
	if root.get_node_or_null("CombatFeedback") == null:
		var combat_feedback: Node = load("res://scripts/CombatFeedback.gd").new()
		combat_feedback.name = "CombatFeedback"
		root.add_child(combat_feedback)

	var level: Node = load("res://scenes/Level.tscn").instantiate()
	root.add_child(level)
	for frame in range(24):
		await physics_frame

	var player: CharacterBody2D = level.get_node("Player")
	assert(level.get_node("HUD") is CanvasLayer, "HUD is not a screen-space CanvasLayer.")
	assert(game_manager.player_health == player.max_health, "GameManager did not initialize player health.")
	assert(is_equal_approx(game_manager.player_energy, player.max_energy), "GameManager did not initialize player energy.")

	var energy_before: float = player.energy
	player.shoot_projectile()
	assert(player.energy < energy_before, "Shooting did not consume weapon energy.")

	var coin: Area2D = level.get_node("Coin 01")
	player.global_position = coin.global_position
	for frame in range(4):
		await physics_frame
	assert(game_manager.current_score == 100, "Collectible signal did not increment persistent score.")

	var terminal: Area2D = level.get_node("Rooftop Terminal")
	player.global_position = terminal.global_position
	for frame in range(4):
		await physics_frame
	assert(game_manager.current_checkpoint_id == &"rooftop_terminal", "Terminal did not update the checkpoint.")
	assert(game_manager.player_health == player.max_health, "Checkpoint did not restore health.")

	player.kill()
	await create_timer(0.72, true, false, true).timeout
	assert(not player.is_dead, "Player did not respawn after death.")
	assert(player.global_position.distance_to(game_manager.current_checkpoint) < 20.0, "Player did not respawn at the terminal.")
	assert(game_manager.player_health == player.max_health, "Respawn did not restore health.")

	assert(level.get_node("Level Exit").get("next_scene_path") == "res://scenes/Level2.tscn", "Rooftop exit is not linked to Level 2.")
	assert(load("res://scenes/Level2.tscn") != null, "Level 2 could not be loaded.")
	for path in [
		"res://scenes/vfx/SparkBurst.tscn",
		"res://scenes/vfx/DustBurst.tscn",
		"res://scenes/vfx/SmokeBurst.tscn",
	]:
		var effect: Node = load(path).instantiate()
		assert(effect is GPUParticles2D and effect.one_shot, "VFX scene is not a one-shot GPU particle burst: %s" % path)
		effect.free()

	assert(sound_manager.get_node("Effect00") is AudioStreamPlayer2D, "Sound pool does not use positional AudioStreamPlayer2D nodes.")
	var level_exit: Area2D = level.get_node("Level Exit")
	player.global_position = level_exit.global_position
	for frame in range(8):
		await physics_frame
	assert(current_scene != null and current_scene.scene_file_path == "res://scenes/Level2.tscn", "Level exit did not transition to Level 2.")
	print("SYSTEMS_SMOKE_TEST_OK score=", game_manager.current_score, " checkpoint=", game_manager.current_checkpoint)
	quit()
