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
	settings.call(&"set_setting", &"aim_deadzone", 0.46, false)
	settings.call(&"set_setting", &"aim_response", 0.35, false)
	settings.call(&"set_setting", &"reduced_flashing", true, false)
	settings.call(&"set_setting", &"voice_volume", 0.55, false)
	settings.call(&"set_setting", &"ui_volume", 0.45, false)
	settings.call(&"set_setting", &"ambience_volume", 0.65, false)
	settings.call(&"set_setting", &"teleport_aim_behavior", "tap", false)
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
	if not _require(is_equal_approx(float(settings.call(&"get_setting", &"aim_deadzone")), 0.46) and is_equal_approx(float(settings.call(&"get_setting", &"aim_response")), 0.35), "Independent teleport aim tuning did not persist."):
		return
	if not _require(is_equal_approx(float(settings.call(&"get_setting", &"voice_volume")), 0.55) and is_equal_approx(float(settings.call(&"get_setting", &"ui_volume")), 0.45) and is_equal_approx(float(settings.call(&"get_setting", &"ambience_volume")), 0.65) and String(settings.call(&"get_setting", &"teleport_aim_behavior")) == "tap", "Metroidvania accessibility settings did not persist."):
		return
	var audio := root.get_node("AudioManager")
	for bus_name: StringName in [&"Music", &"SFX", &"UI", &"Ambience", &"Voice"]:
		if not _require(AudioServer.get_bus_index(bus_name) >= 0, "Accessibility mixer bus is missing: %s" % bus_name):
			return
	if not _require(StringName(audio.call(&"get_effect_bus", &"ui_confirm")) == &"UI" and StringName(audio.call(&"get_effect_bus", &"jump")) == &"SFX", "UI and gameplay effects are not routed to independent mixer buses."):
		return
	if not _require(int(audio.call(&"get_configured_ambience_count")) == 4 and StringName(audio.call(&"get_ambience_player_bus")) == &"Ambience", "Regional ambience is not configured on the independent Ambience bus."):
		return
	var melee_events: Array[InputEvent] = InputMap.action_get_events(&"attack_melee")
	if not _require(melee_events.any(func(event: InputEvent) -> bool: return event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_Q), "Keyboard remap did not persist."):
		return
	if not _require(melee_events.any(func(event: InputEvent) -> bool: return event is InputEventJoypadButton), "Keyboard remap removed the controller binding."):
		return
	var device_changes: Array[StringName] = []
	settings.input_device_changed.connect(func(family: StringName) -> void: device_changes.append(family))
	var controller_input := InputEventJoypadButton.new()
	controller_input.button_index = JOY_BUTTON_X
	controller_input.pressed = true
	settings.call(&"_input", controller_input)
	if not _require(StringName(settings.call(&"get_active_input_family")) == &"controller" and String(settings.call(&"get_action_prompt", &"attack_melee")).contains("X / SQUARE"), "Controller activity did not immediately select the controller prompt family."):
		return
	var teleport := TeleportController.new()
	root.add_child(teleport)
	teleport.aim_direction = Vector2.RIGHT
	var retained := teleport.filtered_aim_direction(Vector2(0.0, -0.3), Vector2.LEFT, 1.0 / 60.0)
	if not _require(retained.is_equal_approx(Vector2.RIGHT), "Centered controller aim fell back to the mouse inside the independent aim deadzone."):
		return
	var softened := teleport.filtered_aim_direction(Vector2.UP, Vector2.LEFT, 1.0 / 60.0)
	settings.call(&"set_setting", &"aim_response", 1.0, false)
	var immediate := teleport.filtered_aim_direction(Vector2.UP, Vector2.LEFT, 1.0 / 60.0)
	if not _require(softened.x > 0.0 and softened.y < 0.0 and immediate.is_equal_approx(Vector2.UP), "Aim response did not independently tune stick direction smoothing."):
		return
	teleport.free()
	var keyboard_input := InputEventKey.new()
	keyboard_input.physical_keycode = KEY_Q
	keyboard_input.pressed = true
	settings.call(&"_input", keyboard_input)
	if not _require(StringName(settings.call(&"get_active_input_family")) == &"keyboard_mouse" and String(settings.call(&"get_action_prompt", &"attack_melee")) == "Q", "Keyboard activity did not immediately restore the remapped keyboard prompt."):
		return
	if not _require(device_changes == [&"controller", &"keyboard_mouse"], "Active-input signal did not report both device-family changes."):
		return
	var window_frame := Vector2i(16, 39)
	if not _require(Vector2i(settings.call(&"fit_windowed_resolution", Vector2i(1920, 1080), Vector2i(1920, 1032), window_frame)) == Vector2i(1600, 900), "Windowed 1080p did not fall back to the largest standard client size that fits a 1080p work area."):
		return
	if not _require(Vector2i(settings.call(&"fit_windowed_resolution", Vector2i(2560, 1440), Vector2i(2560, 1400), window_frame)) == Vector2i(1920, 1080), "Windowed 1440p did not reserve room for desktop chrome."):
		return
	if not _require(Vector2i(settings.call(&"fit_windowed_resolution", Vector2i(1280, 720), Vector2i(1920, 1032), window_frame)) == Vector2i(1280, 720), "A fitting windowed resolution was changed unexpectedly."):
		return
	if not _require(Vector2i(settings.call(&"fit_windowed_resolution", Vector2i(1280, 720), Vector2i(1360, 720), window_frame)) == Vector2i(960, 540), "The design-resolution fallback did not protect a short desktop work area."):
		return
	for action: StringName in settings.REBINDABLE_ACTIONS:
		if not _require(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "Input action is missing bindings: %s" % action):
			return
	var dual_input_actions: Array[StringName] = [&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"ui_accept", &"ui_cancel", &"attack_melee", &"attack_shoot", &"slide_dash", &"interact", &"pause_game", &"teleport", &"teleport_cancel", &"open_map", &"open_inventory", &"skip_cutscene"]
	for action: StringName in dual_input_actions:
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		var has_keyboard := events.any(func(event: InputEvent) -> bool: return event is InputEventKey or event is InputEventMouseButton)
		var has_controller := events.any(func(event: InputEvent) -> bool: return event is InputEventJoypadButton or event is InputEventJoypadMotion)
		if not _require(has_keyboard and has_controller, "Core navigation/gameplay action lacks keyboard or controller access: %s" % action):
			return
	var controller_owners: Dictionary = {}
	var simultaneous_actions: Array[StringName] = [&"ui_accept", &"attack_melee", &"attack_shoot", &"slide_dash", &"interact", &"pause_game", &"teleport", &"teleport_cancel", &"aim_left", &"aim_right", &"aim_up", &"aim_down", &"open_map", &"open_inventory", &"skip_cutscene", &"dialogue_backlog"]
	for action: StringName in simultaneous_actions:
		for event: InputEvent in InputMap.action_get_events(action):
			var signature := ""
			if event is InputEventJoypadButton:
				signature = "button:%d" % (event as InputEventJoypadButton).button_index
			elif event is InputEventJoypadMotion:
				var motion := event as InputEventJoypadMotion
				signature = "axis:%d:%d" % [motion.axis, signi(roundi(motion.axis_value))]
			if signature.is_empty():
				continue
			if not _require(not controller_owners.has(signature), "Controller input conflict: %s and %s both use %s." % [controller_owners.get(signature, ""), action, signature]):
				return
			controller_owners[signature] = String(action)
	print("SAVE_SETTINGS_TEST_OK recovered=true score=", manager.current_score, " actions=", settings.REBINDABLE_ACTIONS.size(), " dual_input=", dual_input_actions.size(), " controller_signatures=", controller_owners.size(), " prompt_switches=", device_changes.size())
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
