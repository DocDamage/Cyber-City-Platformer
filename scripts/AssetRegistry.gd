extends Node

const CAMPAIGN_MANIFEST_PATH := "res://Stages/campaign_manifest.json"
const RUNTIME_ASSET_ROOT := "res://assets/runtime"
const PROP_ROOT := RUNTIME_ASSET_ROOT + "/props"
const CHARACTER_TEXTURE_ROOT := RUNTIME_ASSET_ROOT + "/characters"
const STAGE_TEXTURE_ROOT := RUNTIME_ASSET_ROOT + "/environments"
const CHARACTER_ROOT := "res://Characters"
const STAGE_ROOT := "res://Stages"
const ENEMY_FRAMES_ROOT := "res://Characters/Enemies/SpriteFrames"
const ENEMY_SCENES_ROOT := "res://Characters/Enemies/Scenes"
const ENEMY_INDEX_PATH := "res://Characters/Enemies/enemy_library.json"
const MUSIC_ROOT := RUNTIME_ASSET_ROOT + "/audio/music"
const SFX_ROOT := RUNTIME_ASSET_ROOT + "/audio/sfx"
const PARALLAX_ROOT := RUNTIME_ASSET_ROOT + "/environments/parallax"
const VFX_ROOT := RUNTIME_ASSET_ROOT + "/vfx"

const FALLBACK_TEXTURE_PATH := "res://icon.svg"
const FALLBACK_PLAYER_SCENE_PATH := "res://scenes/Player.tscn"
const FALLBACK_CHARACTER_SCENE_PATH := "res://scenes/EnemyBase.tscn"
const FALLBACK_STAGE_SCENE_PATH := "res://scenes/Level.tscn"

const TEXTURE_EXTENSIONS := ["png", "svg", "jpg", "jpeg", "webp", "tres", "res"]
const SCENE_EXTENSIONS := ["tscn", "scn"]
const SPRITE_FRAMES_EXTENSIONS := ["tres", "res"]
const AUDIO_EXTENSIONS := ["ogg", "wav", "mp3"]
const CHARACTER_FOLDER_ALIASES := {
	"player": "Player",
	"enemy": "Enemies",
	"enemies": "Enemies",
	"boss": "Bosses",
	"bosses": "Bosses",
}

var _campaign: Dictionary = {}
var _enemy_library: Dictionary = {}
var _resource_cache: Dictionary = {}
var _missing_cache: Dictionary = {}
var _warned_requests: Dictionary = {}
var _fallback_texture: Texture2D
var _fallback_player_scene: PackedScene
var _fallback_character_scene: PackedScene
var _fallback_stage_scene: PackedScene
var _fallback_enemy_frames: SpriteFrames
var _campaign_validation_errors := PackedStringArray()


func _ready() -> void:
	_ensure_campaign_loaded()


func get_prop_texture(act_number: int, prop_name: String) -> Texture2D:
	var cache_key := "prop:%d:%s" % [act_number, prop_name]
	if _resource_cache.has(cache_key):
		return _resource_cache[cache_key] as Texture2D
	if _missing_cache.has(cache_key):
		return _get_fallback_texture()

	var act := get_act_info(act_number)
	if act.is_empty() or not _is_safe_relative_path(prop_name):
		return _missing_prop(cache_key, act_number, prop_name)

	var roots: Array = [PROP_ROOT.path_join(String(act.get("prop_folder", "")))]
	var resource := _load_named_resource(roots, prop_name, TEXTURE_EXTENSIONS, "Texture2D")
	if resource is Texture2D:
		_resource_cache[cache_key] = resource
		return resource as Texture2D
	return _missing_prop(cache_key, act_number, prop_name)


func get_character_texture(character_folder: String, texture_name: String) -> Texture2D:
	var canonical_folder := _canonical_character_folder(character_folder)
	var cache_key := "character_texture:%s:%s" % [canonical_folder, texture_name]
	if _resource_cache.has(cache_key):
		return _resource_cache[cache_key] as Texture2D
	if _missing_cache.has(cache_key):
		return _get_fallback_texture()

	if canonical_folder.is_empty() or not _is_safe_relative_path(texture_name):
		return _missing_character_texture(cache_key, character_folder, texture_name)

	var roots: Array = [CHARACTER_TEXTURE_ROOT.path_join(canonical_folder)]
	var resource := _load_named_resource(roots, texture_name, TEXTURE_EXTENSIONS, "Texture2D")
	if resource is Texture2D:
		_resource_cache[cache_key] = resource
		return resource as Texture2D
	return _missing_character_texture(cache_key, character_folder, texture_name)


