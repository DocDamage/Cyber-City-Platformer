extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var save_directory := OS.get_environment("CCP_TEST_SAVE_DIR")
	if not _require(not save_directory.is_empty(), "Save test requires CCP_TEST_SAVE_DIR to protect user data."):
		return
	var save_manager := root.get_node("SaveManager")
	var settings := root.get_node("SettingsManager")
	var manager := root.get_node("GameManager")
	save_manager.call(&"reset_save")
	var settings_path := String(settings.call(&"get_settings_path"))
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_path)

	manager.call(&"new_game")
	manager.call(&"enter_stage", "1-2", "res://Stages/Act1_CyberCity/1-2_BillboardHighway/Stage.tscn")
	manager.call(&"add_score", 555)
	manager.call(&"award_upgrade", &"ranged_damage", 2)
	manager.campaign_progress.complete_stage("1-1", 555, 42.0)
	await process_frame
	save_manager.call(&"reset_save")
	if not _require(save_manager.call(&"save_game"), "Initial atomic save failed."):
		return
	manager.call(&"add_score", 222)
	if not _require(save_manager.call(&"save_game"), "Second save did not create a backup."):
		return
	if not _require(FileAccess.file_exists(save_manager.call(&"get_backup_path")), "Save backup was not created."):
		return
	var backup_payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_manager.call(&"get_backup_path")))
	var stored_checksum := String(backup_payload.get("checksum", ""))
	backup_payload.erase("checksum")
	if not _require(stored_checksum == save_manager.call(&"_checksum", backup_payload), "Fresh backup checksum is not stable after parsing."):
		return

	var corrupt := FileAccess.open(save_manager.call(&"get_primary_path"), FileAccess.WRITE)
	corrupt.store_string("{corrupt save")
	corrupt.close()
	var recovery_state := {"value": false}
	save_manager.save_recovered.connect(func(_path: String) -> void: recovery_state["value"] = true, CONNECT_ONE_SHOT)
	manager.call(&"new_game")
	if not _require(save_manager.call(&"load_game", false), "Corrupt primary did not recover from backup."):
		return
	if not _require(bool(recovery_state.value) and manager.current_score == 555, "Backup recovery restored the wrong run."):
		return
	if not _require(int(manager.call(&"get_upgrade_level", &"ranged_damage")) == 2, "Saved upgrades did not survive load."):
		return

	settings.call(&"set_setting", &"master_volume", 0.35, false)
	settings.call(&"set_setting", &"controller_deadzone", 0.4, false)
	settings.call(&"set_setting", &"reduced_flashing", true, false)
	var remapped_key := InputEventKey.new()
	remapped_key.physical_keycode = KEY_Q
	if not _require(settings.call(&"rebind_action", &"attack_melee", remapped_key), "Keyboard remap was rejected."):
		return
	if not _require(settings.call(&"save_settings"), "Settings atomic write failed."):
		return
	settings.call(&"set_setting", &"master_volume", 1.0, false)
	settings.call(&"set_setting", &"controller_deadzone", 0.1, false)
	if not _require(settings.call(&"load_settings"), "Settings reload failed."):
		return
	if not _require(is_equal_approx(float(settings.call(&"get_setting", &"master_volume")), 0.35), "Master volume did not persist."):
		return
	if not _require(is_equal_approx(float(settings.call(&"get_setting", &"controller_deadzone")), 0.4), "Controller deadzone did not persist."):
		return
	var melee_events: Array[InputEvent] = InputMap.action_get_events(&"attack_melee")
	if not _require(melee_events.any(func(event: InputEvent) -> bool: return event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_Q), "Keyboard remap did not persist."):
		return
	if not _require(melee_events.any(func(event: InputEvent) -> bool: return event is InputEventJoypadButton), "Keyboard remap removed the controller binding."):
		return
	for action: StringName in [&"ui_left", &"ui_right", &"ui_accept", &"attack_melee", &"attack_shoot", &"slide_dash", &"interact", &"pause_game"]:
		if not _require(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "Input action is missing bindings: %s" % action):
			return
	print("SAVE_SETTINGS_TEST_OK recovered=true score=", manager.current_score, " actions=8")
	save_manager.call(&"reset_save")
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_path)
	quit()


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
