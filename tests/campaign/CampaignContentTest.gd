extends SceneTree

const ACT_BALANCE := preload("res://scripts/campaign/ActBalanceProfile.gd")

const REQUIRED_EVIDENCE := {
	"1-1": ["jump_school", "wall_school", "melee_intro", "ranged_intro"],
	"1-2": ["billboard_run", "electric_sign_a", "billboard_ambush", "high_billboards"],
	"1-3": ["antenna_shaft", "signal_spinner_a", "lower_airspace", "vertical_camera"],
	"1-4": ["moving_bridge", "bridge_segment_a", "dash_bridge", "preboss_gauntlet"],
	"1-5": ["helipad_airflow", "helipad_edge_left"],
	"2-1": ["safe_belt", "intake_belt", "steam_a", "armored_intake"],
	"2-2": ["reverse_belt_a", "hazard_belt", "cargo_platform", "falling_part_a", "cargo_waves"],
	"2-3": ["furnace_climb", "smelter_pool", "heat_chamber", "forge_steam", "laser_gate_a"],
	"2-4": ["crusher_hall", "crusher_a", "repair_terminal", "repair_gate", "repair_crossfire"],
	"2-5": ["arena_belt", "machinery_terminal"],
	"3-1": ["low_g_school", "lunar_low_g", "zero_g_cave", "zero_g_predators"],
	"3-2": ["cleanroom_gate", "cleanroom_terminal", "clean_laser_a", "lore_terminal"],
	"3-3": ["security_shaft", "shaft_turret", "burst_turret", "security_spinner", "shaft_camera"],
	"3-4": ["heavy_g_lab", "inverse_lab", "containment_pool", "bio_switch_a", "bio_switch_b", "specimen_ambush"],
	"3-5": ["oracle_gravity", "oracle_laser"],
	"4-1": ["corruption_a", "corruption_b", "outpost_lift", "elite_outpost"],
	"4-2": ["void_floats", "chasm_pit_a", "chasm_float_a", "visibility_field", "blind_dash"],
	"4-3": ["organic_crusher_a", "nest_ambush", "corruption_node_a", "corruption_node_b", "nest_gate"],
	"4-4": ["sanctuary_belt", "sanctuary_laser", "sanctuary_gravity", "sanctuary_platform", "mastery_elites_b"],
	"4-5": ["arena_corruption_left", "void_breath_axis"],
}

