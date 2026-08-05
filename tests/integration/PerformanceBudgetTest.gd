extends SceneTree

const STRESS_STAGE := preload("res://Stages/Act4_AbyssalNight/4-4_AbyssalSanctuary/Stage.tscn")
const PROJECTILE_SCENE := preload("res://scenes/systems/security/EnemyProjectile.tscn")

const PROJECTILE_STRESS_COUNT := 64
const VFX_STRESS_COUNT := 32
const MAX_STAGE_NODES := 2000
const MAX_HEADLESS_SECONDS := 10.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(15.0, true, false, true).timeout.connect(func() -> void:
		push_error("Performance budget test timed out.")
		quit(1)
	)
	var started_usec := Time.get_ticks_usec()
	var registry := root.get_node("AssetRegistry")
	assert(registry.get_runtime_indexed_path_count() == 182, "Runtime asset index is incomplete.")
	assert(not registry.has_method(&"_collect_matching_paths"), "Runtime registry still exposes a recursive scan path.")

	var audio_manager := root.get_node("AudioManager")
	var sfx_players := 0
	var music_players := 0
	for child: Node in audio_manager.get_children():
		if child.name.begins_with("SFXPlayer"):
			sfx_players += 1
		elif child.name.begins_with("BGMPlayer"):
			music_players += 1
	assert(sfx_players == 10 and music_players == 2, "Audio player pools are not fixed at 10 SFX and 2 BGM players.")

	var stage := STRESS_STAGE.instantiate()
	root.add_child(stage)
	await physics_frame
	assert(_count_nodes(stage) <= MAX_STAGE_NODES, "Production stress stage exceeds the node budget.")

	var projectile_container := Node2D.new()
	projectile_container.name = "ProjectileStressContainer"
	root.add_child(projectile_container)
	for index in range(PROJECTILE_STRESS_COUNT):
		var projectile := PROJECTILE_SCENE.instantiate() as EnemyProjectile
		projectile.max_lifetime = 0.2
		projectile.position = Vector2(index * 3.0, -1000.0)
		projectile_container.add_child(projectile)
		projectile.launch(Vector2.RIGHT)
	assert(projectile_container.get_child_count() == PROJECTILE_STRESS_COUNT, "Projectile stress setup was incomplete.")

	var vfx_container := Node2D.new()
	vfx_container.name = "VFXStressContainer"
	root.add_child(vfx_container)
	var vfx_spawner := root.get_node("VFXSpawner")
	for index in range(VFX_STRESS_COUNT):
		var effect: Node = vfx_spawner.spawn_effect(&"sparks", Vector2(index * 4.0, -1000.0), Vector2.RIGHT, vfx_container)
		assert(effect != null, "VFX stress setup failed.")
	assert(vfx_container.get_child_count() == VFX_STRESS_COUNT, "VFX stress setup was incomplete.")

	for _frame in range(75):
		await physics_frame
	assert(projectile_container.get_child_count() == 0, "Lifetime-bounded projectiles did not release.")
	assert(vfx_container.get_child_count() == 0, "One-shot VFX did not release.")

	var stage_reference: WeakRef = weakref(stage)
	stage.queue_free()
	projectile_container.queue_free()
	vfx_container.queue_free()
	for _frame in range(3):
		await process_frame
	assert(stage_reference.get_ref() == null, "Stage transition cleanup retained the old production scene.")

	var elapsed_seconds := float(Time.get_ticks_usec() - started_usec) / 1_000_000.0
	assert(elapsed_seconds < MAX_HEADLESS_SECONDS, "Headless stress pass exceeded the regression budget.")
	print(
		"PERFORMANCE_BUDGET_TEST_OK indexed=182 projectiles=",
		PROJECTILE_STRESS_COUNT,
		" vfx=",
		VFX_STRESS_COUNT,
		" elapsed=",
		"%.2f" % elapsed_seconds,
		"s"
	)
	quit()


func _count_nodes(node: Node) -> int:
	var count := 1
	for child: Node in node.get_children():
		count += _count_nodes(child)
	return count
