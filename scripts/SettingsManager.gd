extends Node

signal setting_changed(setting_id: StringName, value: Variant)
signal input_device_changed(device_family: StringName)
signal action_binding_changed(action: StringName)

const RESOLUTION_OPTIONS: Array[String] = ["960x540", "1280x720", "1600x900", "1920x1080", "2560x1440"]
const MINIMUM_WINDOW_DECORATION := Vector2i(16, 48)

const CONTROLLER_BUTTON_LABELS := {
	0: "A / CROSS",
	1: "B / CIRCLE",
	2: "X / SQUARE",
	3: "Y / TRIANGLE",
	4: "VIEW / SHARE",
	5: "GUIDE",
	6: "MENU / OPTIONS",
	7: "L3",
	8: "R3",
	9: "LB / L1",
	10: "RB / R1",
	11: "DPAD UP",
	12: "DPAD DOWN",
	13: "DPAD LEFT",
	14: "DPAD RIGHT",
}
const CONTROLLER_AXIS_LABELS := {
	"0:-1": "LEFT STICK LEFT",
	"0:1": "LEFT STICK RIGHT",
	"1:-1": "LEFT STICK UP",
	"1:1": "LEFT STICK DOWN",
	"2:-1": "RIGHT STICK LEFT",
	"2:1": "RIGHT STICK RIGHT",
	"3:-1": "RIGHT STICK UP",
	"3:1": "RIGHT STICK DOWN",
	"4:1": "LT / L2",
	"5:1": "RT / R2",
}

const REBINDABLE_ACTIONS: Array[StringName] = [
	&"ui_left",
	&"ui_right",
	&"ui_up",
	&"ui_down",
	&"ui_accept",
	&"ui_cancel",
	&"attack_melee",
	&"attack_shoot",
	&"slide_dash",
	&"interact",
	&"pause_game",
	&"teleport",
	&"teleport_cancel",
	&"aim_left",
	&"aim_right",
	&"aim_up",
	&"aim_down",
	&"open_map",
	&"open_inventory",
	&"skip_cutscene",
	&"dialogue_backlog",
]

const DEFAULT_SETTINGS := {
	"master_volume": 1.0,
	"music_volume": 0.85,
	"sfx_volume": 0.9,
	"ui_volume": 0.9,
	"ambience_volume": 0.85,
	"voice_volume": 0.9,
	"barks_enabled": true,
	"bark_subtitles": true,
	"fullscreen": false,
	"resolution": "1280x720",
	"vsync": true,
	"screen_shake_intensity": 1.0,
	"controller_vibration": true,
	"controller_vibration_strength": 1.0,
	"controller_deadzone": 0.2,
	"aim_deadzone": 0.22,
	"aim_response": 0.72,
	"reduced_flashing": false,
	"hit_stop_scale": 1.0,
	"high_contrast_interactables": false,
	"hold_to_interact": false,
	"ui_scale": 1.0,
	"text_speed": 1.0,
	"instant_text": false,
	"auto_advance": false,
	"aim_assist_strength": 0.25,
	"teleport_aim_behavior": "hold",
	"high_contrast_teleport_reticle": false,
}

var _settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var _default_bindings: Dictionary = {}
var _active_input_family: StringName = &"keyboard_mouse"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_capture_default_bindings()
	load_settings()
	_apply_all.call_deferred()


func _input(event: InputEvent) -> void:
	var family := _input_device_family(event)
	if family.is_empty() or family == _active_input_family:
		return
	_active_input_family = family
	input_device_changed.emit(family)


func get_setting(setting_id: StringName, fallback: Variant = null) -> Variant:
	return _settings.get(String(setting_id), fallback)


func get_all_settings() -> Dictionary:
	return _settings.duplicate(true)


func get_resolution_options() -> Array[String]:
	return RESOLUTION_OPTIONS.duplicate()


func set_setting(setting_id: StringName, value: Variant, persist := true) -> bool:
	var key := String(setting_id)
	if not DEFAULT_SETTINGS.has(key):
		return false
	var normalized: Variant = _normalize(key, value)
	_settings[key] = normalized
	_apply(key, normalized)
	setting_changed.emit(setting_id, _settings.get(key, normalized))
	if persist:
		save_settings()
	return true


