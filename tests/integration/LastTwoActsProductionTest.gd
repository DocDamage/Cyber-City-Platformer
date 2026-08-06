extends SceneTree

const STAGE_IDS := [
	"3-1", "3-2", "3-3", "3-4", "3-5",
	"4-1", "4-2", "4-3", "4-4", "4-5",
]

const HERO_BACKGROUNDS := {
	"3-1": "res://assets/runtime/environments/Act3_NeonMoon/Generated/lunar_surface_arrival_panorama_v1.png",
	"3-2": "res://assets/runtime/environments/Act3_NeonMoon/Generated/research_cleanrooms_panorama_v1.png",
	"3-3": "res://assets/runtime/environments/Act3_NeonMoon/Generated/security_grid_shaft_panorama_v1.png",
	"3-4": "res://assets/runtime/environments/Act3_NeonMoon/Generated/bio_tech_labs_panorama_v1.png",
	"3-5": "res://assets/runtime/environments/Act3_NeonMoon/Generated/orbital_command_panorama_v1.png",
	"4-1": "res://assets/runtime/environments/Act4_AbyssalNight/Generated/corrupted_outpost_panorama_v1.png",
	"4-2": "res://assets/runtime/environments/Act4_AbyssalNight/Generated/the_dark_chasm_panorama_v1.png",
	"4-3": "res://assets/runtime/environments/Act4_AbyssalNight/Generated/bio_mechanical_nest_panorama_v1.png",
	"4-4": "res://assets/runtime/environments/Act4_AbyssalNight/Generated/abyssal_sanctuary_panorama_v1.png",
	"4-5": "res://assets/runtime/environments/Act4_AbyssalNight/Generated/heart_of_the_void_panorama_v1.png",
}

const EXPECTED_ENVIRONMENTS := {
	"3-1": "neon_moon", "3-2": "neon_moon", "3-3": "neon_moon", "3-4": "neon_moon", "3-5": "neon_moon",
	"4-1": "abyssal_night", "4-2": "abyssal_night", "4-3": "abyssal_night", "4-4": "abyssal_night", "4-5": "abyssal_night",
}

const EXPECTED_ARCHITECTURES := {
	"3-1": ["lunar_crater_walk", "lunar_crater_span"],
	"3-2": ["lunar_cleanroom_airlock", "lunar_observation_spine"],
	"3-3": ["lunar_security_shaft", "lunar_orbital_lift"],
	"3-4": ["biotech_gravity_bridge", "biotech_containment_bypass"],
	"4-1": ["outpost_ruin_steps", "outpost_corruption_lift"],
	"4-2": ["chasm_cable_lifts", "chasm_shadow_bridge"],
	"4-3": ["nest_rib_walk", "nest_brood_bypass"],
	"4-4": ["sanctuary_mastery_steps", "sanctuary_void_carriage"],
}