func get_character_scene(character_folder: String, character_name: String) -> PackedScene:
	var canonical_folder := _canonical_character_folder(character_folder)
	var cache_key := "character:%s:%s" % [canonical_folder, character_name]
	if _resource_cache.has(cache_key):
		return _resource_cache[cache_key] as PackedScene
	if _missing_cache.has(cache_key):
		return _get_fallback_character_scene(canonical_folder)

	if canonical_folder.is_empty() or not _is_safe_relative_path(character_name):
		return _missing_character(cache_key, character_folder, character_name, canonical_folder)

	var roots: Array = [CHARACTER_ROOT.path_join(canonical_folder)]
	var resource := _load_named_resource(roots, character_name, SCENE_EXTENSIONS, "PackedScene")
	if resource is PackedScene:
		_resource_cache[cache_key] = resource
		return resource as PackedScene
	return _missing_character(cache_key, character_folder, character_name, canonical_folder)


func get_enemy_sprite_frames(enemy_name: StringName) -> SpriteFrames:
	var enemy_id := _canonical_enemy_id(String(enemy_name))
	var cache_key := "enemy_frames:%s" % enemy_id
	if _resource_cache.has(cache_key):
		return _resource_cache[cache_key] as SpriteFrames
	if enemy_id.is_empty():
		return _get_fallback_enemy_frames()
	var resource := _load_named_resource(
		[ENEMY_FRAMES_ROOT], enemy_id, SPRITE_FRAMES_EXTENSIONS, "SpriteFrames"
	)
	if resource is SpriteFrames:
		_resource_cache[cache_key] = resource
		return resource as SpriteFrames
	_warn_once(cache_key, "Could not find enemy SpriteFrames '%s'; using Goblin." % enemy_name)
	return _get_fallback_enemy_frames()


func get_enemy_scene(enemy_name: StringName) -> PackedScene:
	var enemy_id := _canonical_enemy_id(String(enemy_name))
	var cache_key := "enemy_scene:%s" % enemy_id
	if _resource_cache.has(cache_key):
		return _resource_cache[cache_key] as PackedScene
	if not enemy_id.is_empty():
		var resource := _load_named_resource([ENEMY_SCENES_ROOT], enemy_id, SCENE_EXTENSIONS, "PackedScene")
		if resource is PackedScene:
			_resource_cache[cache_key] = resource
			return resource as PackedScene
	_warn_once(cache_key, "Could not find enemy scene '%s'; using %s." % [enemy_name, FALLBACK_CHARACTER_SCENE_PATH])
	return _get_fallback_character_scene("Enemies")


func get_enemy_library() -> Dictionary:
	if _enemy_library.is_empty() and FileAccess.file_exists(ENEMY_INDEX_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENEMY_INDEX_PATH))
		if parsed is Dictionary:
			_enemy_library = parsed
	return _enemy_library.duplicate(true)


func get_enemy_info(enemy_name: StringName) -> Dictionary:
	var enemy_id := _canonical_enemy_id(String(enemy_name))
	var enemies: Array = get_enemy_library().get("enemies", [])
	for value: Variant in enemies:
		if value is Dictionary and String((value as Dictionary).get("id", "")) == enemy_id:
			return (value as Dictionary).duplicate(true)
	return {}


func get_music_stream(track_name: String) -> AudioStream:
	return _get_audio_stream(MUSIC_ROOT, "music", track_name)


func get_sfx_stream(sound_name: String) -> AudioStream:
	return _get_audio_stream(SFX_ROOT, "sfx", sound_name)


func get_parallax_texture(texture_name: String) -> Texture2D:
	return _get_library_texture(PARALLAX_ROOT, "parallax", texture_name)


func get_vfx_texture(texture_name: String) -> Texture2D:
	return _get_library_texture(VFX_ROOT, "vfx", texture_name)