func rebind_action(action: StringName, event: InputEvent) -> bool:
	if action not in REBINDABLE_ACTIONS or not InputMap.has_action(action) or event == null:
		return false
	var family := _event_family(event)
	if family.is_empty():
		return false
	var preserved: Array[InputEvent] = []
	for existing: InputEvent in InputMap.action_get_events(action):
		if _event_family(existing) != family:
			preserved.append(existing)
	InputMap.action_erase_events(action)
	for existing: InputEvent in preserved:
		InputMap.action_add_event(action, existing)
	InputMap.action_add_event(action, event)
	action_binding_changed.emit(action)
	save_settings()
	return true


func get_active_input_family() -> StringName:
	return _active_input_family


func get_action_binding_text(action: StringName, family: StringName = &"") -> String:
	if not InputMap.has_action(action):
		return "Unbound"
	var labels: Array[String] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if not family.is_empty() and _prompt_family(event) != family:
			continue
		var label := _binding_label(event)
		if not label.is_empty() and label not in labels:
			labels.append(label)
	return " / ".join(labels) if not labels.is_empty() else "Unbound"


func get_action_prompt(action: StringName) -> String:
	return get_action_binding_text(action, _active_input_family)


func save_settings() -> bool:
	if not _persistence_enabled():
		return true
	var path := get_settings_path()
	var temporary := "%s.tmp" % path
	DirAccess.make_dir_recursive_absolute(_absolute(path).get_base_dir())
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({
		"version": 2,
		"settings": _settings,
		"bindings": _serialize_bindings(),
	}, "  "))
	file.close()
	var target_absolute := _absolute(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(target_absolute)
	return DirAccess.rename_absolute(_absolute(temporary), target_absolute) == OK


func load_settings() -> bool:
	if not _persistence_enabled():
		return false
	var path := get_settings_path()
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is not Dictionary or (parsed as Dictionary).get("settings", {}) is not Dictionary:
		return false
	var loaded: Dictionary = (parsed as Dictionary).get("settings", {})
	for key: String in DEFAULT_SETTINGS:
		if loaded.has(key):
			_settings[key] = _normalize(key, loaded[key])
	var bindings: Variant = (parsed as Dictionary).get("bindings", {})
	if bindings is Dictionary:
		_apply_serialized_bindings(bindings)
	return true


func reset_defaults() -> void:
	_settings = DEFAULT_SETTINGS.duplicate(true)
	_restore_default_bindings()
	_apply_all()
	for action: StringName in REBINDABLE_ACTIONS:
		action_binding_changed.emit(action)
	save_settings()


func get_settings_path() -> String:
	var test_directory := OS.get_environment("CCP_TEST_SAVE_DIR")
	return test_directory.path_join("settings.json") if not test_directory.is_empty() else "user://settings.json"


func _apply_all() -> void:
	for key: String in _settings:
		_apply(key, _settings[key])


func _apply(key: String, value: Variant) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	match key:
		"master_volume":
			if audio != null: audio.call(&"set_master_volume", float(value))
		"music_volume":
			if audio != null: audio.call(&"set_music_volume", float(value))
		"sfx_volume":
			if audio != null: audio.call(&"set_sfx_volume", float(value))
		"ui_volume":
			if audio != null: audio.call(&"set_ui_volume", float(value))
		"ambience_volume":
			if audio != null: audio.call(&"set_ambience_volume", float(value))
		"voice_volume":
			if audio != null: audio.call(&"set_voice_volume", float(value))
		"fullscreen":
			if DisplayServer.get_name() != "headless":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(value) else DisplayServer.WINDOW_MODE_WINDOWED)
				if not bool(value):
					_apply_windowed_resolution(String(_settings.get("resolution", DEFAULT_SETTINGS.resolution)))
		"resolution":
			if DisplayServer.get_name() != "headless" and not bool(_settings.get("fullscreen", false)):
				_apply_windowed_resolution(String(value))
		"vsync":
			if DisplayServer.get_name() != "headless":
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(value) else DisplayServer.VSYNC_DISABLED)
		"ui_scale":
			get_tree().root.content_scale_factor = float(value)


