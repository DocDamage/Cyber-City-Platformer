extends SceneTree

const STAGE_IDS := [
	"1-1", "1-2", "1-3", "1-4", "1-5",
	"2-1", "2-2", "2-3", "2-4", "2-5",
]
const EXPECTED_ROUTE_LINKS := 41
const EXPECTED_HERO_BACKGROUNDS := {
	"1-3": "res://assets/runtime/environments/Act1_CyberCity/Generated/communication_spire_panorama_v1.png",
	"1-4": "res://assets/runtime/environments/Act1_CyberCity/Generated/skybridge_junction_panorama_v1.png",
	"1-5": "res://assets/runtime/environments/Act1_CyberCity/Generated/executive_helipad_panorama_v1.png",
	"2-1": "res://assets/runtime/environments/Act2_RobotFactory/Generated/mega_robot_factory_panorama_v1.png",
	"2-2": "res://assets/runtime/environments/Act2_RobotFactory/Generated/mega_robot_factory_panorama_v1.png",
	"2-3": "res://assets/runtime/environments/Act2_RobotFactory/Generated/smelting_core_panorama_v1.png",
	"2-4": "res://assets/runtime/environments/Act2_RobotFactory/Generated/robotic_maintenance_panorama_v1.png",
	"2-5": "res://assets/runtime/environments/Act2_RobotFactory/Generated/assembly_engine_panorama_v1.png",
}

const EXPECTED_STATIC_SUPPORTS := {
	"1-1": 2,
	"1-2": 4,
	"1-3": 3,
	"1-4": 4,
	"1-5": 2,
	"2-1": 3,
	"2-2": 4,
	"2-3": 4,
	"2-4": 4,
	"2-5": 2,
}

