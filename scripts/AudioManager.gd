extends Node

## Persistent music/SFX mixer. All external streams are loaded defensively so
## an optional missing file can never prevent this autoload from compiling.

const SAMPLE_RATE := 22050
const SFX_POOL_SIZE := 10
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const DEFAULT_MUSIC_VOLUME_DB := -9.0
const DEFAULT_SFX_VOLUME_DB := -5.0
const CROSSFADE_TIME := 0.55

const SFX_PATHS := {
	&"laser_shot": "res://assets/runtime/audio/sfx/FREE Retro Action Platformer Sound Effects/Weapon Discharge - Laser.mp3",
	&"sword_slash": "res://assets/runtime/audio/sfx/FREE Retro Action Platformer Sound Effects/Woosh_1.ogg",
	&"explosion": "res://assets/runtime/audio/sfx/FREE Retro Action Platformer Sound Effects/Shell Explosion_1.ogg",
	&"player_hurt": "res://assets/runtime/audio/sfx/FREE Retro Action Platformer Sound Effects/Thudd2.ogg",
	&"jump": "res://assets/runtime/audio/sfx/FREE Retro Action Platformer Sound Effects/Snap_3.ogg",
	&"dash": "res://assets/runtime/audio/sfx/FREE Retro Action Platformer Sound Effects/Woosh_4.ogg",
	&"pickup": "res://assets/runtime/audio/sfx/FREE Retro Action Platformer Sound Effects/sucess1.mp3",
	&"checkpoint": "res://assets/runtime/audio/sfx/FREE Retro Action Platformer Sound Effects/Transition.ogg",
	&"armor_hit": "res://assets/runtime/audio/sfx/FREE Retro Action Platformer Sound Effects/Clang3.ogg",
	&"phase_change": "res://assets/runtime/audio/sfx/FREE Retro Action Platformer Sound Effects/brass1.mp3",
}
const ACT_BGM_PATHS := {
	1: "res://assets/runtime/audio/music/Rooftops 2/cyberpunk city 2.ogg",
	2: "res://assets/runtime/audio/music/Robot Factory/Mega Robot Factory – 2 .ogg",
	3: "res://assets/runtime/audio/music/Street Beats/DavidKBD - Street Beat - System Glitch-essential-edition.ogg",
	4: "res://assets/runtime/audio/music/Boss Battles/Loops/Ogg/6. Dread Requiem (Loop).ogg",
}
const BOSS_BGM_PATHS := {
	1: "res://assets/runtime/audio/music/Boss Battles/Loops/Ogg/1. Abyssal Tyrant (Loop).ogg",
	2: "res://assets/runtime/audio/music/Boss Battles/Loops/Ogg/2. Soulrend Sovereign (Loop).ogg",
	3: "res://assets/runtime/audio/music/Boss Battles/Loops/Ogg/3. Veil of the Forsaken (Loop).ogg",
	4: "res://assets/runtime/audio/music/Boss Battles/Loops/Ogg/6. Dread Requiem (Loop).ogg",
}
const SFX_ALIASES := {
	&"laser": &"laser_shot",
	&"melee": &"sword_slash",
	&"hurt": &"player_hurt",
}
const FALLBACK_DURATIONS := {
	&"laser_shot": 0.14,
	&"sword_slash": 0.12,
	&"jump": 0.11,
	&"dash": 0.16,
	&"explosion": 0.34,
	&"pickup": 0.18,
	&"checkpoint": 0.36,
	&"player_hurt": 0.16,
	&"armor_hit": 0.13,
	&"phase_change": 0.42,
}

var _music_players: Array[AudioStreamPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}
var _act_music: Dictionary = {}
var _boss_music: Dictionary = {}
var _missing_audio: Array[String] = []
var _active_music_index := 0
var _sfx_cursor := 0
var _current_music_key := ""
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_bus(MUSIC_BUS)
	_ensure_audio_bus(SFX_BUS)
	_load_audio_manifest()
	_build_music_players()
	_build_sfx_pool()


func play_sfx(effect_name: StringName, _world_position := Vector2.ZERO, volume_db := DEFAULT_SFX_VOLUME_DB) -> void:
	if _sfx_players.is_empty() or DisplayServer.get_name() == "headless":
		return
	var canonical_name: StringName = SFX_ALIASES.get(effect_name, effect_name)
	var stream := _sfx_streams.get(canonical_name) as AudioStream
	if stream == null:
		push_warning("AudioManager has no SFX named '%s'." % effect_name)
		return
	var player := _sfx_players[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.96, 1.04)
	player.play()


func play_bgm(act_number: int, volume_db := DEFAULT_MUSIC_VOLUME_DB) -> void:
	_crossfade_to(_act_music.get(act_number) as AudioStream, "act:%d" % act_number, volume_db)


