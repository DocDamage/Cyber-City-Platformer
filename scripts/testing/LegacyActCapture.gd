extends SceneTree

const CAPTURE_SIZE := Vector2i(960, 540)
const STAGE_IDS := [
	"1-1", "1-2", "1-3", "1-4", "1-5",
	"2-1", "2-2", "2-3", "2-4", "2-5",
]
const SIGNATURE_FOCUS := {
	"1-1": Vector2(704, 300),
	"1-2": Vector2(2250, 300),
	"1-3": Vector2(2450, -120),
	"1-4": Vector2(2200, 300),
	"1-5": Vector2(3900, 300),
	"2-1": Vector2(760, 310),
	"2-2": Vector2(2900, 280),
	"2-3": Vector2(3150, 120),
	"2-4": Vector2(3200, 300),
	"2-5": Vector2(3900, 300),
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var output_directory := OS.get_environment("CCP_LEGACY_CAPTURE_DIR")
	if output_directory.is_empty():
		push_error("Legacy act capture requires CCP_LEGACY_CAPTURE_DIR.")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(output_directory) != OK:
		push_error("Legacy act capture could not create %s." % output_directory)
		quit(1)
		return
	root.size = CAPTURE_SIZE
	root.content_scale_size = CAPTURE_SIZE
	var stages: Array[String] = []
	var requested_stages := OS.get_environment("CCP_LEGACY_CAPTURE_STAGES")
	if requested_stages.is_empty():
		stages.assign(STAGE_IDS)
	else:
		for stage_value: String in requested_stages.split(",", false):
			var stage_id := stage_value.strip_edges()
			if stage_id in STAGE_IDS and stage_id not in stages:
				stages.append(stage_id)
	if stages.is_empty():
		push_error("Legacy act capture did not receive a valid stage selection.")
		quit(1)
		return
	print("LEGACY_ACT_CAPTURE_BEGIN stages=", stages.size(), " output=", output_directory)
	var registry := root.get_node_or_null("AssetRegistry")
	if registry == null:
		push_error("Legacy act capture requires the AssetRegistry autoload.")
		quit(1)
		return
	for stage_id: String in stages:
		print("LEGACY_ACT_CAPTURE_STAGE_BEGIN stage=", stage_id)
		var coordinates := stage_id.split("-", false, 1)
		var metadata: Dictionary = registry.call(&"get_stage_info", coordinates[0].to_int(), coordinates[1].to_int())
		if metadata.is_empty():
			push_error("Legacy act capture could not resolve stage %s." % stage_id)
			quit(1)
			return
		var resource := load(String(metadata.get("scene", ""))) as PackedScene
		if resource == null:
			push_error("Legacy act capture could not load stage %s." % stage_id)
			quit(1)
			return
		var stage := resource.instantiate() as StageBase
		root.add_child(stage)
		print("LEGACY_ACT_CAPTURE_STAGE_LOADED stage=", stage_id)
		for _frame: int in range(5):
			await process_frame
		print("LEGACY_ACT_CAPTURE_STAGE_READY stage=", stage_id)
		if stage.runtime_controller == null:
			push_error("Legacy act capture stage %s has no runtime controller." % stage_id)
			quit(1)
			return
		var player := stage.get_player() as Node2D
		var camera := player.get_node_or_null("Camera2D") as Camera2D if player != null else null
		if camera == null:
			push_error("Legacy act capture stage %s has no player camera." % stage_id)
			quit(1)
			return
		player.set_physics_process(false)
		camera.position_smoothing_enabled = false
		var anchors := _capture_anchors(stage_id, stage, metadata)
		for label: String in anchors:
			print("LEGACY_ACT_CAPTURE_FRAME_BEGIN stage=", stage_id, " label=", label)
			if label == "start":
				var hud := stage.get_hud()
				if hud != null and hud.has_method(&"show_stage_intro"):
					hud.call(&"show_stage_intro", stage_id, metadata)
			player.global_position = anchors[label]
			if player is CharacterBody2D:
				(player as CharacterBody2D).velocity = Vector2.ZERO
			camera.position = Vector2.ZERO
			camera.force_update_scroll()
			for _frame: int in range(2):
				await process_frame
			# Headless drivers do not consistently emit frame_post_draw on Windows.
			# A forced off-screen draw keeps capture deterministic in local and CI QA.
			RenderingServer.force_draw(false)
			var capture := root.get_texture().get_image()
			if capture == null or capture.is_empty():
				push_error("Legacy act capture produced no image for %s %s." % [stage_id, label])
				quit(1)
				return
			var destination := output_directory.path_join("%s_%s.png" % [stage_id, label])
			if capture.save_png(destination) != OK:
				push_error("Legacy act capture could not write %s." % destination)
				quit(1)
				return
			capture = null
			print("LEGACY_ACT_CAPTURE_FRAME_OK stage=", stage_id, " label=", label)
			if label == "start":
				var hud := stage.get_hud()
				if hud != null:
					var stage_intro := hud.get_node_or_null("Layout/StageIntro") as Control
					if stage_intro != null:
						stage_intro.visible = false
		stage.queue_free()
		await process_frame
		await process_frame
		camera = null
		player = null
		stage = null
		resource = null
		print("LEGACY_ACT_CAPTURE_STAGE_OK stage=", stage_id, " captures=3")
	print("LEGACY_ACT_CAPTURE_OK stages=", stages.size(), " captures=", stages.size() * 3, " output=", output_directory)
	quit()


func _capture_anchors(stage_id: String, stage: StageBase, metadata: Dictionary) -> Dictionary:
	var start := stage.get_player_spawn().global_position
	var finish := stage.get_stage_exit().global_position
	var signature := SIGNATURE_FOCUS.get(stage_id, (start + finish) * 0.5) as Vector2
	var values: Array = metadata.get("camera_bounds", [])
	if values.size() == 4:
		var viewport_half := Vector2(CAPTURE_SIZE) * 0.5
		var minimum := Vector2(float(values[0]), float(values[1])) + viewport_half
		var maximum := Vector2(float(values[2]), float(values[3])) - viewport_half
		if maximum.x >= minimum.x:
			signature.x = clampf(signature.x, minimum.x, maximum.x)
		if maximum.y >= minimum.y:
			signature.y = clampf(signature.y, minimum.y, maximum.y)
	return {
		"start": start,
		"signature": signature,
		"finish": finish,
	}