func get_stage_texture(act_number: int, texture_name: String) -> Texture2D:
	var cache_key := "stage_texture:%d:%s" % [act_number, texture_name]
	if _resource_cache.has(cache_key):
		return _resource_cache[cache_key] as Texture2D
	if _missing_cache.has(cache_key):
		return _get_fallback_texture()

	var act := get_act_info(act_number)
	if act.is_empty() or not _is_safe_relative_path(texture_name):
		return _missing_stage_texture(cache_key, act_number, texture_name)

	var roots: Array = [STAGE_TEXTURE_ROOT.path_join(String(act.get("folder", "")))]
	var resource := _load_named_resource(roots, texture_name, TEXTURE_EXTENSIONS, "Texture2D")
	if resource is Texture2D:
		_resource_cache[cache_key] = resource
		return resource as Texture2D
	return _missing_stage_texture(cache_key, act_number, texture_name)


func get_stage_background_texture(act_number: int, background_name: String) -> Texture2D:
	return get_stage_texture(act_number, background_name)


func get_level_background_texture(act_number: int, background_name: String) -> Texture2D:
	return get_stage_background_texture(act_number, background_name)


func get_stage_scene(act_number: int, substage_number: int) -> PackedScene:
	var cache_key := "stage:%d:%d" % [act_number, substage_number]
	if _resource_cache.has(cache_key):
		return _resource_cache[cache_key] as PackedScene
	if _missing_cache.has(cache_key):
		return _get_fallback_stage_scene()

	var stage := get_stage_info(act_number, substage_number)
	if stage.is_empty():
		_missing_cache[cache_key] = true
		_warn_once(cache_key, "No campaign entry exists for act %d, sub-stage %d; using %s." % [
			act_number, substage_number, FALLBACK_STAGE_SCENE_PATH,
		])
		return _get_fallback_stage_scene()

	var scene_path := String(stage.get("scene", ""))
	var resource := _load_resource_path(scene_path, "PackedScene")
	if resource is PackedScene:
		_resource_cache[cache_key] = resource
		return resource as PackedScene

	var act := get_act_info(act_number)
	var act_root := STAGE_ROOT.path_join(String(act.get("folder", "")))
	var lookup_names: Array = [
		String(stage.get("id", "")),
		String(stage.get("slug", "")),
		String(stage.get("name", "")),
	]
	for lookup_name: String in lookup_names:
		resource = _load_named_resource([act_root], lookup_name, SCENE_EXTENSIONS, "PackedScene")
		if resource is PackedScene:
			_resource_cache[cache_key] = resource
			return resource as PackedScene

	_missing_cache[cache_key] = true
	_warn_once(cache_key, "Stage %s (%s) has no scene yet; using %s." % [
		String(stage.get("id", "unknown")), String(stage.get("name", "Unnamed")), FALLBACK_STAGE_SCENE_PATH,
	])
	return _get_fallback_stage_scene()


func get_campaign_manifest() -> Dictionary:
	_ensure_campaign_loaded()
	return _campaign.duplicate(true)


func get_campaign_validation_errors() -> PackedStringArray:
	_ensure_campaign_loaded()
	return _campaign_validation_errors.duplicate()


func get_act_info(act_number: int) -> Dictionary:
	_ensure_campaign_loaded()
	var acts: Array = _campaign.get("acts", [])
	for value: Variant in acts:
		if value is Dictionary:
			var act: Dictionary = value
			if int(act.get("number", -1)) == act_number:
				return act.duplicate(true)
	return {}


func get_stage_info(act_number: int, substage_number: int) -> Dictionary:
	var act := get_act_info(act_number)
	var stages: Array = act.get("stages", [])
	for value: Variant in stages:
		if value is Dictionary:
			var stage: Dictionary = value
			if int(stage.get("number", -1)) == substage_number:
				return stage.duplicate(true)
	return {}


func get_character_folder_info(character_folder: String) -> Dictionary:
	_ensure_campaign_loaded()
	var canonical_folder := _canonical_character_folder(character_folder)
	var characters: Dictionary = _campaign.get("characters", {})
	var value: Variant = characters.get(canonical_folder, {})
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func clear_cache() -> void:
	_resource_cache.clear()
	_missing_cache.clear()
	_warned_requests.clear()
	_enemy_library.clear()


func reload_campaign_manifest() -> void:
	_campaign.clear()
	clear_cache()
	_ensure_campaign_loaded()