func _normalize(key: String, value: Variant) -> Variant:
	match key:
		"master_volume", "music_volume", "sfx_volume", "ui_volume", "ambience_volume", "voice_volume": return clampf(float(value), 0.0, 1.0)
		"screen_shake_intensity": return clampf(float(value), 0.0, 1.0)
		"hit_stop_scale", "aim_assist_strength", "controller_vibration_strength": return clampf(float(value), 0.0, 1.0)
		"controller_deadzone", "aim_deadzone": return clampf(float(value), 0.05, 0.8)
		"aim_response": return clampf(float(value), 0.1, 1.0)
		"ui_scale": return clampf(float(value), 0.75, 1.5)
		"text_speed": return clampf(float(value), 0.5, 2.0)
		"fullscreen", "vsync", "controller_vibration", "reduced_flashing", "high_contrast_interactables", "hold_to_interact", "barks_enabled", "bark_subtitles", "instant_text", "auto_advance", "high_contrast_teleport_reticle": return bool(value)
		"teleport_aim_behavior": return String(value) if String(value) in ["hold", "tap"] else "hold"
		"resolution":
			return String(value) if String(value) in RESOLUTION_OPTIONS else "1280x720"
	return value


func fit_windowed_resolution(requested: Vector2i, usable_size: Vector2i, decoration_size: Vector2i = Vector2i.ZERO) -> Vector2i:
	var reserved := Vector2i(
		maxi(decoration_size.x, MINIMUM_WINDOW_DECORATION.x),
		maxi(decoration_size.y, MINIMUM_WINDOW_DECORATION.y)
	)
	var maximum_client := Vector2i(
		maxi(1, usable_size.x - reserved.x),
		maxi(1, usable_size.y - reserved.y)
	)
	for option_index in range(RESOLUTION_OPTIONS.size() - 1, -1, -1):
		var candidate := _parse_resolution(RESOLUTION_OPTIONS[option_index])
		if candidate.x <= requested.x and candidate.y <= requested.y and candidate.x <= maximum_client.x and candidate.y <= maximum_client.y:
			return candidate
	return _parse_resolution(RESOLUTION_OPTIONS[0])


func _apply_windowed_resolution(value: String) -> void:
	var requested := _parse_resolution(value)
	if requested == Vector2i.ZERO:
		requested = _parse_resolution(String(DEFAULT_SETTINGS.resolution))
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var client_size := DisplayServer.window_get_size()
	var decorated_size := DisplayServer.window_get_size_with_decorations()
	var decoration := Vector2i(
		maxi(0, decorated_size.x - client_size.x),
		maxi(0, decorated_size.y - client_size.y)
	)
	var fitted := fit_windowed_resolution(requested, usable.size, decoration)
	var fitted_text := "%dx%d" % [fitted.x, fitted.y]
	if String(_settings.get("resolution", "")) != fitted_text:
		_settings["resolution"] = fitted_text
		setting_changed.emit(&"resolution", fitted_text)
	DisplayServer.window_set_size(fitted)
	var reserved := Vector2i(
		maxi(decoration.x, MINIMUM_WINDOW_DECORATION.x),
		maxi(decoration.y, MINIMUM_WINDOW_DECORATION.y)
	)
	var outer_size := fitted + reserved
	DisplayServer.window_set_position(usable.position + (usable.size - outer_size) / 2)


func _parse_resolution(value: String) -> Vector2i:
	var parts := value.split("x")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(parts[0].to_int(), parts[1].to_int())


func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path


func _persistence_enabled() -> bool:
	return DisplayServer.get_name() != "headless" or not OS.get_environment("CCP_TEST_SAVE_DIR").is_empty()


func _capture_default_bindings() -> void:
	_default_bindings.clear()
	for action: StringName in REBINDABLE_ACTIONS:
		_default_bindings[action] = InputMap.action_get_events(action).duplicate(true)


func _restore_default_bindings() -> void:
	for action: StringName in REBINDABLE_ACTIONS:
		InputMap.action_erase_events(action)
		for event: InputEvent in (_default_bindings.get(action, []) as Array):
			InputMap.action_add_event(action, event)