func play_boss_bgm(act_number: int, volume_db := -7.0) -> void:
	var stream := _boss_music.get(act_number) as AudioStream
	if stream == null:
		stream = _act_music.get(act_number) as AudioStream
	_crossfade_to(stream, "boss:%d" % act_number, volume_db)


func play_music(stream_path: String, volume_db := DEFAULT_MUSIC_VOLUME_DB) -> void:
	if stream_path.is_empty():
		return
	_crossfade_to(_safe_load_audio(stream_path), "path:%s" % stream_path, volume_db)


func stop_music(fade_time := 0.35) -> void:
	_current_music_key = ""
	var has_active_music := false
	for player: AudioStreamPlayer in _music_players:
		if player.playing:
			has_active_music = true
			break
	if not has_active_music:
		return
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	for player: AudioStreamPlayer in _music_players:
		if player.playing:
			_music_tween.tween_property(player, "volume_db", -45.0, fade_time)
	await _music_tween.finished
	for player: AudioStreamPlayer in _music_players:
		player.stop()
		player.stream = null


func stop_all_sfx() -> void:
	for player: AudioStreamPlayer in _sfx_players:
		player.stop()
		player.stream = null


func set_master_volume(linear_value: float) -> void:
	_set_bus_volume(&"Master", linear_value)


func set_music_volume(linear_value: float) -> void:
	_set_bus_volume(MUSIC_BUS, linear_value)


func set_sfx_volume(linear_value: float) -> void:
	_set_bus_volume(SFX_BUS, linear_value)


func set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), muted)


func get_loaded_sfx_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for value: Variant in _sfx_streams:
		names.append(value as StringName)
	return names


func get_configured_act_count() -> int:
	return ACT_BGM_PATHS.size()


func get_missing_audio_paths() -> Array[String]:
	return _missing_audio.duplicate()


func _load_audio_manifest() -> void:
	for key: StringName in SFX_PATHS:
		var path := String(SFX_PATHS[key])
		var stream := _safe_load_audio(path)
		_sfx_streams[key] = stream if stream != null else _make_effect(key, float(FALLBACK_DURATIONS[key]))
	for act_number: int in ACT_BGM_PATHS:
		_act_music[act_number] = _safe_load_audio(String(ACT_BGM_PATHS[act_number]))
	for act_number: int in BOSS_BGM_PATHS:
		_boss_music[act_number] = _safe_load_audio(String(BOSS_BGM_PATHS[act_number]))


func _safe_load_audio(path: String) -> AudioStream:
	var force_missing := OS.get_environment("CCP_TEST_AUDIO_MISSING") == "1"
	if force_missing or path.is_empty() or not ResourceLoader.exists(path, "AudioStream"):
		if not _missing_audio.has(path):
			_missing_audio.append(path)
			push_warning("AudioManager: optional audio is unavailable: %s" % path)
		return null
	return ResourceLoader.load(path, "AudioStream", ResourceLoader.CACHE_MODE_REUSE) as AudioStream


func _crossfade_to(stream: AudioStream, music_key: String, volume_db: float) -> void:
	if stream == null or _music_players.size() < 2 or DisplayServer.get_name() == "headless":
		return
	var current := _music_players[_active_music_index]
	if _current_music_key == music_key and current.playing:
		return
	_current_music_key = music_key
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	var incoming_index := 1 - _active_music_index
	var incoming := _music_players[incoming_index]
	incoming.stop()
	incoming.stream = stream
	_set_looping(stream)
	incoming.volume_db = -45.0
	incoming.play()
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(incoming, "volume_db", volume_db, CROSSFADE_TIME)
	if current.playing:
		_music_tween.tween_property(current, "volume_db", -45.0, CROSSFADE_TIME)
	_active_music_index = incoming_index
	await _music_tween.finished
	if current != _music_players[_active_music_index]:
		current.stop()
		current.stream = null


func _make_effect(kind: StringName, duration: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = hash(kind)
	var phase := 0.0
	for index in range(sample_count):
		var progress := float(index) / float(sample_count)
		var envelope := pow(1.0 - progress, 1.6)
		var frequency := lerpf(980.0, 95.0, progress)
		phase += TAU * frequency / SAMPLE_RATE
		var tonal := sin(phase) * 0.48
		var noise := random.randf_range(-0.28, 0.28)
		var sample := (tonal + noise) * envelope
		bytes.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _set_looping(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true


func _build_music_players() -> void:
	for index in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "BGMPlayer%d" % index
		player.bus = MUSIC_BUS
		player.volume_db = -45.0
		add_child(player)
		_music_players.append(player)


func _build_sfx_pool() -> void:
	for index in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%02d" % index
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)


func _set_bus_volume(bus_name: StringName, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(linear_value, 0.0, 1.0)))


func _ensure_audio_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _exit_tree() -> void:
	for player: AudioStreamPlayer in _music_players:
		player.stop()
		player.stream = null
	stop_all_sfx()
