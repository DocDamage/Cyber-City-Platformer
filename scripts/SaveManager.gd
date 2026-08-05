extends Node

signal save_completed(path: String)
signal load_completed(path: String)
signal save_recovered(backup_path: String)
signal save_failed(message: String)

const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://savegame.json"
const DEFAULT_BACKUP_PATH := "user://savegame.backup.json"

var _last_error := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func save_game() -> bool:
	if not _persistence_enabled():
		return true
	var manager := get_node_or_null("/root/GameManager")
	if manager == null:
		return _fail("SaveManager requires GameManager.")
	var game_data: Dictionary = manager.call(&"get_save_data")
	var settings_manager := get_node_or_null("/root/SettingsManager")
	var payload := {
		"version": SAVE_VERSION,
		"saved_at_utc": Time.get_datetime_string_from_system(true),
		"game": game_data,
		"settings": settings_manager.call(&"get_all_settings") if settings_manager != null else {},
	}
	payload["checksum"] = _checksum(payload)
	var primary := get_primary_path()
	var backup := get_backup_path()
	var temporary := "%s.tmp" % primary
	_ensure_parent_directory(primary)
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _fail("Could not open temporary save file: %s" % temporary)
	file.store_string(JSON.stringify(payload, "  "))
	file.flush()
	file.close()
	var primary_absolute := _absolute(primary)
	var backup_absolute := _absolute(backup)
	var temporary_absolute := _absolute(temporary)
	if FileAccess.file_exists(primary):
		var copy_error := DirAccess.copy_absolute(primary_absolute, backup_absolute)
		if copy_error != OK:
			return _fail("Could not create save backup (error %s)." % copy_error)
		DirAccess.remove_absolute(primary_absolute)
	var rename_error := DirAccess.rename_absolute(temporary_absolute, primary_absolute)
	if rename_error != OK:
		return _fail("Could not atomically install save file (error %s)." % rename_error)
	_last_error = ""
	save_completed.emit(primary)
	return true


func load_game(change_scene := true) -> bool:
	if not _persistence_enabled():
		return _fail("Headless persistence requires CCP_TEST_SAVE_DIR.")
	var primary := get_primary_path()
	var data := _read_valid(primary)
	var loaded_path := primary
	var recovered := false
	if data.is_empty():
		loaded_path = get_backup_path()
		data = _read_valid(loaded_path)
		recovered = not data.is_empty()
	if data.is_empty():
		return _fail("No valid primary or backup save is available.")
	var manager := get_node_or_null("/root/GameManager")
	if manager == null or not manager.call(&"restore_save_data", data.get("game", {})):
		return _fail("Save data could not be restored into GameManager.")
	_last_error = ""
	load_completed.emit(loaded_path)
	if recovered:
		save_recovered.emit(loaded_path)
		if FileAccess.file_exists(primary):
			DirAccess.remove_absolute(_absolute(primary))
		save_game()
	if change_scene:
		var scene_path := String(manager.run_state.stage_scene)
		if scene_path.is_empty() or not ResourceLoader.exists(scene_path, "PackedScene"):
			return _fail("Saved stage scene is unavailable: %s" % scene_path)
		manager.call(&"change_level", scene_path)
	return true


func has_valid_save() -> bool:
	if not _persistence_enabled():
		return false
	return not _read_valid(get_primary_path()).is_empty() or not _read_valid(get_backup_path()).is_empty()


func get_save_summary() -> Dictionary:
	var data := _read_valid(get_primary_path())
	if data.is_empty():
		data = _read_valid(get_backup_path())
	return (data.get("game", {}) as Dictionary).duplicate(true) if not data.is_empty() else {}


func reset_save() -> void:
	if not _persistence_enabled():
		return
	for path: String in [get_primary_path(), get_backup_path(), "%s.tmp" % get_primary_path()]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(_absolute(path))


func get_last_error() -> String:
	return _last_error


func get_primary_path() -> String:
	var test_directory := OS.get_environment("CCP_TEST_SAVE_DIR")
	return test_directory.path_join("savegame.json") if not test_directory.is_empty() else DEFAULT_SAVE_PATH


func get_backup_path() -> String:
	var test_directory := OS.get_environment("CCP_TEST_SAVE_DIR")
	return test_directory.path_join("savegame.backup.json") if not test_directory.is_empty() else DEFAULT_BACKUP_PATH


func _read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = parser.data
	if parsed is not Dictionary:
		return {}
	var payload: Dictionary = parsed
	var migrated := _migrate(payload)
	if migrated.is_empty():
		return {}
	var stored_checksum := String(migrated.get("checksum", ""))
	var checksum_payload := migrated.duplicate(true)
	checksum_payload.erase("checksum")
	if stored_checksum.is_empty() or stored_checksum != _checksum(checksum_payload):
		return {}
	if migrated.get("game", {}) is not Dictionary:
		return {}
	return migrated


func _migrate(payload: Dictionary) -> Dictionary:
	var version := int(payload.get("version", 0))
	if version == SAVE_VERSION:
		return payload
	if version == 0 and payload.has("run_state") and payload.has("campaign_progress"):
		var migrated := {
			"version": SAVE_VERSION,
			"saved_at_utc": Time.get_datetime_string_from_system(true),
			"game": {
				"run_state": payload.get("run_state", {}),
				"campaign_progress": payload.get("campaign_progress", {}),
			},
			"settings": {},
		}
		migrated["checksum"] = _checksum(migrated)
		return migrated
	return {}


func _checksum(payload: Dictionary) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(JSON.stringify(_canonicalize(payload)).to_utf8_buffer())
	return context.finish().hex_encode()


func _canonicalize(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		var keys: Array = (value as Dictionary).keys()
		keys.sort_custom(func(left: Variant, right: Variant) -> bool: return String(left) < String(right))
		for key: Variant in keys:
			result[String(key)] = _canonicalize((value as Dictionary)[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value:
			result.append(_canonicalize(item))
		return result
	if value is int or value is float:
		return float(value)
	return value


func _ensure_parent_directory(path: String) -> void:
	var parent := _absolute(path).get_base_dir()
	DirAccess.make_dir_recursive_absolute(parent)


func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path


func _persistence_enabled() -> bool:
	return DisplayServer.get_name() != "headless" or not OS.get_environment("CCP_TEST_SAVE_DIR").is_empty()


func _fail(message: String) -> bool:
	_last_error = message
	push_warning(message)
	save_failed.emit(message)
	return false
