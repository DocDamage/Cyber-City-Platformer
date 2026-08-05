extends Node

signal setting_changed(setting_id: StringName, value: Variant)

const REBINDABLE_ACTIONS: Array[StringName] = [
	&"ui_left",
	&"ui_right",
	&"ui_accept",
	&"attack_melee",
	&"attack_shoot",
	&"slide_dash",
	&"interact",
	&"pause_game",
]

const DEFAULT_SETTINGS := {
	"master_volume": 1.0,
	"music_volume": 0.85,
	"sfx_volume": 0.9,
	"fullscreen": false,
	"resolution": "1280x720",
	"vsync": true,
	"screen_shake_intensity": 1.0,
	"controller_vibration": true,
	"controller_deadzone": 0.2,
	"reduced_flashing": false,
	"high_contrast_interactables": false,
	"hold_to_interact": false,
	"ui_scale": 1.0,
	"text_speed": 1.0,
}

var _settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var _default_bindings: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_capture_default_bindings()
	load_settings()
	_apply_all.call_deferred()


func get_setting(setting_id: StringName, fallback: Variant = null) -> Variant:
	return _settings.get(String(setting_id), fallback)


func get_all_settings() -> Dictionary:
	return _settings.duplicate(true)


func set_setting(setting_id: StringName, value: Variant, persist := true) -> bool:
	var key := String(setting_id)
	if not DEFAULT_SETTINGS.has(key):
		return false
	var normalized: Variant = _normalize(key, value)
	_settings[key] = normalized
	_apply(key, normalized)
	setting_changed.emit(setting_id, normalized)
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
	save_settings()
	return true


func get_action_binding_text(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "Unbound"
	var labels: Array[String] = []
	for event: InputEvent in InputMap.action_get_events(action):
		var label := event.as_text().trim_suffix(" (Physical)")
		if not label.is_empty() and label not in labels:
			labels.append(label)
	return " / ".join(labels) if not labels.is_empty() else "Unbound"


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
		"fullscreen":
			if DisplayServer.get_name() != "headless":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(value) else DisplayServer.WINDOW_MODE_WINDOWED)
		"resolution":
			if DisplayServer.get_name() != "headless" and not bool(_settings.get("fullscreen", false)):
				var parts := String(value).split("x")
				if parts.size() == 2:
					DisplayServer.window_set_size(Vector2i(parts[0].to_int(), parts[1].to_int()))
		"vsync":
			if DisplayServer.get_name() != "headless":
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(value) else DisplayServer.VSYNC_DISABLED)
		"ui_scale":
			get_tree().root.content_scale_factor = float(value)


func _normalize(key: String, value: Variant) -> Variant:
	match key:
		"master_volume", "music_volume", "sfx_volume": return clampf(float(value), 0.0, 1.0)
		"screen_shake_intensity": return clampf(float(value), 0.0, 1.0)
		"controller_deadzone": return clampf(float(value), 0.05, 0.8)
		"ui_scale": return clampf(float(value), 0.75, 1.5)
		"text_speed": return clampf(float(value), 0.5, 2.0)
		"fullscreen", "vsync", "controller_vibration", "reduced_flashing", "high_contrast_interactables", "hold_to_interact": return bool(value)
		"resolution":
			return String(value) if String(value) in ["1280x720", "1600x900", "1920x1080", "2560x1440"] else "1280x720"
	return value


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
