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
			var terrain_layers := stage.find_children("*", "TileMapLayer", true, false)
			assert(not terrain_layers.is_empty(), "Stage %d-%d has no painted TileMapLayer." % [act_number, stage_number])
			var terrain := terrain_layers[0] as TileMapLayer
			assert(not terrain.get_used_cells().is_empty(), "Stage %d-%d has no painted terrain cells." % [act_number, stage_number])
			assert(terrain.tile_set != null and terrain.tile_set.get_physics_layers_count() > 0, "Stage %d-%d terrain has no physics layer." % [act_number, stage_number])
			var props := stage.find_child("Props", true, false)
			assert(props != null and not props.find_children("*", "Sprite2D", true, false).is_empty(), "Stage %d-%d has no layered Sprite2D props." % [act_number, stage_number])
			var checkpoint_count := 0
			for checkpoint: Node in get_nodes_in_group(&"checkpoints"):
				if stage.is_ancestor_of(checkpoint):
					checkpoint_count += 1
			assert(checkpoint_count > 0, "Stage %d-%d has no checkpoint." % [act_number, stage_number])
			var exit_count := 0
			for stage_exit: Node in get_nodes_in_group(&"stage_exits"):
				if stage.is_ancestor_of(stage_exit):
					exit_count += 1
			assert(exit_count == 1, "Stage %d-%d does not have exactly one stage exit." % [act_number, stage_number])
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
