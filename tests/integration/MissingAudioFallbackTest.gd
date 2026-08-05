extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	assert(audio_manager != null, "AudioManager did not survive the missing-audio fixture.")
	var missing: Array = audio_manager.get_missing_audio_paths()
	var loaded_sfx: Array[StringName] = audio_manager.get_loaded_sfx_names()
	assert(missing.size() == 21, "The fixture did not exercise every configured stream.")
	assert(loaded_sfx.size() == 14, "Procedural fallback SFX were not generated.")
	for required_sfx: StringName in [&"laser_shot", &"sword_slash", &"explosion", &"checkpoint"]:
		assert(loaded_sfx.has(required_sfx), "Missing procedural fallback: %s" % required_sfx)
	print("MISSING_AUDIO_FALLBACK_TEST_OK missing=", missing.size(), " fallback_sfx=", loaded_sfx.size())
	quit()
