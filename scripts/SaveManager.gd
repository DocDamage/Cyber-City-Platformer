extends Node

signal save_completed(path: String)
signal load_completed(path: String)
signal save_recovered(backup_path: String)
signal save_failed(message: String)
signal active_slot_changed(slot_id: int)

const SAVE_VERSION := 2
const SLOT_COUNT := 3
const LEGACY_PRIMARY_PATH := "user://savegame.json"
const LEGACY_BACKUP_PATH := "user://savegame.backup.json"
const LEGACY_STAGE_MAP := {
	"1-1": ["cyber_city", "rooftop_alley", "cyber_rooftop_entry"],
	"1-2": ["cyber_city", "billboard_highway", "cyber_billboard_entry"],
	"1-3": ["cyber_city", "communication_spire", "cyber_spire_entry"],
	"1-4": ["cyber_city", "skybridge_junction", "cyber_skybridge_entry"],
	"1-5": ["cyber_city", "executive_helipad", "cyber_helipad_entry"],
	"2-1": ["robot_factory", "sub_level_intake", "factory_intake_entry"],
	"2-2": ["robot_factory", "conveyor_assembly", "factory_conveyor_entry"],
	"2-3": ["robot_factory", "smelting_core", "factory_smelting_entry"],
	"2-4": ["robot_factory", "robotic_maintenance", "factory_maintenance_entry"],
	"2-5": ["robot_factory", "assembly_engine", "factory_engine_entry"],
	"3-1": ["neon_moon", "lunar_surface_arrival", "moon_surface_entry"],
	"3-2": ["neon_moon", "research_cleanrooms", "moon_cleanroom_entry"],
	"3-3": ["neon_moon", "security_grid_shaft", "moon_security_entry"],
	"3-4": ["neon_moon", "bio_tech_labs", "moon_biotech_entry"],
	"3-5": ["neon_moon", "orbital_command", "moon_command_entry"],
	"4-1": ["abyssal_night", "corrupted_outpost", "void_outpost_entry"],
	"4-2": ["abyssal_night", "the_dark_chasm", "void_chasm_entry"],
	"4-3": ["abyssal_night", "bio_mechanical_nest", "void_nest_entry"],
	"4-4": ["abyssal_night", "abyssal_sanctuary", "void_sanctuary_entry"],
	"4-5": ["abyssal_night", "heart_of_the_void", "void_heart_entry"],
}

var active_slot := 1
var _last_error := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_active_slot(slot_id: int) -> bool:
	if not _valid_slot(slot_id):
		return _fail("Save slot must be between 1 and %d." % SLOT_COUNT)
	if active_slot == slot_id:
		return true
	active_slot = slot_id
	active_slot_changed.emit(active_slot)
	return true


func save_game(slot_id := -1) -> bool:
	if not _persistence_enabled():
		return true
	var slot := _resolve_slot(slot_id)
	if not _valid_slot(slot):
		return _fail("Cannot save invalid slot %d." % slot)
	var manager := get_node_or_null("/root/GameManager")
	if manager == null:
		return _fail("SaveManager requires GameManager.")
	var game_data: Dictionary = manager.call(&"get_save_data")
	var summary: Dictionary = manager.call(&"get_save_summary") if manager.has_method(&"get_save_summary") else {}
	var settings_manager := get_node_or_null("/root/SettingsManager")
	var payload := {
		"version": SAVE_VERSION,
		"saved_at_utc": Time.get_datetime_string_from_system(true),
		"slot_id": slot,
		"summary": summary,
		"game": game_data,
		"settings": settings_manager.call(&"get_all_settings") if settings_manager != null else {},
	}
	payload["checksum"] = _checksum(payload)
	var primary := get_primary_path(slot)
	var backup := get_backup_path(slot)
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


func load_game(change_scene := true, slot_id := -1) -> bool:
	if not _persistence_enabled():
		return _fail("Headless persistence requires CCP_TEST_SAVE_DIR.")
	var slot := _resolve_slot(slot_id)
	if not _valid_slot(slot):
		return _fail("Cannot load invalid slot %d." % slot)
	active_slot = slot
	var primary := get_primary_path(slot)
	var data := _read_valid(primary, slot)
	var loaded_path := primary
	var recovered := false
	if data.is_empty():
		loaded_path = get_backup_path(slot)
		data = _read_valid(loaded_path, slot)
		recovered = not data.is_empty()
	if data.is_empty() and slot == 1:
		loaded_path = _legacy_path(false)
		data = _read_valid(loaded_path, slot)
		if data.is_empty():
			loaded_path = _legacy_path(true)
			data = _read_valid(loaded_path, slot)
			recovered = not data.is_empty()
	if data.is_empty():
		return _fail("No valid primary or backup save is available for slot %d." % slot)
	var manager := get_node_or_null("/root/GameManager")
	if manager == null or not manager.call(&"restore_save_data", data.get("game", {})):
		return _fail("Save data could not be restored into GameManager.")
	var settings_manager := get_node_or_null("/root/SettingsManager")
	if settings_manager != null and settings_manager.has_method(&"restore_settings"):
		settings_manager.call(&"restore_settings", data.get("settings", {}))
	_last_error = ""
	load_completed.emit(loaded_path)
	if recovered:
		save_recovered.emit(loaded_path)
		if FileAccess.file_exists(primary):
			DirAccess.remove_absolute(_absolute(primary))
		save_game(slot)
	elif loaded_path != primary:
		# A valid legacy save is installed into the slot-aware format on load.
		save_game(slot)
	if change_scene:
		var scene_path := String(manager.run_state.stage_scene)
		if scene_path.is_empty() and ResourceLoader.exists("res://scenes/world/WorldRoot.tscn", "PackedScene"):
			scene_path = "res://scenes/world/WorldRoot.tscn"
		if scene_path.is_empty() or not ResourceLoader.exists(scene_path, "PackedScene"):
			return _fail("Saved gameplay scene is unavailable: %s" % scene_path)
		manager.call(&"change_level", scene_path)
	return true


