extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var registry := root.get_node("AssetRegistry")
	var manifest: Dictionary = registry.call(&"get_campaign_manifest")
	if not _require(CampaignSchema.validate(manifest).is_empty(), "Production campaign schema is invalid."):
		return
	var ordered_ids: Array[String] = []
	for act_value: Variant in manifest.get("acts", []):
		for stage_value: Variant in (act_value as Dictionary).get("stages", []):
			ordered_ids.append(String((stage_value as Dictionary).get("id", "")))
	if not _require(ordered_ids.size() == 20 and ordered_ids.front() == "1-1" and ordered_ids.back() == "4-5", "Campaign order is not deterministic."):
		return
	var invalid := manifest.duplicate(true)
	var invalid_acts: Array = invalid.get("acts", [])
	var first_stages: Array = (invalid_acts[0] as Dictionary).get("stages", [])
	(first_stages[1] as Dictionary)["id"] = "1-1"
	if not _require(not CampaignSchema.validate(invalid).is_empty(), "Duplicate campaign IDs did not fail validation."):
		return

	var run := RunState.new()
	run.player_health = 4
	run.score = 1234
	run.checkpoint_position = Vector2(80.0, 96.0)
	run.upgrades["melee_damage"] = 2
	var restored_run := RunState.new()
	if not _require(restored_run.load_dict(run.to_dict()), "RunState rejected its own serialized data."):
		return
	if not _require(restored_run.score == 1234 and restored_run.checkpoint_position == Vector2(80.0, 96.0), "RunState round trip changed values."):
		return

	var progress := CampaignProgress.new()
	progress.complete_stage("1-1", 900, 31.5)
	var restored_progress := CampaignProgress.new()
	if not _require(restored_progress.load_dict(progress.to_dict()) and restored_progress.completed_stages.has("1-1"), "CampaignProgress round trip failed."):
		return

	var manager := root.get_node("GameManager")
	manager.call(&"new_game")
	if not _require(manager.call(&"award_upgrade", &"max_health", 2), "Valid upgrade was rejected."):
		return
	if not _require(int(manager.call(&"get_upgrade_level", &"max_health")) == 2, "Upgrade did not change run state."):
		return
	var save_data: Dictionary = manager.call(&"get_save_data")
	manager.call(&"new_game")
	if not _require(manager.call(&"restore_save_data", save_data), "GameManager could not restore serialized state."):
		return
	if not _require(int(manager.call(&"get_upgrade_level", &"max_health")) == 2, "Restored upgrade level is incorrect."):
		return
	print("STATE_SCHEMA_TEST_OK stages=20 score=1234 upgrade=2")
	quit()


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
