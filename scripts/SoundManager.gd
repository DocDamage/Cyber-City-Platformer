extends Node

const SAMPLE_RATE := 22050
const EFFECT_POOL_SIZE := 8
const DEFAULT_MUSIC := "res://assets/Music/Rooftops/Cyberpunk Rooftops.mp3"

var _music_player: AudioStreamPlayer
var _effect_players: Array[AudioStreamPlayer2D] = []
var _effect_cursor := 0
var _effect_streams: Dictionary = {}


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "Music"
	_music_player.volume_db = -9.0
	add_child(_music_player)

	for index in range(EFFECT_POOL_SIZE):
		var player := AudioStreamPlayer2D.new()
		player.name = "Effect%02d" % index
		player.max_distance = 900.0
		player.attenuation = 0.55
		add_child(player)
		_effect_players.append(player)

	_build_effects()


func play_music(stream_path := DEFAULT_MUSIC, volume_db := -9.0) -> void:
	if _music_player == null or stream_path.is_empty() or DisplayServer.get_name() == "headless":
		return
	if _music_player.playing and _music_player.stream != null \
			and _music_player.stream.resource_path == stream_path:
		return
	var stream := load(stream_path)
	if stream == null:
		push_warning("SoundManager could not load music: %s" % stream_path)
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()


func stop_music(fade_time := 0.35) -> void:
	if _music_player == null or not _music_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -45.0, fade_time)
	await tween.finished
	_music_player.stop()


func play_sfx(effect: StringName, world_position := Vector2.ZERO, volume_db := -5.0) -> void:
	if not _effect_streams.has(effect) or _effect_players.is_empty():
		return
	var player := _effect_players[_effect_cursor]
	_effect_cursor = (_effect_cursor + 1) % _effect_players.size()
	player.global_position = world_position
	player.stream = _effect_streams[effect]
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.96, 1.04)
	player.play()


func _exit_tree() -> void:
	if _music_player != null:
		_music_player.stop()
		_music_player.stream = null
	for player in _effect_players:
		player.stop()
		player.stream = null
	_effect_streams.clear()


func _build_effects() -> void:
	_effect_streams[&"laser"] = _make_effect(&"laser", 0.14)
	_effect_streams[&"melee"] = _make_effect(&"melee", 0.12)
	_effect_streams[&"jump"] = _make_effect(&"jump", 0.11)
	_effect_streams[&"dash"] = _make_effect(&"dash", 0.16)
	_effect_streams[&"explosion"] = _make_effect(&"explosion", 0.34)
	_effect_streams[&"pickup"] = _make_effect(&"pickup", 0.18)
	_effect_streams[&"checkpoint"] = _make_effect(&"checkpoint", 0.36)
	_effect_streams[&"hurt"] = _make_effect(&"hurt", 0.16)


func _make_effect(kind: StringName, duration: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = hash(kind)
	var phase := 0.0

	for index in range(sample_count):
		var t := float(index) / SAMPLE_RATE
		var progress := t / duration
		var envelope := pow(1.0 - progress, 1.6)
		var frequency := 220.0
		var sample := 0.0
		match kind:
			&"laser":
				frequency = lerpf(1150.0, 190.0, progress)
				phase += TAU * frequency / SAMPLE_RATE
				sample = (sin(phase) * 0.68 + signf(sin(phase * 0.51)) * 0.16) * envelope
			&"melee":
				frequency = lerpf(180.0, 70.0, progress)
				phase += TAU * frequency / SAMPLE_RATE
				sample = (random.randf_range(-1.0, 1.0) * 0.55 + sin(phase) * 0.35) * envelope
			&"jump":
				frequency = lerpf(220.0, 720.0, progress)
				phase += TAU * frequency / SAMPLE_RATE
				sample = signf(sin(phase)) * 0.42 * envelope
			&"dash":
				frequency = lerpf(95.0, 420.0, progress)
				phase += TAU * frequency / SAMPLE_RATE
				sample = (sin(phase) * 0.35 + random.randf_range(-0.3, 0.3)) * envelope
			&"explosion":
				frequency = lerpf(100.0, 38.0, progress)
				phase += TAU * frequency / SAMPLE_RATE
				sample = (random.randf_range(-1.0, 1.0) * 0.68 + sin(phase) * 0.38) * envelope
			&"pickup":
				frequency = 660.0 if progress < 0.45 else 990.0
				phase += TAU * frequency / SAMPLE_RATE
				sample = sin(phase) * 0.52 * envelope
			&"checkpoint":
				var note_index := mini(int(progress * 4.0), 3)
				frequency = [330.0, 440.0, 660.0, 880.0][note_index]
				phase += TAU * frequency / SAMPLE_RATE
				sample = sin(phase) * 0.48 * (0.55 + envelope * 0.45)
			&"hurt":
				frequency = lerpf(190.0, 75.0, progress)
				phase += TAU * frequency / SAMPLE_RATE
				sample = (signf(sin(phase)) * 0.32 + random.randf_range(-0.35, 0.35)) * envelope
		bytes.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