func has_valid_save(slot_id := -1) -> bool:
	if not _persistence_enabled():
		return false
	var slot := _resolve_slot(slot_id)
	if not _valid_slot(slot):
		return false
	if not _read_valid(get_primary_path(slot), slot).is_empty() or not _read_valid(get_backup_path(slot), slot).is_empty():
		return true
	return slot == 1 and (not _read_valid(_legacy_path(false), slot).is_empty() or not _read_valid(_legacy_path(true), slot).is_empty())


func get_save_summary(slot_id := -1) -> Dictionary:
	var slot := _resolve_slot(slot_id)
	var data := _best_payload(slot)
	if data.is_empty():
		return {}
	var result := (data.get("game", {}) as Dictionary).duplicate(true)
	result["summary"] = (data.get("summary", {}) as Dictionary).duplicate(true)
	result["saved_at_utc"] = String(data.get("saved_at_utc", ""))
	result["slot_id"] = slot
	return result


func get_slot_summaries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot: int in range(1, SLOT_COUNT + 1):
		var payload := _best_payload(slot)
		var entry := {
			"slot_id": slot,
			"status": get_slot_status(slot),
			"saved_at_utc": String(payload.get("saved_at_utc", "")),
			"summary": (payload.get("summary", {}) as Dictionary).duplicate(true) if not payload.is_empty() else {},
		}
		result.append(entry)
	return result


func get_most_recent_slot() -> int:
	var newest_slot := -1
	var newest_timestamp := ""
	for entry: Dictionary in get_slot_summaries():
		if StringName(entry.status) not in [&"valid", &"recoverable", &"legacy"]:
			continue
		var timestamp := String(entry.saved_at_utc)
		if newest_slot < 0 or timestamp > newest_timestamp:
			newest_slot = int(entry.slot_id)
			newest_timestamp = timestamp
	return newest_slot


func get_slot_status(slot_id: int) -> StringName:
	if not _valid_slot(slot_id):
		return &"invalid"
	if not _read_valid(get_primary_path(slot_id), slot_id).is_empty():
		return &"valid"
	if not _read_valid(get_backup_path(slot_id), slot_id).is_empty():
		return &"recoverable"
	if slot_id == 1 and (not _read_valid(_legacy_path(false), slot_id).is_empty() or not _read_valid(_legacy_path(true), slot_id).is_empty()):
		return &"legacy"
	if FileAccess.file_exists(get_primary_path(slot_id)) or FileAccess.file_exists(get_backup_path(slot_id)):
		return &"corrupt"
	return &"empty"