func _ensure_campaign_loaded() -> void:
	if not _campaign.is_empty():
		return
	if not FileAccess.file_exists(CAMPAIGN_MANIFEST_PATH):
		_warn_once("manifest:missing", "Campaign manifest is missing at %s." % CAMPAIGN_MANIFEST_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMPAIGN_MANIFEST_PATH))
	if parsed is Dictionary:
		_campaign = parsed
		_campaign_validation_errors = CampaignSchema.validate(_campaign)
		for failure: String in _campaign_validation_errors:
			push_error("Campaign manifest: %s" % failure)
	else:
		_warn_once("manifest:invalid", "Campaign manifest is not valid JSON: %s." % CAMPAIGN_MANIFEST_PATH)


func _canonical_character_folder(character_folder: String) -> String:
	if not _is_safe_relative_path(character_folder):
		return ""
	var normalized := _normalize_lookup_name(character_folder)
	return String(CHARACTER_FOLDER_ALIASES.get(normalized, character_folder.strip_edges()))


func _canonical_enemy_id(enemy_name: String) -> String:
	if not _is_safe_relative_path(enemy_name):
		return ""
	return enemy_name.strip_edges().to_snake_case().to_lower()


func _get_audio_stream(root_path: String, kind: String, requested_name: String) -> AudioStream:
	if not _is_safe_relative_path(requested_name):
		_warn_once("%s:unsafe:%s" % [kind, requested_name], "Rejected unsafe %s path '%s'." % [kind, requested_name])
		return null
	var cache_key := "%s:%s" % [kind, requested_name]
	if _resource_cache.has(cache_key):
		return _resource_cache[cache_key] as AudioStream
	var resource := _load_named_resource([root_path], requested_name, AUDIO_EXTENSIONS, "AudioStream")
	if resource is AudioStream:
		_resource_cache[cache_key] = resource
		return resource as AudioStream
	_warn_once(cache_key, "Could not find %s '%s' under %s." % [kind, requested_name, root_path])
	return null


func _get_library_texture(root_path: String, kind: String, requested_name: String) -> Texture2D:
	var cache_key := "%s:%s" % [kind, requested_name]
	if _resource_cache.has(cache_key):
		return _resource_cache[cache_key] as Texture2D
	if not _is_safe_relative_path(requested_name):
		_warn_once(cache_key, "Rejected unsafe %s path '%s'." % [kind, requested_name])
		return _get_fallback_texture()
	var resource := _load_named_resource([root_path], requested_name, TEXTURE_EXTENSIONS, "Texture2D")
	if resource is Texture2D:
		_resource_cache[cache_key] = resource
		return resource as Texture2D
	_warn_once(cache_key, "Could not find %s texture '%s'; using %s." % [kind, requested_name, FALLBACK_TEXTURE_PATH])
	return _get_fallback_texture()


func _load_named_resource(
		roots: Array,
		requested_name: String,
		extensions: Array,
		type_hint: String
) -> Resource:
	for root_value: Variant in roots:
		var root := String(root_value).trim_suffix("/")
		if root.is_empty():
			continue
		var direct := _load_direct_candidate(root, requested_name, extensions, type_hint)
		if direct != null:
			return direct

	var target := _normalize_lookup_name(requested_name)
	for root_value: Variant in roots:
		var root := String(root_value).trim_suffix("/")
		if root.is_empty() or not DirAccess.dir_exists_absolute(root):
			continue
		var matches: Array[String] = []
		_collect_matching_paths(root, target, extensions, matches)
		matches.sort()
		for path: String in matches:
			var resource := _load_resource_path(path, type_hint)
			if resource != null:
				return resource
	return null


func _load_direct_candidate(root: String, requested_name: String, extensions: Array, type_hint: String) -> Resource:
	var relative_path := requested_name.strip_edges().replace("\\", "/").trim_prefix("/")
	var extension := relative_path.get_extension().to_lower()
	var candidates: Array[String] = []
	if extensions.has(extension):
		candidates.append(root.path_join(relative_path))
	else:
		for candidate_extension: String in extensions:
			candidates.append(root.path_join("%s.%s" % [relative_path, candidate_extension]))
	for path: String in candidates:
		var resource := _load_resource_path(path, type_hint)
		if resource != null:
			return resource
	return null


func _load_resource_path(path: String, type_hint: String) -> Resource:
	if path.is_empty() or not ResourceLoader.exists(path, type_hint):
		return null
	return ResourceLoader.load(path, type_hint, ResourceLoader.CACHE_MODE_REUSE)


