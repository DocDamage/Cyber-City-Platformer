extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(45.0, true, false, true).timeout.connect(func() -> void:
		push_error("Campaign traversal test timed out.")
		quit(1)
	)
	var manager := root.get_node("GameManager")
	var registry := root.get_node("AssetRegistry")
	manager.call(&"new_game")
	var stages: Array[Dictionary] = []
	var manifest: Dictionary = registry.call(&"get_campaign_manifest")
	for act_value: Variant in manifest.get("acts", []):
		for stage_value: Variant in (act_value as Dictionary).get("stages", []):
			stages.append(stage_value as Dictionary)
	var visited: Array[String] = []
	for index in range(stages.size()):
		var metadata := stages[index]
		var stage_id := String(metadata.get("id", ""))
		var stage := (load(String(metadata.get("scene", ""))) as PackedScene).instantiate() as StageBase
		root.add_child(stage)
		for _frame in range(4):
			await process_frame
		var controller := stage.runtime_controller
		var stage_exit := stage.get_stage_exit()
		if not _require(controller != null and stage_exit != null, "Traversal could not initialize stage %s." % stage_id):
			return
		visited.append(stage_id)
		var expected_next := String(stages[index + 1].get("scene", "")) if index + 1 < stages.size() else ""
		if not _require(stage_exit.next_scene_path == expected_next, "Stage %s exit path does not match campaign order." % stage_id):
			return
		var completion: Dictionary = metadata.get("completion_target", {})
		if String(completion.get("type", "")) == "boss":
			var boss := _find_boss(stage)
			if not _require(boss != null, "Traversal could not find boss in %s." % stage_id):
				return
			boss.start_encounter()
			boss.complete_intro()
			boss.take_damage(9999)
			await process_frame
		else:
			controller.complete_objectives_for_test()
		if not _require(not stage_exit.is_locked, "Stage %s exit remained locked after completion." % stage_id):
			return
		manager.call(&"complete_stage", stage_id)
		stage.queue_free()
		await process_frame
	if not _require(visited.size() == 20 and visited.front() == "1-1" and visited.back() == "4-5", "Traversal did not visit all stages in order."):
		return
	var completion_events := {"count": 0}
	manager.campaign_completed.connect(func() -> void: completion_events["count"] = int(completion_events["count"]) + 1)
	manager.call(&"_finish_campaign")
	await create_timer(0.8, true, false, true).timeout
	manager.call(&"_finish_campaign")
	if not _require(manager.campaign_progress.campaign_complete and int(completion_events.count) == 1, "Campaign completion did not fire exactly once."):
		return
	if not _require(current_scene != null and current_scene.scene_file_path == "res://scenes/ui/EndingScreen.tscn", "Final completion did not reach the ending scene."):
		return
	print("CAMPAIGN_TRAVERSAL_TEST_OK visited=20 completion_events=1")
	quit()


func _find_boss(stage: Node) -> BossBase:
	for node: Node in get_nodes_in_group(&"bosses"):
		if stage.is_ancestor_of(node) and node is BossBase:
			return node as BossBase
	return null


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
