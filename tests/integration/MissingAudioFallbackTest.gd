extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	assert(audio_manager != null, "AudioManager did not survive the missing-audio fixture.")
	var missing: Array = audio_manager.get_missing_audio_paths()
	var loaded_sfx: Array[StringName] = audio_manager.get_loaded_sfx_names()
	var constants: Dictionary = audio_manager.get_script().get_script_constant_map()
	var configured_paths := {}
	for manifest_name: String in ["SFX_PATHS", "ACT_BGM_PATHS", "BOSS_BGM_PATHS"]:
		var manifest: Dictionary = constants.get(manifest_name, {})
		for path: String in manifest.values():
			configured_paths[path] = true
	assert(missing.size() == configured_paths.size(), "The fixture did not exercise every unique configured stream.")
	for path: String in configured_paths:
		assert(path in missing, "Configured missing-audio path was not reported: %s" % path)
	var expected_sfx: Dictionary = constants.get("SFX_PATHS", {})
	assert(loaded_sfx.size() == expected_sfx.size(), "Procedural fallback SFX were not generated for every configured effect.")
	for required_sfx: StringName in [&"laser_shot", &"sword_slash", &"explosion", &"checkpoint"]:
		assert(loaded_sfx.has(required_sfx), "Missing procedural fallback: %s" % required_sfx)
	print("MISSING_AUDIO_FALLBACK_TEST_OK missing=", missing.size(), " fallback_sfx=", loaded_sfx.size())
	quit()