func reset_save(slot_id := -1) -> void:
	if not _persistence_enabled():
		return
	var slot := _resolve_slot(slot_id)
	if not _valid_slot(slot):
		return
	for path: String in [get_primary_path(slot), get_backup_path(slot), "%s.tmp" % get_primary_path(slot)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(_absolute(path))


func reset_all_slots() -> void:
	for slot: int in range(1, SLOT_COUNT + 1):
		reset_save(slot)


func get_last_error() -> String:
	return _last_error


func get_primary_path(slot_id := -1) -> String:
	var slot := _resolve_slot(slot_id)
	var test_directory := OS.get_environment("CCP_TEST_SAVE_DIR")
	return test_directory.path_join("save_slot_%d.json" % slot) if not test_directory.is_empty() else "user://saves/save_slot_%d.json" % slot


func get_backup_path(slot_id := -1) -> String:
	var slot := _resolve_slot(slot_id)
	var test_directory := OS.get_environment("CCP_TEST_SAVE_DIR")
	return test_directory.path_join("save_slot_%d.backup.json" % slot) if not test_directory.is_empty() else "user://saves/save_slot_%d.backup.json" % slot


func _best_payload(slot: int) -> Dictionary:
	var data := _read_valid(get_primary_path(slot), slot)
	if data.is_empty():
		data = _read_valid(get_backup_path(slot), slot)
	if data.is_empty() and slot == 1:
		data = _read_valid(_legacy_path(false), slot)
	if data.is_empty() and slot == 1:
		data = _read_valid(_legacy_path(true), slot)
	return data


func _read_valid(path: String, slot: int) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = parser.data
	if parsed is not Dictionary:
		return {}
	var payload := _migrate(parsed as Dictionary, slot)
	if payload.is_empty():
		return {}
	var stored_checksum := String(payload.get("checksum", ""))
	var checksum_payload := payload.duplicate(true)
	checksum_payload.erase("checksum")
	if stored_checksum.is_empty() or stored_checksum != _checksum(checksum_payload):
		return {}
	if payload.get("game", {}) is not Dictionary:
		return {}
	return payload


func _migrate(payload: Dictionary, slot: int) -> Dictionary:
	var version := int(payload.get("version", 0))
	if version == SAVE_VERSION:
		if int(payload.get("slot_id", slot)) != slot:
			return {}
		return payload
	if version == 1:
		if not _legacy_checksum_is_valid(payload):
			return {}
		return _build_v2_payload(payload.get("game", {}), payload.get("settings", {}), String(payload.get("saved_at_utc", "")), slot)
	if version == 0 and payload.has("run_state") and payload.has("campaign_progress"):
		return _build_v2_payload({"run_state": payload.run_state, "campaign_progress": payload.campaign_progress}, {}, Time.get_datetime_string_from_system(true), slot)
	return {}


func _build_v2_payload(old_game_value: Variant, settings_value: Variant, saved_at: String, slot: int) -> Dictionary:
	var old_game: Dictionary = old_game_value if old_game_value is Dictionary else {}
	var run_state: Dictionary = (old_game.get("run_state", {}) as Dictionary).duplicate(true)
	var stage_id := String(run_state.get("stage_id", "1-1"))
	var location: Array = LEGACY_STAGE_MAP.get(stage_id, LEGACY_STAGE_MAP["1-1"])
	var profile := CharacterProfile.new()
	var equipment := EquipmentState.new()
	equipment.clear(&"sword")
	var inventory := InventoryState.new()
	inventory.add_item(StringName(equipment.main_weapon_id), 1, true)
	var abilities := AbilityState.new()
	var world := WorldProgress.new()
	world.current_region_id = String(location[0])
	world.current_district_id = String(location[1])
	world.current_room_id = String(location[2])
	world.spawn_connection_id = "legacy_migration"
	world.discovered_rooms = {world.current_room_id: true}
	var game := {
		"character_profile": profile.to_dict(),
		"player_stats": run_state,
		"inventory": inventory.to_dict(),
		"equipment": equipment.to_dict(),
		"abilities": abilities.to_dict(),
		"world_progress": world.to_dict(),
		"story_flags": {"legacy_save_migrated": true},
		"quest_states": {},
		"seen_cutscenes": {},
		"play_time": float((old_game.get("campaign_progress", {}) as Dictionary).get("total_play_time", 0.0)),
		"run_state": run_state,
		"campaign_progress": (old_game.get("campaign_progress", {}) as Dictionary).duplicate(true),
	}
	var summary := {
		"character_name": profile.character_name,
		"portrait_id": profile.portrait_id,
		"pronoun_set_id": String(profile.pronoun_set_id),
		"voice_profile_id": profile.voice_profile_id,
		"appearance": profile.appearance.to_dict(),
		"play_time": game.play_time,
		"region_id": world.current_region_id,
		"district_id": world.current_district_id,
		"room_id": world.current_room_id,
		"map_completion": 0.0,
		"equipped_weapon_id": equipment.main_weapon_id,
		"weapon_family_id": String(equipment.weapon_family_id),
	}
	var migrated := {
		"version": SAVE_VERSION,
		"saved_at_utc": saved_at if not saved_at.is_empty() else Time.get_datetime_string_from_system(true),
		"slot_id": slot,
		"summary": summary,
		"game": game,
		"settings": (settings_value as Dictionary).duplicate(true) if settings_value is Dictionary else {},
	}
	migrated["checksum"] = _checksum(migrated)
	return migrated


func _legacy_checksum_is_valid(payload: Dictionary) -> bool:
	var stored := String(payload.get("checksum", ""))
	if stored.is_empty():
		return false
	var body := payload.duplicate(true)
	body.erase("checksum")
	return stored == _checksum(body)


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
	DirAccess.make_dir_recursive_absolute(_absolute(path).get_base_dir())


func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path


func _legacy_path(backup: bool) -> String:
	var test_directory := OS.get_environment("CCP_TEST_SAVE_DIR")
	if not test_directory.is_empty():
		return test_directory.path_join("savegame.backup.json" if backup else "savegame.json")
	return LEGACY_BACKUP_PATH if backup else LEGACY_PRIMARY_PATH


func _resolve_slot(slot_id: int) -> int:
	return active_slot if slot_id < 0 else slot_id


func _valid_slot(slot_id: int) -> bool:
	return slot_id >= 1 and slot_id <= SLOT_COUNT


func _persistence_enabled() -> bool:
	return DisplayServer.get_name() != "headless" or not OS.get_environment("CCP_TEST_SAVE_DIR").is_empty()


func _fail(message: String) -> bool:
	_last_error = message
	push_warning(message)
	save_failed.emit(message)
	return false
