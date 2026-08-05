extends Node

## Persistent, independent music/SFX mixer. Music uses two players so changing
## Acts can crossfade, while repeat requests during stage transitions do not
## restart the current track.

const SFX_POOL_SIZE := 10
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const DEFAULT_MUSIC_VOLUME_DB := -9.0
const DEFAULT_SFX_VOLUME_DB := -5.0
const CROSSFADE_TIME := 0.55

const SFX_STREAMS := {
	&"laser_shot": preload("res://SFX/Library/FREE Retro Action Platformer Sound Effects/Weapon Discharge - Laser.mp3"),
	&"sword_slash": preload("res://SFX/Library/FREE Retro Action Platformer Sound Effects/Woosh_1.ogg"),
	&"explosion": preload("res://SFX/Library/FREE Retro Action Platformer Sound Effects/Shell Explosion_1.ogg"),
	&"player_hurt": preload("res://SFX/Library/FREE Retro Action Platformer Sound Effects/Thudd2.ogg"),
	&"jump": preload("res://SFX/Library/FREE Retro Action Platformer Sound Effects/Snap_3.ogg"),
	&"dash": preload("res://SFX/Library/FREE Retro Action Platformer Sound Effects/Woosh_4.ogg"),
	&"pickup": preload("res://SFX/Library/FREE Retro Action Platformer Sound Effects/sucess1.mp3"),
	&"checkpoint": preload("res://SFX/Library/FREE Retro Action Platformer Sound Effects/Transition.ogg"),
	&"armor_hit": preload("res://SFX/Library/FREE Retro Action Platformer Sound Effects/Clang3.ogg"),
	&"phase_change": preload("res://SFX/Library/FREE Retro Action Platformer Sound Effects/brass1.mp3"),
}

const SFX_ALIASES := {
	&"laser": &"laser_shot",
	&"melee": &"sword_slash",
	&"hurt": &"player_hurt",
}

const ACT_BGM := {
	1: preload("res://Music/Library/Rooftops 2/cyberpunk city 2.ogg"),
	2: preload("res://Music/Library/Robot Factory/Mega Robot Factory – 2 .ogg"),
	3: preload("res://Music/Library/Street Beats/DavidKBD - Street Beat - System Glitch-essential-edition.ogg"),
	4: preload("res://Music/Library/Boss Battles/Loops/Ogg/6. Dread Requiem (Loop).ogg"),
}

const BOSS_BGM := {
	1: preload("res://Music/Library/Boss Battles/Loops/Ogg/1. Abyssal Tyrant (Loop).ogg"),
	2: preload("res://Music/Library/Boss Battles/Loops/Ogg/2. Soulrend Sovereign (Loop).ogg"),
	3: preload("res://Music/Library/Boss Battles/Loops/Ogg/3. Veil of the Forsaken (Loop).ogg"),
	4: preload("res://Music/Library/Boss Battles/Loops/Ogg/6. Dread Requiem (Loop).ogg"),
}

var _music_players: Array[AudioStreamPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _active_music_index := 0
var _sfx_cursor := 0
var _current_music_key := ""
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_bus(MUSIC_BUS)
	_ensure_audio_bus(SFX_BUS)
	_build_music_players()
	_build_sfx_pool()


func play_sfx(
		effect_name: StringName,
		_world_position := Vector2.ZERO,
		volume_db := DEFAULT_SFX_VOLUME_DB
) -> void:
	if _sfx_players.is_empty() or DisplayServer.get_name() == "headless":
		return
	var canonical_name: StringName = SFX_ALIASES.get(effect_name, effect_name)
	var stream := SFX_STREAMS.get(canonical_name) as AudioStream
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
	var stream := ACT_BGM.get(act_number) as AudioStream
	if stream == null:
		push_warning("AudioManager has no background track for Act %d." % act_number)
		return
	_crossfade_to(stream, "act:%d" % act_number, volume_db)


func play_boss_bgm(act_number: int, volume_db := -7.0) -> void:
	var stream := BOSS_BGM.get(act_number) as AudioStream
	if stream == null:
		play_bgm(act_number, volume_db)
		return
	_crossfade_to(stream, "boss:%d" % act_number, volume_db)


func play_music(stream_path: String, volume_db := DEFAULT_MUSIC_VOLUME_DB) -> void:
	if stream_path.is_empty():
		return
	var stream := load(stream_path) as AudioStream
	if stream == null:
		push_warning("AudioManager could not load music: %s" % stream_path)
		return
	_crossfade_to(stream, "path:%s" % stream_path, volume_db)


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


func _exit_tree() -> void:
	for player: AudioStreamPlayer in _music_players:
		player.stop()
		player.stream = null
	stop_all_sfx()


func get_loaded_sfx_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for value: Variant in SFX_STREAMS:
		names.append(value as StringName)
	return names


func get_configured_act_count() -> int:
	return ACT_BGM.size()


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


func _ensure_audio_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
