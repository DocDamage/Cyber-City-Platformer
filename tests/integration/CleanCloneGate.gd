extends SceneTree

const BOSS_SCENES := [
	"res://Characters/Bosses/Scenes/act1_helix_warden.tscn",
	"res://Characters/Bosses/Scenes/act2_assembly_colossus.tscn",
	"res://Characters/Bosses/Scenes/act3_lunar_oracle.tscn",
	"res://Characters/Bosses/Scenes/act4_void_cerberus.tscn",
]
const REQUIRED_AUTOLOADS := [
	"GameManager",
	"CombatFeedback",
	"AudioManager",
	"VFXSpawner",
	"AssetRegistry",
	"SceneTransition",
]

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(45.0, true, false, true).timeout.connect(func() -> void:
		push_error("Clean-clone gate timed out.")
		quit(1)
	)
	for autoload_name: String in REQUIRED_AUTOLOADS:
		_require(root.get_node_or_null(autoload_name) != null, "Autoload is unavailable: %s" % autoload_name)

	var registry := root.get_node_or_null("AssetRegistry")
	if registry == null:
		_finish()
		return

	var main_scene_path := String(ProjectSettings.get_setting("application/run/main_scene", ""))
	_require_scene(main_scene_path, "main scene")

	var stage_count := 0
	for act_number in range(1, 5):
		for stage_number in range(1, 6):
			var stage_info: Dictionary = registry.call(&"get_stage_info", act_number, stage_number)
			var stage_path := String(stage_info.get("scene", ""))
			_require_scene(stage_path, "stage %d-%d" % [act_number, stage_number])
			stage_count += 1

	var enemy_count := 0
	var enemy_library: Dictionary = registry.call(&"get_enemy_library")
	for enemy_value: Variant in enemy_library.get("enemies", []):
		var enemy_info: Dictionary = enemy_value
		var enemy_id := StringName(enemy_info.get("id", ""))
		var enemy_scene := registry.call(&"get_enemy_scene", enemy_id) as PackedScene
		var frames := registry.call(&"get_enemy_sprite_frames", enemy_id) as SpriteFrames
		_require(enemy_scene != null, "Enemy scene is unavailable: %s" % enemy_id)
		_require(frames != null and not frames.get_animation_names().is_empty(), "Enemy frames are unavailable: %s" % enemy_id)
		if enemy_scene != null:
			var instance := enemy_scene.instantiate()
			_require(instance != null, "Enemy could not instantiate: %s" % enemy_id)
			instance.free()
		enemy_count += 1

	for boss_path: String in BOSS_SCENES:
		_require_scene(boss_path, "boss")

	var player_texture := registry.call(&"get_character_texture", "Player", "Player 96X96 (1)") as Texture2D
	var checkpoint_prop := registry.call(&"get_prop_texture", 3, "Space Props/Space extra (1).png") as Texture2D
	_require(player_texture != null and player_texture.resource_path != "res://icon.svg", "Player is using a fallback texture.")
	_require(checkpoint_prop != null and checkpoint_prop.resource_path != "res://icon.svg", "Runtime prop is using a fallback texture.")

	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null:
		var missing_audio: Array = audio_manager.call(&"get_missing_audio_paths")
		_require(missing_audio.is_empty(), "Required audio is unresolved: %s" % str(missing_audio))
		_require((audio_manager.call(&"get_loaded_sfx_names") as Array).size() == 10, "SFX manifest did not load all cues.")

	_require(stage_count == 20, "Expected 20 campaign stages; found %d." % stage_count)
	_require(enemy_count == 22, "Expected 22 production enemies; found %d." % enemy_count)
	_finish()


func _require_scene(scene_path: String, label: String) -> void:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path, "PackedScene"):
		_failures.append("Missing %s: %s" % [label, scene_path])
		return
	var packed := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE) as PackedScene
	if packed == null:
		_failures.append("Could not load %s: %s" % [label, scene_path])
		return
	var instance := packed.instantiate()
	if instance == null:
		_failures.append("Could not instantiate %s: %s" % [label, scene_path])
	else:
		instance.free()


func _require(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if not _failures.is_empty():
		for failure: String in _failures:
			push_error(failure)
		quit(1)
		return
	print("CLEAN_CLONE_GATE_OK stages=20 enemies=22 bosses=4")
	quit()
