extends Node

signal setting_changed(setting_id: StringName, value: Variant)

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	if not InputMap.has_action(action) or event == null:
		return false
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	return true


func save_settings() -> bool:
	if not _persistence_enabled():
		return true
	var path := get_settings_path()
	var temporary := "%s.tmp" % path
	DirAccess.make_dir_recursive_absolute(_absolute(path).get_base_dir())
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "settings": _settings}, "  "))
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
	return true


func reset_defaults() -> void:
	_settings = DEFAULT_SETTINGS.duplicate(true)
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
