extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(25.0, true, false, true).timeout.connect(func() -> void:
		push_error("Campaign scene smoke test timed out.")
		quit(1)
	)
	var registry := root.get_node_or_null("AssetRegistry")
	assert(registry != null, "AssetRegistry autoload is missing.")

	var instantiated_stages := 0
	for act_number in range(1, 5):
		for stage_number in range(1, 6):
			var scene: PackedScene = registry.get_stage_scene(act_number, stage_number)
			var stage := scene.instantiate()
			root.add_child(stage)
			await physics_frame
			assert(is_instance_valid(stage), "Stage %d-%d failed during startup." % [act_number, stage_number])
			if not Vector2i(act_number, stage_number) in [Vector2i(1, 1), Vector2i(2, 1)]:
				for required_node in ["Terrain", "Props", "Hazards", "Enemies", "VFX", "Lighting", "Markers"]:
					assert(stage.has_node(required_node), "Stage %d-%d is missing its %s editor folder." % [act_number, stage_number, required_node])
			stage.free()
			instantiated_stages += 1

	var enemy_library: Dictionary = registry.get_enemy_library()
	var enemies: Array = enemy_library.get("enemies", [])
	var instantiated_enemies := 0
	for enemy_value: Variant in enemies:
		var enemy_info: Dictionary = enemy_value
		var enemy_scene: PackedScene = registry.get_enemy_scene(StringName(enemy_info.get("id", "")))
		var enemy := enemy_scene.instantiate() as EnemyBase
		root.add_child(enemy)
		await process_frame
		assert(enemy.sprite.sprite_frames != null, "Enemy '%s' did not apply its SpriteFrames." % enemy_info.get("id", ""))
		assert(enemy.sprite.sprite_frames.has_animation(enemy.death_animation), "Enemy '%s' has no configured death animation." % enemy_info.get("id", ""))
		enemy.free()
		instantiated_enemies += 1

	var catalog_scene := load("res://Characters/Enemies/EnemyCatalog.tscn") as PackedScene
	var catalog := catalog_scene.instantiate()
	root.add_child(catalog)
	await process_frame
	var catalog_enemy_count := 0
	for child: Node in catalog.get_children():
		if child is EnemyBase:
			catalog_enemy_count += 1
	assert(catalog_enemy_count == 22, "Enemy catalog does not show all 22 supplied packs.")
	catalog.free()

	print("CAMPAIGN_SCENE_SMOKE_TEST_OK stages=", instantiated_stages, " enemies=", instantiated_enemies)
	quit()