const EXPECTED_STATIC_ASSEMBLIES := {
	"3-1": 3, "3-2": 3, "3-3": 3, "3-4": 3, "3-5": 2,
	"4-1": 3, "4-2": 3, "4-3": 3, "4-4": 3, "4-5": 2,
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(60.0, true, false, true).timeout.connect(func() -> void:
		push_error("Last two acts production test timed out.")
		quit(1)
	)
	var registry := root.get_node("AssetRegistry")
	var manager := root.get_node("GameManager")
	manager.call(&"new_game")
	var metadata_by_id := _metadata_by_id(registry.call(&"get_campaign_manifest") as Dictionary)
	var completed := 0
	var hero_paths := {}
	var deck_count := 0
	var static_assemblies := 0
	for index: int in range(STAGE_IDS.size()):
		var stage_id: String = STAGE_IDS[index]
		if not _require(metadata_by_id.has(stage_id), "Missing latter-act manifest entry %s." % stage_id):
			return
		var metadata := metadata_by_id[stage_id] as Dictionary
		var scene_path := String(metadata.get("scene", ""))
		var stage := (load(scene_path) as PackedScene).instantiate() as StageBase
		root.add_child(stage)
		for _frame: int in range(4):
			await process_frame
			await physics_frame
		var controller := stage.runtime_controller
		var exit := stage.get_stage_exit()
		if not _require(stage is CampaignStage and controller != null and exit != null, "Stage %s did not initialize its campaign controller and exit." % stage_id):
			return
		var campaign_stage := stage as CampaignStage
		var expected_background := String(HERO_BACKGROUNDS[stage_id])
		if not _require(campaign_stage.use_layer_tints and campaign_stage.far_background != null and campaign_stage.far_background.resource_path == expected_background, "Stage %s does not use its dedicated hero panorama." % stage_id):
			return
		if not _require(campaign_stage.far_background.get_width() >= 1600 and campaign_stage.far_background.get_height() >= 900, "Stage %s hero panorama is below the HD production floor." % stage_id):
			return
		var far_sprite := stage.get_node_or_null("Background/Far/FarSprite") as Sprite2D
		var middle_sprite := stage.get_node_or_null("Background/Middle/MiddleSprite") as Sprite2D
		var front_sprite := stage.get_node_or_null("Background/Front/FrontSprite") as Sprite2D
		if not _require(far_sprite != null and far_sprite.texture == campaign_stage.far_background and middle_sprite != null and front_sprite != null and middle_sprite.modulate.a > 0.0 and middle_sprite.modulate.a <= 0.35 and front_sprite.modulate.a > 0.0 and front_sprite.modulate.a <= 0.35, "Stage %s does not preserve a restrained depth overlay above its panorama." % stage_id):
			return
		if stage_id == "3-3" and not _require(campaign_stage.background_coverage_size.y >= 900.0, "Security Grid Shaft does not overscan its vertical hero background."):
			return
		hero_paths[expected_background] = true

		var expected_environment := String(EXPECTED_ENVIRONMENTS[stage_id])
		var presentation := stage.get_presentation_container().get_node_or_null("StageArchitectureDressing") as Node2D
		var stage_assemblies := _regional_assembly_count(presentation, expected_environment)
		if not _require(stage_assemblies == int(EXPECTED_STATIC_ASSEMBLIES[stage_id]), "Stage %s expected %d collision-bound regional assemblies, found %d." % [stage_id, int(EXPECTED_STATIC_ASSEMBLIES[stage_id]), stage_assemblies]):
			return
		static_assemblies += stage_assemblies
		var expected_architectures := EXPECTED_ARCHITECTURES.get(stage_id, []) as Array
		if expected_architectures.is_empty():
			if not _require(controller.authored_traversal.is_empty(), "Boss stage %s unexpectedly installed traversal sections." % stage_id):
				return
		else:
			if not _require(controller.authored_traversal.size() == expected_architectures.size(), "Stage %s does not expose its authored traversal count." % stage_id):
				return
			for section: AuthoredTraversal in controller.authored_traversal:
				if not _require(String(section.environment_id) == expected_environment and String(section.architecture_id) in expected_architectures, "Stage %s traversal %s borrows a legacy-act architecture." % [stage_id, section.section_id]):
					return
				var architecture := section.get_node_or_null("Architecture") as Node2D
				if not _require(_regional_assembly_count(architecture, expected_environment) == 1, "Stage %s traversal %s is missing its region-native architectural assembly." % [stage_id, section.section_id]):
					return
				deck_count += _deck_count(section)
		if not await _verify_spawn_controls(stage, stage_id):
			return

		var completion := metadata.get("completion_target", {}) as Dictionary
		var is_boss_stage := String(completion.get("type", "")) == "boss"
		var expected_lock_text := "DEFEAT BOSS" if is_boss_stage else "CLEAR ENCOUNTERS"
		var exit_label := exit.get_node_or_null("Label") as Label
		if not _require(exit.is_locked and exit_label != null and exit_label.text == expected_lock_text, "Stage %s does not present its objective lock." % stage_id):
			return
		if not _require(stage.get_checkpoints_container().get_child_count() >= int(metadata.get("expected_checkpoints", 1)) and stage.get_collectibles_container().get_child_count() == int(metadata.get("collectible_count", 0)), "Stage %s checkpoint or collectible budget did not reach runtime." % stage_id):
			return
		var expected_next := ""
		if index + 1 < STAGE_IDS.size():
			expected_next = String((metadata_by_id[STAGE_IDS[index + 1]] as Dictionary).get("scene", ""))
		if not _require(exit.next_scene_path == expected_next, "Stage %s does not hand off to the next authored stage or finale." % stage_id):
			return
		if is_boss_stage:
			var boss := stage.get_boss()
			if not _require(boss != null and boss.get_attack_roster().size() >= 3, "Boss stage %s lacks a production boss roster." % stage_id):
				return
			boss.start_encounter()
			boss.complete_intro()
			boss.take_damage(boss.health)
			await process_frame
		else:
			controller.complete_objectives_for_test()
		if not _require(not exit.is_locked and exit_label.text == "STAGE EXIT", "Stage %s did not unlock its exit on completion." % stage_id):
			return
		manager.call(&"complete_stage", stage_id)
		completed += 1
		stage.queue_free()
		await process_frame
	if not _require(completed == 10 and hero_paths.size() == 10 and deck_count >= 32 and static_assemblies == 28, "The latter acts lack complete, distinct panoramas and regional traversal dressing."):
		return
	manager.call(&"_finish_campaign")
	for _frame: int in range(90):
		await process_frame
		if current_scene != null and current_scene.scene_file_path == "res://scenes/ui/EndingScreen.tscn":
			break
	if not _require(manager.campaign_progress.campaign_complete and current_scene != null and current_scene.scene_file_path == "res://scenes/ui/EndingScreen.tscn", "The last two acts do not complete into the ending flow."):
		return
	print("LAST_TWO_ACTS_PRODUCTION_TEST_OK stages=", completed, " panoramas=", hero_paths.size(), " traversal_decks=", deck_count, " regional_assemblies=", static_assemblies, " ending=true")
	quit()


func _metadata_by_id(manifest: Dictionary) -> Dictionary:
	var result := {}
	for act_value: Variant in manifest.get("acts", []):
		for stage_value: Variant in (act_value as Dictionary).get("stages", []):
			var metadata := stage_value as Dictionary
			var stage_id := String(metadata.get("id", ""))
			if stage_id.begins_with("3-") or stage_id.begins_with("4-"):
				result[stage_id] = metadata
	return result


func _regional_assembly_count(parent: Node, expected_environment: String) -> int:
	if parent == null:
		return 0
	var count := 0
	for child: Node in parent.get_children():
		if String(child.get_meta(&"environment_id", "")) == expected_environment and String(child.get_meta(&"asset_id", "")).begins_with("procedural_"):
			count += 1
	return count


func _deck_count(section: AuthoredTraversal) -> int:
	var count := 0
	for child: Node in section.get_children():
		if child is StaticBody2D and child.get_node_or_null("DeckArt/SurfaceTiles") is TerrainSurfaceArt:
			count += 1
	return count


func _verify_spawn_controls(stage: StageBase, stage_id: String) -> bool:
	var player := stage.get_player() as CharacterBody2D
	if not _require(player != null, "Stage %s did not create a controllable player." % stage_id):
		return false
	_release_inputs()
	for _frame: int in range(24):
		await physics_frame
		if player.is_on_floor():
			break
	if not _require(player.is_on_floor(), "Stage %s player did not settle on authored entry collision." % stage_id):
		return false
	var start_x := player.global_position.x
	Input.action_press(&"ui_right")
	for _frame: int in range(12):
		await physics_frame
	Input.action_release(&"ui_right")
	if not _require(player.global_position.x >= start_x + 8.0, "Stage %s player did not respond to entry movement." % stage_id):
		return false
	for _frame: int in range(12):
		await physics_frame
		if player.is_on_floor():
			break
	var ground_y := player.global_position.y
	player.call(&"request_jump")
	var jumped := false
	for _frame: int in range(30):
		await physics_frame
		jumped = jumped or player.global_position.y < ground_y - 18.0
		if jumped and player.is_on_floor():
			break
	_release_inputs()
	return _require(jumped, "Stage %s player did not complete a grounded jump." % stage_id)


func _release_inputs() -> void:
	Input.action_release(&"ui_left")
	Input.action_release(&"ui_right")
	Input.action_release(&"ui_accept")
	Input.action_release(&"slide_dash")


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