const EXPECTED_MECHANIC_ASSEMBLIES := {
	"1-1": 0,
	"1-2": 2,
	"1-3": 1,
	"1-4": 3,
	"1-5": 0,
	"2-1": 0,
	"2-2": 1,
	"2-3": 0,
	"2-4": 2,
	"2-5": 0,
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(45.0, true, false, true).timeout.connect(func() -> void:
		push_error("First two acts production test timed out.")
		quit(1)
	)
	var registry := root.get_node("AssetRegistry")
	var manager := root.get_node("GameManager")
	manager.call(&"new_game")
	var manifest := registry.call(&"get_campaign_manifest") as Dictionary
	var metadata_by_id := _metadata_by_id(manifest)
	var observed_backgrounds := {}
	var completed := 0
	var player_controlled := 0
	var traversal_surfaces := 0
	var traversal_decks := 0
	var traversal_links := 0
	var static_supports := 0
	var mechanic_assemblies := 0
	for index: int in range(STAGE_IDS.size()):
		var stage_id: String = STAGE_IDS[index]
		if not _require(metadata_by_id.has(stage_id), "Missing first-two-acts manifest entry %s." % stage_id):
			return
		var metadata := metadata_by_id[stage_id] as Dictionary
		var scene_path := String(metadata.get("scene", ""))
		var scene_text := FileAccess.get_file_as_string(scene_path)
		if not _require(stage_id.begins_with("1-") or "Neon Alley" not in scene_text, "Factory stage %s still uses the Neon Alley city backdrop." % stage_id):
			return
		var resource := load(scene_path) as PackedScene
		if not _require(resource != null, "Could not load first-two-acts stage %s." % stage_id):
			return
		var stage := resource.instantiate() as StageBase
		root.add_child(stage)
		for _frame: int in range(5):
			await process_frame
			await physics_frame
		var controller := stage.runtime_controller
		var stage_exit := stage.get_stage_exit()
		if not _require(controller != null and stage_exit != null, "Stage %s did not initialize its production controller and exit." % stage_id):
			return
		var stage_intro := stage.get_node_or_null("HUD/Layout/StageIntro") as Control
		var stage_intro_act := stage.get_node_or_null("HUD/Layout/StageIntro/Margin/Readouts/ActLabel") as Label
		var stage_intro_title := stage.get_node_or_null("HUD/Layout/StageIntro/Margin/Readouts/TitleLabel") as Label
		var status_panel := stage.get_node_or_null("HUD/Layout/StatusPanel") as Control
		var score_panel := stage.get_node_or_null("HUD/Layout/ScorePanel") as Control
		var hud := stage.get_hud()
		var expected_title := String(metadata.get("display_name", metadata.get("name", stage_id))).to_upper()
		if hud != null:
			hud.call(&"show_stage_intro", stage_id, metadata)
		if not _require(stage_intro != null and stage_intro_act != null and stage_intro_title != null and hud != null and stage_intro.visible and String(hud.call(&"get_presented_stage_id")) == stage_id and stage_intro_act.text.begins_with("ACT %02d" % int(metadata.get("act", 0))) and stage_intro_title.text == expected_title, "Stage %s does not present its authored act and stage briefing (presented=%s visible=%s act=%s title=%s)." % [stage_id, String(hud.call(&"get_presented_stage_id")) if hud != null else "<missing>", stage_intro.visible if stage_intro != null else false, stage_intro_act.text if stage_intro_act != null else "<missing>", stage_intro_title.text if stage_intro_title != null else "<missing>"]):
			return
		if not _require(status_panel != null and score_panel != null and not stage_intro.get_global_rect().intersects(status_panel.get_global_rect()) and not stage_intro.get_global_rect().intersects(score_panel.get_global_rect()), "Stage %s briefing overlaps core HUD readouts." % stage_id):
			return
		if not await _verify_spawn_controls(stage, stage_id):
			return
		player_controlled += 1
		var presented_decks := _verify_traversal_deck_presentation(controller, stage_id)
		if presented_decks < 0:
			return
		traversal_decks += presented_decks
		var verified_links := _verify_authored_route_kinematics(controller, stage.get_player() as CharacterBody2D, stage_id)
		if verified_links < 0:
			return
		traversal_links += verified_links
		var presented_static_supports := _verify_static_architecture_dressing(stage, stage_id)
		if presented_static_supports < 0:
			return
		static_supports += presented_static_supports
		var presented_mechanic_assemblies := _verify_mechanic_architecture(controller, stage_id)
		if presented_mechanic_assemblies < 0:
			return
		mechanic_assemblies += presented_mechanic_assemblies
		var verified_surfaces := await _verify_authored_traversal_surfaces(controller, stage.get_player() as CharacterBody2D, stage_id)
		if verified_surfaces < 0:
			return
		traversal_surfaces += verified_surfaces
		var is_boss_stage := String((metadata.get("completion_target", {}) as Dictionary).get("type", "")) == "boss"
		var expected_locked_label := "DEFEAT BOSS" if is_boss_stage else "CLEAR ENCOUNTERS"
		var exit_label := stage_exit.get_node_or_null("Label") as Label
		if not _require(stage_exit.is_locked and exit_label != null and exit_label.text == expected_locked_label, "Stage %s exit does not communicate its locked objective." % stage_id):
			return
		if not _require(stage.get_checkpoints_container().get_child_count() >= int(metadata.get("expected_checkpoints", 1)), "Stage %s is missing its checkpoint budget." % stage_id):
			return
		if not _require(stage.get_collectibles_container().get_child_count() == int(metadata.get("collectible_count", 0)), "Stage %s collectible budget did not reach runtime." % stage_id):
			return
		var camera_bounds: Array = metadata.get("camera_bounds", [])
		if camera_bounds.size() == 4 and float(camera_bounds[1]) < 0.0:
			if not _require(stage is CampaignStage and (stage as CampaignStage).background_coverage_size.y >= 900.0, "Vertical stage %s does not overscan its hero background." % stage_id):
				return

		if EXPECTED_HERO_BACKGROUNDS.has(stage_id):
			var texture := _primary_background(stage)
			var expected_path := String(EXPECTED_HERO_BACKGROUNDS[stage_id])
			if not _require(texture != null and texture.resource_path == expected_path, "Stage %s is missing its authored hero panorama." % stage_id):
				return
			if not _require(texture.get_width() >= 1600 and texture.get_height() >= 900, "Stage %s hero panorama is below the 16:9 production resolution floor." % stage_id):
				return
			observed_backgrounds[expected_path] = true

		var expected_next := "res://Stages/Act3_NeonMoon/3-1_LunarSurfaceArrival/Stage.tscn"
		if index + 1 < STAGE_IDS.size():
			expected_next = String((metadata_by_id[STAGE_IDS[index + 1]] as Dictionary).get("scene", ""))
		if not _require(stage_exit.next_scene_path == expected_next, "Stage %s does not hand off to the next authored stage." % stage_id):
			return

		if is_boss_stage:
			var boss := stage.get_boss()
			if not _require(boss != null, "Boss stage %s did not instantiate its boss." % stage_id):
				return
			boss.start_encounter()
			boss.complete_intro()
			await process_frame
			var boss_panel := stage.get_node_or_null("HUD/Layout/BossPanel") as Control
			if not _require(boss_panel != null and status_panel != null and score_panel != null, "Boss stage %s is missing a required HUD panel." % stage_id):
				return
			if not _require(boss_panel.visible and boss_panel.size.x <= 400.0, "Boss stage %s does not present a bounded boss HUD." % stage_id):
				return
			if not _require(not boss_panel.get_global_rect().intersects(status_panel.get_global_rect()) and not boss_panel.get_global_rect().intersects(score_panel.get_global_rect()), "Boss stage %s boss HUD overlaps the core status readouts." % stage_id):
				return
			boss.take_damage(boss.health)
			await process_frame
		else:
			controller.complete_objectives_for_test()
		if not _require(not stage_exit.is_locked and exit_label.text == "STAGE EXIT", "Stage %s did not unlock and relabel its exit after completion." % stage_id):
			return
		manager.call(&"complete_stage", stage_id)
		completed += 1
		stage.queue_free()
		await process_frame
	if not _require(completed == 10 and player_controlled == 10 and traversal_surfaces == 18 and traversal_decks >= traversal_surfaces and traversal_links == EXPECTED_ROUTE_LINKS and static_supports >= 32 and mechanic_assemblies == 9 and observed_backgrounds.size() == 7, "First two acts did not complete every stage with player-controlled movement, jumping, bounded route links, eighteen landed authored traversal surfaces, collision-bound structural supports, mechanic assemblies, visible traversal decks, and seven distinct production panoramas."):
		return
	if not _require(manager.campaign_progress.completed_stages.has("1-5") and manager.campaign_progress.completed_stages.has("2-5"), "Act completion did not persist both regional finales."):
		return
	print("FIRST_TWO_ACTS_PRODUCTION_TEST_OK stages=", completed, " player_controls=", player_controlled, " traversal_surfaces=", traversal_surfaces, " traversal_decks=", traversal_decks, " traversal_links=", traversal_links, " static_supports=", static_supports, " mechanic_assemblies=", mechanic_assemblies, " hero_backgrounds=", observed_backgrounds.size(), " exits=10")
	quit()


func _metadata_by_id(manifest: Dictionary) -> Dictionary:
	var result := {}
	for act_value: Variant in manifest.get("acts", []):
		var act := act_value as Dictionary
		if int(act.get("number", 0)) > 2:
			continue
		for stage_value: Variant in act.get("stages", []):
			var metadata := stage_value as Dictionary
			result[String(metadata.get("id", ""))] = metadata
	return result


func _primary_background(stage: StageBase) -> Texture2D:
	if stage is CampaignStage:
		return (stage as CampaignStage).far_background
	var sprite := stage.get_node_or_null("Background Skyline/Cyberpunk City Sunset") as Sprite2D
	return sprite.texture if sprite != null else null


func _verify_spawn_controls(stage: StageBase, stage_id: String) -> bool:
	var player := stage.get_player() as CharacterBody2D
	if not _require(player != null, "Stage %s did not create a controllable CharacterBody2D player." % stage_id):
		return false
	_release_inputs()
	for _frame: int in range(24):
		await physics_frame
		if player.is_on_floor():
			break
	if not _require(player.is_on_floor(), "Stage %s player did not settle on authored spawn collision." % stage_id):
		return false
	var start_x := player.global_position.x
	Input.action_press(&"ui_right")
	for _frame: int in range(12):
		await physics_frame
	Input.action_release(&"ui_right")
	if not _require(player.global_position.x >= start_x + 8.0, "Stage %s player did not respond to rightward movement from spawn." % stage_id):
		return false
	for _frame: int in range(12):
		await physics_frame
		if player.is_on_floor():
			break
	if not _require(player.is_on_floor(), "Stage %s player did not recover to a traversable floor after entry movement." % stage_id):
		return false
	var grounded_y := player.global_position.y
	player.call(&"request_jump")
	var jumped := false
	for _frame: int in range(30):
		await physics_frame
		if player.global_position.y < grounded_y - 18.0:
			jumped = true
		if jumped and player.is_on_floor():
			break
	_release_inputs()
	return _require(jumped, "Stage %s player did not complete a real jump from the authored entry surface." % stage_id)


func _release_inputs() -> void:
	Input.action_release(&"ui_left")
	Input.action_release(&"ui_right")
	Input.action_release(&"ui_accept")
	Input.action_release(&"slide_dash")


func _verify_traversal_deck_presentation(controller: StageController, stage_id: String) -> int:
	if controller.authored_traversal.is_empty():
		return 0
	var deck_count := 0
	for section: AuthoredTraversal in controller.authored_traversal:
		if not _require(not section.architecture_id.is_empty(), "Stage %s traversal %s has no authored architecture identity." % [stage_id, section.section_id]):
			return -1
		var architecture := section.get_node_or_null("Architecture") as Node2D
		if not _require(architecture != null, "Stage %s traversal %s has no architectural presentation." % [stage_id, section.section_id]):
			return -1
		var structure_count := 0
		for structure: Node in architecture.get_children():
			if structure is Sprite2D and (structure as Sprite2D).texture != null:
				structure_count += 1
		if not _require(structure_count > 0, "Stage %s traversal %s has no visible load-bearing architecture." % [stage_id, section.section_id]):
			return -1
		var expects_hazard_marks := section.section_kind == &"hazard_steps" or section.section_kind == &"dash_gap" or section.section_kind == &"long_gap" or section.section_kind == &"low_gravity_gap"
		for child: Node in section.get_children():
			if child is not StaticBody2D:
				continue
			var body := child as StaticBody2D
			var collision := _rectangle_collision(body)
			if not _require(collision != null, "Stage %s traversal %s contains a deck without rectangle collision." % [stage_id, section.section_id]):
				return -1
			var deck_art := body.get_node_or_null("DeckArt") as Node2D
			if not _require(deck_art != null, "Stage %s traversal %s contains an unrendered collision deck." % [stage_id, section.section_id]):
				return -1
			var deck_role := String(body.get_meta(&"architecture_role", ""))
			var surface_tiles := deck_art.get_node_or_null("SurfaceTiles") as TerrainSurfaceArt
			if not _require(deck_role == "shaft_wall" or (surface_tiles != null and surface_tiles.source_texture != null), "Stage %s traversal %s collision deck is missing its environment tile surface." % [stage_id, section.section_id]):
				return -1
			var expected_environment := &"cyber_city" if stage_id.begins_with("1-") else &"robot_factory"
			if not _require(String(deck_art.get("environment_id")) == String(expected_environment), "Stage %s traversal %s uses art from the wrong environment kit." % [stage_id, section.section_id]):
				return -1
			if not _require(String(deck_art.get("deck_role")) == deck_role, "Stage %s traversal %s deck art does not know its architectural collision role." % [stage_id, section.section_id]):
				return -1
			var expected_size := (collision.shape as RectangleShape2D).size
			var art_size: Variant = deck_art.get("deck_size")
			if not _require(art_size is Vector2 and (art_size as Vector2).is_equal_approx(expected_size), "Stage %s traversal %s deck art does not match its collision geometry." % [stage_id, section.section_id]):
				return -1
			if not _require(bool(deck_art.get("show_hazard_marks")) == expects_hazard_marks, "Stage %s traversal %s deck hazard markings do not match its gameplay route." % [stage_id, section.section_id]):
				return -1
			deck_count += 1
	if not _require(deck_count > 0, "Stage %s did not expose any authored traversal decks for presentation verification." % stage_id):
		return -1
	return deck_count


func _verify_static_architecture_dressing(stage: StageBase, stage_id: String) -> int:
	var dressing := stage.get_presentation_container().get_node_or_null("StageArchitectureDressing") as Node2D
	var terrain := stage.get_terrain()
	var expected_count := int(EXPECTED_STATIC_SUPPORTS.get(stage_id, 0))
	if not _require(dressing != null and terrain != null, "Stage %s is missing collision-bound environmental architecture." % stage_id):
		return -1
	var support_count := 0
	for child: Node in dressing.get_children():
		if child is not Sprite2D:
			continue
		var support := child as Sprite2D
		var anchor: Variant = support.get_meta(&"surface_anchor", null)
		if not _require(support.texture != null and not String(support.get_meta(&"asset_id", "")).is_empty(), "Stage %s has a static support without a runtime art asset." % stage_id):
			return -1
		if not _require(anchor is Vector2 and _is_bound_to_static_surface(stage, terrain, anchor as Vector2), "Stage %s has a floating static support rather than a terrain-bound assembly." % stage_id):
			return -1
		support_count += 1
	if not _require(support_count == expected_count, "Stage %s expected %d collision-bound structural supports, found %d." % [stage_id, expected_count, support_count]):
		return -1
	return support_count


func _verify_authored_route_kinematics(controller: StageController, player: CharacterBody2D, stage_id: String) -> int:
	if player == null:
		_require(false, "Stage %s has no player to validate route kinematics." % stage_id)
		return -1
	var maximum_rise: float = player.jump_velocity * player.jump_velocity / (2.0 * player.gravity) * 0.84
	var verified_links := 0
	for section: AuthoredTraversal in controller.authored_traversal:
		var route := section.get_route_platforms()
		if section.section_kind == &"wall_jump_shaft":
			if not _require(route.size() >= 3 and String(route[0].get("role", "")) == "shaft_wall" and String(route[1].get("role", "")) == "shaft_wall", "Stage %s wall-jump traversal %s is missing its paired climb surfaces." % [stage_id, section.section_id]):
				return -1
			continue
		if section.section_kind == &"moving_platform_route":
			continue
		if route.size() < 2:
			if not _require(false, "Stage %s traversal %s has no route sequence to validate." % [stage_id, section.section_id]):
				return -1
		for index in range(1, route.size()):
			var source := route[index - 1] as Dictionary
			var target := route[index] as Dictionary
			var source_center := source.get("center", Vector2.ZERO) as Vector2
			var target_center := target.get("center", Vector2.ZERO) as Vector2
			var source_size := source.get("size", Vector2.ZERO) as Vector2
			var target_size := target.get("size", Vector2.ZERO) as Vector2
			var rise := source_center.y - target_center.y
			var horizontal_gap := absf(target_center.x - source_center.x) - (source_size.x + target_size.x) * 0.5
			if section.section_kind == &"dash_gap" or section.section_kind == &"long_gap":
				var dash_distance: float = player.dash_speed * player.dash_duration
				var timed_followthrough: float = player.speed * 0.39
				if not _require(horizontal_gap > dash_distance and horizontal_gap <= dash_distance + timed_followthrough, "Stage %s dash traversal %s has an invalid dash gap %.1f." % [stage_id, section.section_id, horizontal_gap]):
					return -1
			else:
				if not _require(rise <= maximum_rise and horizontal_gap <= 48.0, "Stage %s traversal %s link %d exceeds the standard jump envelope (rise=%.1f/%.1f gap=%.1f)." % [stage_id, section.section_id, index, rise, maximum_rise, horizontal_gap]):
					return -1
			verified_links += 1
	return verified_links


func _is_bound_to_static_surface(stage: StageBase, terrain: TileMapLayer, anchor: Vector2) -> bool:
	if terrain.tile_set == null:
		return false
	var tile_size := Vector2(terrain.tile_set.tile_size)
	var target_global := stage.to_global(anchor)
	var tolerance := tile_size.length() + 1.0
	for cell: Vector2i in terrain.get_used_cells():
		if terrain.get_cell_source_id(cell + Vector2i.UP) != -1:
			continue
		var center_global := terrain.to_global(terrain.map_to_local(cell))
		var surface_global := center_global - Vector2(0.0, tile_size.y * 0.5)
		if surface_global.distance_to(target_global) <= tolerance:
			return true
	return false


func _verify_mechanic_architecture(controller: StageController, stage_id: String) -> int:
	var expected_count := int(EXPECTED_MECHANIC_ASSEMBLIES.get(stage_id, 0))
	var actual_count := 0
	for mechanic: Node in controller.installed_mechanics:
		var expects_assembly := (mechanic is MovingPlatform and not (mechanic as MovingPlatform).presentation_id.is_empty()) or mechanic is BreakawayPlatform or mechanic is CrusherHazard
		if not expects_assembly:
			continue
		var assembly := mechanic.get_node_or_null("MechanicArchitecture") as Sprite2D
		if not _require(assembly != null and assembly.texture != null and not String(assembly.get_meta(&"presentation_id", "")).is_empty(), "Stage %s mechanic %s does not present a visible machinery assembly." % [stage_id, mechanic.name]):
			return -1
		actual_count += 1
	if not _require(actual_count == expected_count, "Stage %s expected %d machinery assemblies, found %d." % [stage_id, expected_count, actual_count]):
		return -1
	return actual_count


func _verify_authored_traversal_surfaces(controller: StageController, player: CharacterBody2D, stage_id: String) -> int:
	if player == null:
		_require(false, "Stage %s cannot verify traversal surfaces without a CharacterBody2D player." % stage_id)
		return -1
	var player_collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if player_collision == null or player_collision.shape is not CapsuleShape2D:
		_require(false, "Stage %s player has no capsule collision for traversal landing verification." % stage_id)
		return -1
	var player_shape := player_collision.shape as CapsuleShape2D
	var player_bottom_offset := player_shape.height * 0.5 + player_collision.position.y
	var verified := 0
	player.is_invincible = true
	for section: AuthoredTraversal in controller.authored_traversal:
		var surfaces := _authored_surfaces(section)
		if surfaces.is_empty():
			player.is_invincible = false
			_require(false, "Stage %s traversal %s has no colliding authored surface." % [stage_id, section.section_id])
			return -1
		var landed := false
		for surface_value: Variant in surfaces:
			var surface := surface_value as Dictionary
			var body := surface.get("body") as StaticBody2D
			var center := surface.get("center", Vector2.ZERO) as Vector2
			var size := surface.get("size", Vector2.ZERO) as Vector2
			var expected_y := center.y - size.y * 0.5 - player_bottom_offset
			player.global_position = Vector2(center.x, expected_y - 72.0)
			player.velocity = Vector2.ZERO
			for _frame: int in range(36):
				await physics_frame
				if _is_grounded_on_body(player, body):
					landed = true
					break
			if landed:
				break
		if not landed:
			player.is_invincible = false
			_require(false, "Stage %s player did not land on any authored traversal platform in %s (actual=%s)." % [stage_id, section.section_id, player.global_position])
			return -1
		verified += 1
	player.is_invincible = false
	_release_inputs()
	return verified


func _authored_surfaces(section: AuthoredTraversal) -> Array:
	var surfaces: Array = []
	for child: Node in section.get_children():
		if child is not StaticBody2D:
			continue
		var body := child as StaticBody2D
		var collision := _rectangle_collision(body)
		if collision == null:
			continue
		var size := (collision.shape as RectangleShape2D).size
		surfaces.append({
			"body": body,
			"center": collision.global_position,
			"size": size,
		})
	return surfaces


func _rectangle_collision(body: StaticBody2D) -> CollisionShape2D:
	for child: Node in body.get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			return child as CollisionShape2D
	return null


func _is_grounded_on_body(player: CharacterBody2D, body: StaticBody2D) -> bool:
	if not player.is_on_floor():
		return false
	for index: int in range(player.get_slide_collision_count()):
		var collision := player.get_slide_collision(index)
		if collision != null and collision.get_collider() == body:
			return true
	return false


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