const REQUIRED_IMPLEMENTATIONS := [
	"moving_platform", "breakaway_platform", "conveyor", "gravity_zone", "camera_zone",
	"visibility_zone", "turret", "security_gate", "terminal", "switch", "lore_terminal",
	"destructible_switch", "laser_grid", "steam_vent", "electrical_floor", "toxic_pool",
	"void_pit", "falling_object", "crusher", "rotating_laser",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(75.0, true, false, true).timeout.connect(func() -> void:
		push_error("Campaign content test timed out.")
		quit(1)
	)
	var registry := root.get_node("AssetRegistry")
	var manifest := registry.call(&"get_campaign_manifest") as Dictionary
	var observed_kinds := {}
	var boss_signatures := {}
	var act_archetypes := {1: {}, 2: {}, 3: {}, 4: {}}
	var previous_profile: Dictionary = ACT_BALANCE.get_profile(1)
	for act_number in range(2, 5):
		var profile: Dictionary = ACT_BALANCE.get_profile(act_number)
		if not _require(float(profile.health) >= float(previous_profile.health) and float(profile.speed) >= float(previous_profile.speed) and float(profile.knockback_resistance) >= float(previous_profile.knockback_resistance), "Act %d balance targets do not progress predictably." % act_number):
			return
		if not _require(float(profile.health) <= 1.2, "Act %d health target turns regular enemies into damage sponges." % act_number):
			return
		previous_profile = profile
	var stage_count := 0
	for act_value: Variant in manifest.get("acts", []):
		for stage_value: Variant in (act_value as Dictionary).get("stages", []):
			var metadata := stage_value as Dictionary
			var stage_id := String(metadata.get("id", ""))
			var blueprint := StageContentCatalog.get_blueprint(stage_id)
			var is_boss_stage := String((metadata.get("completion_target", {}) as Dictionary).get("type", "")) == "boss"
			if not _require(StageContentCatalog.validate(blueprint, is_boss_stage).is_empty(), "Blueprint validation failed for %s." % stage_id):
				return
			if not _require(_has_required_evidence(stage_id, blueprint), "Stage %s is missing required design evidence." % stage_id):
				return
			for mechanic_value: Variant in blueprint.get("mechanics", []):
				observed_kinds[String((mechanic_value as Dictionary).get("kind", ""))] = true
			var scene_path := String(metadata.get("scene", ""))
			var text := FileAccess.get_file_as_string(scene_path)
			if not _require("prototype" not in text.to_lower() and "designguide" not in text.to_lower(), "Stage %s contains editor-guide residue." % stage_id):
				return
			var stage := (load(scene_path) as PackedScene).instantiate() as StageBase
			root.add_child(stage)
			for _frame in range(4):
				await process_frame
				await physics_frame
			var controller := stage.runtime_controller
			if not _require(controller != null and controller.blueprint.get("stage_id") == stage_id, "Stage %s did not install its authored blueprint." % stage_id):
				return
			if not _require(stage.get_player() != null and stage.get_player_spawn() != null and stage.get_stage_exit() != null, "Stage %s has invalid critical node paths." % stage_id):
				return
			if not _require(stage.get_terrain() != null and stage.get_terrain().tile_set != null and stage.get_terrain().tile_set.get_physics_layers_count() > 0, "Stage %s has no terrain collision layer." % stage_id):
				return
			if not _require(stage.get_death_zone() != null and stage.get_ambient_root() != null and stage.get_hud() != null, "Stage %s is missing death, ambient, or HUD structure." % stage_id):
				return
			if not _require(controller.environmental_presentation != null and controller.environmental_presentation.is_in_group(&"ambient_presentation"), "Stage %s has no runtime ambient presentation." % stage_id):
				return
			if is_boss_stage:
				var boss := stage.get_boss()
				if not _require(boss != null and boss.get_attack_roster().size() >= 3 and boss.phase_two_threshold > boss.phase_three_threshold, "Boss %s lacks distinct attacks or three valid phases." % stage_id):
					return
				var signature := ",".join(PackedStringArray(boss.get_attack_roster()))
				if not _require(not boss_signatures.has(signature), "Boss %s reuses another boss attack roster." % stage_id):
					return
				boss_signatures[signature] = stage_id
				if not _require(stage.get_encounters_container().get_child_count() == 1 and stage.get_encounters_container().get_child(0) is BossArenaController and stage.get_stage_exit().is_locked, "Boss stage %s has no locked authored arena." % stage_id):
					return
			else:
				var summary := controller.get_debug_summary()
				if not _require(controller.authored_traversal.size() >= 2 and int(summary.get("encounter_count", 0)) == int(metadata.get("encounter_count", 0)), "Stage %s lacks two authored traversal/combat sections." % stage_id):
					return
				for section: AuthoredTraversal in controller.authored_traversal:
					if not _require(int(section.get_descriptor().get("platform_count", 0)) >= 2, "Stage %s has an empty traversal section." % stage_id):
						return
				for encounter: EncounterController in controller.authored_encounters:
					if not _require(encounter.get_wave_count() >= 1 and encounter.get_total_authored_enemy_count() >= 2, "Stage %s has an under-authored encounter." % stage_id):
						return
				for enemy_node: Node in stage.get_enemies_container().get_children():
					if enemy_node is EnemyBase:
						var enemy := enemy_node as EnemyBase
						var stage_act := int(metadata.get("act", 1))
						var active_profile := ACT_BALANCE.get_profile(stage_act)
						if not _require(is_equal_approx(enemy.knockback_resistance, float(active_profile.knockback_resistance)) and enemy.detection_radius > 0.0 and enemy.health == enemy.max_health, "Stage %s spawned an enemy without its live act balance profile." % stage_id):
							return
						(act_archetypes[stage_act] as Dictionary)[String(enemy.get_archetype())] = true
			stage_count += 1
			stage.queue_free()
			await process_frame
	for kind: String in REQUIRED_IMPLEMENTATIONS:
		if not _require(observed_kinds.has(kind), "Campaign never uses required mechanic implementation '%s'." % kind):
			return
	for act_number in range(1, 5):
		if not _require((act_archetypes[act_number] as Dictionary).size() >= 3, "Act %d uses fewer than three enemy behavior types." % act_number):
			return
	if not _require(stage_count == 20 and boss_signatures.size() == 4, "Campaign content test did not cover 20 stages and 4 distinct bosses."):
		return
	print("CAMPAIGN_CONTENT_TEST_OK stages=20 mechanics=", observed_kinds.size(), " bosses=4")
	quit()


func _has_required_evidence(stage_id: String, blueprint: Dictionary) -> bool:
	var ids := {}
	for section_value: Variant in blueprint.get("traversal", []):
		ids[String((section_value as Dictionary).get("id", ""))] = true
	for mechanic_value: Variant in blueprint.get("mechanics", []):
		ids[String((mechanic_value as Dictionary).get("id", ""))] = true
	for encounter_value: Variant in blueprint.get("encounters", []):
		ids[String((encounter_value as Dictionary).get("id", ""))] = true
	for required_id: String in REQUIRED_EVIDENCE.get(stage_id, []):
		if not ids.has(required_id):
			return false
	return true


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