func _serialize_bindings() -> Dictionary:
	var result := {}
	for action: StringName in REBINDABLE_ACTIONS:
		var events: Array[Dictionary] = []
		for event: InputEvent in InputMap.action_get_events(action):
			var encoded := _serialize_event(event)
			if not encoded.is_empty():
				events.append(encoded)
		result[String(action)] = events
	return result


func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key := event as InputEventKey
		return {"type": "key", "keycode": key.keycode, "physical_keycode": key.physical_keycode}
	if event is InputEventJoypadButton:
		return {"type": "joy_button", "button_index": (event as InputEventJoypadButton).button_index}
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return {"type": "joy_motion", "axis": motion.axis, "axis_value": motion.axis_value}
	if event is InputEventMouseButton:
		return {"type": "mouse_button", "button_index": (event as InputEventMouseButton).button_index}
	return {}


func _apply_serialized_bindings(bindings: Dictionary) -> void:
	for action: StringName in REBINDABLE_ACTIONS:
		var encoded_events: Variant = bindings.get(String(action), null)
		if encoded_events is not Array or (encoded_events as Array).is_empty():
			continue
		var decoded: Array[InputEvent] = []
		for encoded: Variant in encoded_events:
			if encoded is Dictionary:
				var event := _deserialize_event(encoded)
				if event != null:
					decoded.append(event)
		if decoded.is_empty():
			continue
		InputMap.action_erase_events(action)
		for event: InputEvent in decoded:
			InputMap.action_add_event(action, event)


func _deserialize_event(encoded: Dictionary) -> InputEvent:
	match String(encoded.get("type", "")):
		"key":
			var key := InputEventKey.new()
			key.keycode = int(encoded.get("keycode", 0)) as Key
			key.physical_keycode = int(encoded.get("physical_keycode", 0)) as Key
			return key
		"joy_button":
			var button := InputEventJoypadButton.new()
			button.button_index = int(encoded.get("button_index", 0)) as JoyButton
			return button
		"joy_motion":
			var motion := InputEventJoypadMotion.new()
			motion.axis = int(encoded.get("axis", 0)) as JoyAxis
			motion.axis_value = float(encoded.get("axis_value", 0.0))
			return motion
		"mouse_button":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = int(encoded.get("button_index", 1)) as MouseButton
			return mouse
	return null


func _event_family(event: InputEvent) -> StringName:
	if event is InputEventKey:
		return &"keyboard"
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return &"controller"
	if event is InputEventMouseButton:
		return &"mouse"
	return &""


func _prompt_family(event: InputEvent) -> StringName:
	return &"controller" if event is InputEventJoypadButton or event is InputEventJoypadMotion else &"keyboard_mouse"


func _input_device_family(event: InputEvent) -> StringName:
	if event is InputEventKey:
		var key := event as InputEventKey
		return &"keyboard_mouse" if key.pressed and not key.echo else &""
	if event is InputEventMouseButton:
		return &"keyboard_mouse" if (event as InputEventMouseButton).pressed else &""
	if event is InputEventMouseMotion:
		return &"keyboard_mouse" if (event as InputEventMouseMotion).relative.length_squared() >= 4.0 else &""
	if event is InputEventJoypadButton:
		return &"controller" if (event as InputEventJoypadButton).pressed else &""
	if event is InputEventJoypadMotion:
		return &"controller" if absf((event as InputEventJoypadMotion).axis_value) >= float(_settings.get("controller_deadzone", 0.2)) else &""
	return &""


func _binding_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		var label := OS.get_keycode_string(code)
		if label.is_empty() and key.unicode > 0:
			label = String.chr(key.unicode)
		return label.to_upper()
	if event is InputEventMouseButton:
		return "MOUSE %d" % int((event as InputEventMouseButton).button_index)
	if event is InputEventJoypadButton:
		var button := int((event as InputEventJoypadButton).button_index)
		return String(CONTROLLER_BUTTON_LABELS.get(button, "BUTTON %d" % button))
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		var direction := -1 if motion.axis_value < 0.0 else 1
		var key := "%d:%d" % [int(motion.axis), direction]
		return String(CONTROLLER_AXIS_LABELS.get(key, "AXIS %d %s" % [int(motion.axis), "-" if direction < 0 else "+"]))
	return event.as_text().trim_suffix(" (Physical)")
