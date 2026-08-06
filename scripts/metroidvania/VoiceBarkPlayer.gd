class_name VoiceBarkPlayer
extends Node

signal bark_started(profile_id: String, category: StringName, clip_path: String)
signal bark_finished
signal bark_rejected(reason: StringName)

const CATEGORY_COOLDOWNS := {
	"confirmation": 0.8,
	"greeting": 2.0,
	"damage": 0.35,
	"grunting": 0.55,
}
const CATEGORY_PRIORITIES := {
	"confirmation": 1,
	"greeting": 1,
	"damage": 3,
	"grunting": 0,
}

@export var voice_profile_id := "voice_01"
@export var barks_enabled := true
@export_range(0.0, 1.0, 0.01) var volume_linear := 1.0
@export var global_cooldown := 0.22

var _player: AudioStreamPlayer
var _last_global_time := -1000.0
var _last_category_time: Dictionary = {}
var _recent_paths: Dictionary = {}
var _active_priority := -1
var _manifest: Dictionary = {}


func _ready() -> void:
	_manifest = CreatorCatalog.voice_manifest()
	_player = get_node_or_null("AudioStreamPlayer") as AudioStreamPlayer
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.name = "AudioStreamPlayer"
		add_child(_player)
	_player.finished.connect(_on_finished)
	_player.bus = &"Voice"
	_player.volume_db = linear_to_db(maxf(volume_linear, 0.0001))
	set_voice_profile(voice_profile_id)
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null:
		barks_enabled = bool(settings.call(&"get_setting", &"barks_enabled", true))
		settings.setting_changed.connect(_on_setting_changed)


func _exit_tree() -> void:
	# AudioServer can retain a playback reference beyond the node's lifetime if a
	# streaming scene is removed while a bark is still playing. Release both the
	# playback and stream explicitly so room transitions and shutdown are clean.
	if _player != null:
		_player.stop()
		_player.stream = null
	_active_priority = -1


func set_voice_profile(profile_id: String) -> void:
	voice_profile_id = profile_id if CreatorCatalog.has_voice(profile_id) else "voice_01"


func play_bark(category: StringName, force := false) -> bool:
	if not barks_enabled:
		bark_rejected.emit(&"disabled")
		return false
	var now := Time.get_ticks_msec() / 1000.0
	var category_key := String(category)
	var priority := int(CATEGORY_PRIORITIES.get(category_key, 0))
	if not force:
		var rejection_reason := _bark_rejection_reason(category, now)
		if not rejection_reason.is_empty():
			bark_rejected.emit(rejection_reason)
			return false
	var path := _select_clip(voice_profile_id, category_key)
	if path.is_empty() or not ResourceLoader.exists(path, "AudioStream"):
		bark_rejected.emit(&"missing_clip")
		return false
	_player.stop()
	_player.stream = load(path) as AudioStream
	_player.volume_db = linear_to_db(maxf(volume_linear, 0.0001))
	_player.play()
	_active_priority = priority
	_last_global_time = now
	_last_category_time[category_key] = now
	_remember(category_key, path)
	bark_started.emit(voice_profile_id, category, path)
	return true


func _bark_rejection_reason(category: StringName, now: float) -> StringName:
	var category_key := String(category)
	if now - _last_global_time < global_cooldown:
		return &"global_cooldown"
	if now - float(_last_category_time.get(category_key, -1000.0)) < float(CATEGORY_COOLDOWNS.get(category_key, 1.0)):
		return &"category_cooldown"
	var priority := int(CATEGORY_PRIORITIES.get(category_key, 0))
	if _active_priority >= 0 and priority <= _active_priority:
		return &"priority"
	return &""


func stop_bark() -> void:
	_player.stop()
	_player.stream = null
	_active_priority = -1


func validate_manifest() -> PackedStringArray:
	var errors := PackedStringArray()
	var clips: Dictionary = _manifest.get("clips", {})
	for profile: Variant in _manifest.get("profiles", []):
		var profile_id := String((profile as Dictionary).get("id", ""))
		if not clips.has(profile_id):
			errors.append("Missing clip table for %s." % profile_id)
			continue
		for category: Variant in _manifest.get("categories", []):
			var paths: Array = (clips[profile_id] as Dictionary).get(String(category), [])
			if paths.is_empty():
				errors.append("Missing %s clip for %s." % [category, profile_id])
			continue
			for value: Variant in paths:
				if not ResourceLoader.exists(String(value), "AudioStream"):
					errors.append("Missing voice resource: %s" % value)
	return errors


func _select_clip(profile_id: String, category: String) -> String:
	var clips: Dictionary = _manifest.get("clips", {})
	var profile_clips: Dictionary = clips.get(profile_id, {})
	var paths: Array = profile_clips.get(category, [])
	if paths.is_empty():
		return ""
	var recent: Array = _recent_paths.get(category, [])
	var candidates := paths.filter(func(value: Variant) -> bool: return String(value) not in recent)
	if candidates.is_empty():
		candidates = paths.duplicate()
	return String(candidates[randi() % candidates.size()])


func _remember(category: String, path: String) -> void:
	var recent: Array = _recent_paths.get(category, [])
	recent.push_front(path)
	while recent.size() > 2:
		recent.pop_back()
	_recent_paths[category] = recent


func _on_finished() -> void:
	_active_priority = -1
	bark_finished.emit()


func _on_setting_changed(setting_id: StringName, value: Variant) -> void:
	if setting_id == &"barks_enabled":
		barks_enabled = bool(value)
		if not barks_enabled:
			stop_bark()