func _collect_matching_paths(
		directory_path: String,
		target: String,
		extensions: Array,
		matches: Array[String]
) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	for file_name: String in directory.get_files():
		if extensions.has(file_name.get_extension().to_lower()) and _normalize_lookup_name(file_name) == target:
			matches.append(directory_path.path_join(file_name))
	for child_name: String in directory.get_directories():
		if not child_name.begins_with("."):
			_collect_matching_paths(directory_path.path_join(child_name), target, extensions, matches)


func _normalize_lookup_name(value: String) -> String:
	var normalized := value.replace("\\", "/").get_file().get_basename().to_lower()
	for token: String in [" ", "_", "-", ".", "(", ")", "'"]:
		normalized = normalized.replace(token, "")
	return normalized


func _is_safe_relative_path(value: String) -> bool:
	var path := value.strip_edges().replace("\\", "/")
	if path.is_empty() or path.is_absolute_path() or path.contains(":"):
		return false
	for segment: String in path.split("/", false):
		if segment == "..":
			return false
	return true


func _append_paths(target: Array, values: Variant) -> void:
	if values is not Array:
		return
	for value: Variant in values:
		var path := String(value)
		if not path.is_empty() and not target.has(path):
			target.append(path)


func _missing_prop(cache_key: String, act_number: int, prop_name: String) -> Texture2D:
	_missing_cache[cache_key] = true
	_warn_once(cache_key, "Could not find prop '%s' for act %d; using %s." % [
		prop_name, act_number, FALLBACK_TEXTURE_PATH,
	])
	return _get_fallback_texture()


func _missing_character_texture(cache_key: String, character_folder: String, texture_name: String) -> Texture2D:
	_missing_cache[cache_key] = true
	_warn_once(cache_key, "Could not find character texture '%s' in '%s'; using %s." % [
		texture_name, character_folder, FALLBACK_TEXTURE_PATH,
	])
	return _get_fallback_texture()


func _missing_stage_texture(cache_key: String, act_number: int, texture_name: String) -> Texture2D:
	_missing_cache[cache_key] = true
	_warn_once(cache_key, "Could not find stage texture '%s' for act %d; using %s." % [
		texture_name, act_number, FALLBACK_TEXTURE_PATH,
	])
	return _get_fallback_texture()


func _missing_character(
		cache_key: String,
		character_folder: String,
		character_name: String,
		canonical_folder: String
) -> PackedScene:
	_missing_cache[cache_key] = true
	var fallback := FALLBACK_PLAYER_SCENE_PATH if canonical_folder == "Player" else FALLBACK_CHARACTER_SCENE_PATH
	_warn_once(cache_key, "Could not find character '%s' in '%s'; using %s." % [
		character_name, character_folder, fallback,
	])
	return _get_fallback_character_scene(canonical_folder)


func _warn_once(key: String, message: String) -> void:
	if _warned_requests.has(key):
		return
	_warned_requests[key] = true
	push_warning("AssetRegistry: %s" % message)


func _get_fallback_texture() -> Texture2D:
	if _fallback_texture == null:
		_fallback_texture = load(FALLBACK_TEXTURE_PATH) as Texture2D
	return _fallback_texture


func _get_fallback_character_scene(canonical_folder: String) -> PackedScene:
	if canonical_folder == "Player":
		if _fallback_player_scene == null:
			_fallback_player_scene = load(FALLBACK_PLAYER_SCENE_PATH) as PackedScene
		return _fallback_player_scene
	if _fallback_character_scene == null:
		_fallback_character_scene = load(FALLBACK_CHARACTER_SCENE_PATH) as PackedScene
	return _fallback_character_scene


func _get_fallback_stage_scene() -> PackedScene:
	if _fallback_stage_scene == null:
		_fallback_stage_scene = load(FALLBACK_STAGE_SCENE_PATH) as PackedScene
	return _fallback_stage_scene


func _get_fallback_enemy_frames() -> SpriteFrames:
	if _fallback_enemy_frames == null:
		_fallback_enemy_frames = load(ENEMY_FRAMES_ROOT.path_join("goblin.tres")) as SpriteFrames
	if _fallback_enemy_frames == null:
		_fallback_enemy_frames = SpriteFrames.new()
	return _fallback_enemy_frames
