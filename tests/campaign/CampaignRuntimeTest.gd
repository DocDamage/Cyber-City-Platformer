extends SceneTree

const REQUIRED_ARCHETYPES := [
	"ground_chaser",
	"fast_melee_attacker",
	"heavy_armored_enemy",
	"ranged_shooter",
	"flying_patrol",
	"flying_shooter",
	"leaping_enemy",
	"shielded_enemy",
	"ambush_enemy",
	"hazard_spawning_enemy",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(60.0, true, false, true).timeout.connect(func() -> void:
		push_error("Campaign runtime test timed out.")
		quit(1)
	)
	var registry := root.get_node("AssetRegistry")
	var manifest: Dictionary = registry.call(&"get_campaign_manifest")
	var stage_count := 0
	var encountered_archetypes := {}
	for act_value: Variant in manifest.get("acts", []):
		var act: Dictionary = act_value
		for stage_value: Variant in act.get("stages", []):
			var metadata: Dictionary = stage_value
			var stage_id := String(metadata.get("id", ""))
			var packed := load(String(metadata.get("scene", ""))) as PackedScene
			if not _require(packed != null, "Stage %s could not be loaded." % stage_id):
				return
			var stage := packed.instantiate() as StageBase
			root.add_child(stage)
			for _frame in range(4):
				await process_frame
				await physics_frame
			var controller := stage.runtime_controller
			if not _require(controller != null, "Stage %s has no runtime controller." % stage_id):
				return
			var player := stage.get_player() as CharacterBody2D
			var camera := player.get_node_or_null("Camera2D") as DynamicCamera
			var values: Array = metadata.get("camera_bounds", [])
			var expected := Rect2(float(values[0]), float(values[1]), float(values[2]) - float(values[0]), float(values[3]) - float(values[1]))
			if not _require(camera != null and camera.get_configured_bounds().is_equal_approx(expected), "Stage %s camera bounds differ from metadata." % stage_id):
				return
			var start_center := camera.get_clamped_center_for_world_position(Vector2(expected.position.x, expected.get_center().y))
			var middle_center := camera.get_clamped_center_for_world_position(expected.get_center())
			var exit_center := camera.get_clamped_center_for_world_position(Vector2(expected.end.x, expected.get_center().y))
			if not _require(start_center.x <= middle_center.x and middle_center.x <= exit_center.x, "Stage %s camera cannot progress start-to-exit." % stage_id):
				return
			if expected.size.x > 960.0 and not _require(exit_center.x > start_center.x, "Stage %s wide camera never reaches its exit." % stage_id):
				return
			var stage_exit := stage.get_stage_exit()
			if not _require(stage_exit != null, "Stage %s has no production exit." % stage_id):
				return
			var completion: Dictionary = metadata.get("completion_target", {})
			if String(completion.get("type", "")) == "boss":
				if not _require(stage_exit.is_locked and _count_descendants_in_group(stage, &"bosses") == 1, "Boss stage %s is not locked to one boss." % stage_id):
					return
			else:
				var summary: Dictionary = controller.get_debug_summary()
				if not _require(int(summary.get("encounters_remaining", 0)) == int(metadata.get("encounter_count", 0)), "Stage %s encounter count is incorrect." % stage_id):
					return
				if not _require(controller.installed_mechanics.size() > 0, "Stage %s has no installed stage mechanic." % stage_id):
					return
				if not _require(_count_descendants_in_group(stage, &"enemies") >= 4, "Stage %s has fewer than two populated encounters." % stage_id):
					return
			for node: Node in get_nodes_in_group(&"enemies"):
				if stage.is_ancestor_of(node) and node is EnemyBase:
					var enemy := node as EnemyBase
					if not _require(enemy.detection_area != null and enemy.get_node_or_null("AttackController") is EnemyAttackController, "Stage %s contains an incompletely wired enemy." % stage_id):
						return
					if not _require(not enemy.contact_hitbox.is_active(), "Stage %s enemy contact damage is active outside attack frames." % stage_id):
						return
					encountered_archetypes[String(enemy.get_archetype())] = true
			stage_count += 1
			stage.queue_free()
			await process_frame
	for archetype: String in REQUIRED_ARCHETYPES:
		if not _require(encountered_archetypes.has(archetype), "Campaign never instantiates archetype '%s'." % archetype):
			return
	print("CAMPAIGN_RUNTIME_TEST_OK stages=", stage_count, " archetypes=", encountered_archetypes.size())
	quit()


func _count_descendants_in_group(ancestor: Node, group: StringName) -> int:
	var count := 0
	for node: Node in get_nodes_in_group(group):
		if ancestor.is_ancestor_of(node):
			count += 1
	return count


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
