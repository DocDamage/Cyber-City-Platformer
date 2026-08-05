extends SceneTree

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const ENEMY_SCENE := preload("res://Characters/Enemies/Scenes/goblin.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(8.0, true, false, true).timeout.connect(func() -> void:
		push_error("Encounter lifecycle test timed out.")
		quit(1)
	)
	root.get_node("GameManager").call(&"new_game")
	var arena := Node2D.new()
	root.add_child(arena)
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	player.position = Vector2(-500.0, 0.0)
	arena.add_child(player)
	var enemy := ENEMY_SCENE.instantiate() as EnemyBase
	enemy.position = Vector2(100.0, 0.0)
	arena.add_child(enemy)
	var enemies: Array[EnemyBase] = [enemy]
	var encounter := EncounterController.new()
	encounter.configure(&"lifecycle", Rect2(-50.0, -100.0, 300.0, 200.0), enemies)
	arena.add_child(encounter)
	await physics_frame
	if not _require(not encounter.is_active() and enemy.process_mode == Node.PROCESS_MODE_DISABLED, "Encounter enemies were not dormant before activation."):
		return
	encounter.call(&"_on_body_entered", player)
	await physics_frame
	if not _require(encounter.is_active() and enemy.process_mode != Node.PROCESS_MODE_DISABLED, "Encounter did not activate its enemies."):
		return
	player.died.emit()
	await create_timer(0.8, true, false, true).timeout
	if not _require(not encounter.is_active() and encounter.get_live_enemy_count() == 1, "Encounter did not rebuild after player death."):
		return
	encounter.call(&"_on_body_entered", player)
	await physics_frame
	var rebuilt := encounter.get_live_enemies()[0] as EnemyBase
	rebuilt.take_damage(rebuilt.health)
	for _frame in range(20):
		await process_frame
		if encounter.is_complete():
			break
	if not _require(encounter.is_complete(), "Encounter did not complete after its rebuilt roster was defeated."):
		return
	print("ENCOUNTER_LIFECYCLE_TEST_OK reset=1 complete=true")
	arena.queue_free()
	await process_frame
	quit()


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
