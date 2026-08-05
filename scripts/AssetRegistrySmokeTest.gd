extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var registry := root.get_node_or_null("AssetRegistry")
	assert(registry != null, "AssetRegistry is not registered as an autoload.")

	var manifest: Dictionary = registry.get_campaign_manifest()
	var acts: Array = manifest.get("acts", [])
	assert(acts.size() == 4, "Campaign manifest must contain four acts.")
	for act_number in range(1, 5):
		var act: Dictionary = registry.get_act_info(act_number)
		assert(not act.is_empty(), "Missing campaign act %d." % act_number)
		assert((act.get("stages", []) as Array).size() == 5, "Act %d must contain five sub-stages." % act_number)
		assert(String(act.get("character_folder", "")) == "Enemies", "Act %d is not using the shared enemy library." % act_number)
		for stage_number in range(1, 6):
			var stage: Dictionary = registry.get_stage_info(act_number, stage_number)
			var stage_scene: PackedScene = registry.get_stage_scene(act_number, stage_number)
			assert(stage_scene != null, "Stage %d-%d is not loadable." % [act_number, stage_number])
			assert(stage_scene.resource_path == String(stage.get("scene", "")), "Stage %d-%d resolved to the wrong scene." % [act_number, stage_number])

	var rooftop_scene: PackedScene = registry.get_stage_scene(1, 1)
	var factory_scene: PackedScene = registry.get_stage_scene(2, 1)
	assert(rooftop_scene.resource_path == "res://Stages/Act1_CyberCity/1-1_RooftopAlley/Stage.tscn")
	assert(factory_scene.resource_path == "res://Stages/Act2_RobotFactory/2-1_SubLevelIntake/Stage.tscn")
	assert(registry.get_stage_scene(4, 5).resource_path == "res://Stages/Act4_AbyssalNight/4-5_HeartOfTheVoid/Stage.tscn")
	var boss_scene: PackedScene = registry.get_character_scene("Bosses", "act1_helix_warden")
	assert(boss_scene != null and boss_scene.resource_path == "res://Characters/Bosses/Scenes/act1_helix_warden.tscn")

	var enemy_library: Dictionary = registry.get_enemy_library()
	var enemies: Array = enemy_library.get("enemies", [])
	assert(enemies.size() == 22, "Enemy library must contain all 22 supplied packs.")
	for enemy_value: Variant in enemies:
		var enemy: Dictionary = enemy_value
		var enemy_id := StringName(enemy.get("id", ""))
		var frames: SpriteFrames = registry.get_enemy_sprite_frames(enemy_id)
		var enemy_scene: PackedScene = registry.get_enemy_scene(enemy_id)
		assert(frames != null and frames.get_animation_names().size() >= 4, "Enemy '%s' does not have usable animations." % enemy_id)
		assert(enemy_scene != null and enemy_scene.resource_path == String(enemy.get("scene", "")), "Enemy '%s' scene did not resolve." % enemy_id)

	var fallback_texture: Texture2D = registry.get_prop_texture(99, "missing")
	var fallback_player: PackedScene = registry.get_character_scene("Player", "missing")
	var fallback_enemy: PackedScene = registry.get_character_scene("Enemies", "missing")
	assert(fallback_texture != null and fallback_texture.resource_path == "res://icon.svg")
	assert(fallback_player != null and fallback_player.resource_path == "res://scenes/Player.tscn")
	assert(fallback_enemy != null and fallback_enemy.resource_path == "res://scenes/EnemyBase.tscn")
	var canonical_prop: Texture2D = registry.get_prop_texture(3, "SourceArt/Space Props/Space extra (1).png")
	assert(canonical_prop.resource_path == "res://Stage Props/LunarProps/SourceArt/Space Props/Space extra (1).png")
	var rooftop_music: AudioStream = registry.get_music_stream("Rooftops/Cyberpunk Rooftops.ogg")
	var laser_sfx: AudioStream = registry.get_sfx_stream("FREE Retro Action Platformer Sound Effects/Weapon Discharge - Laser.mp3")
	var parallax: Texture2D = registry.get_parallax_texture("Rooftops 2/back.png")
	var vfx: Texture2D = registry.get_vfx_texture("Pack 6/PNG sheet/Effect (1)-Sheet.png")
	assert(rooftop_music != null and rooftop_music.resource_path.get_extension().to_lower() == "ogg")
	assert(laser_sfx != null, "Canonical SFX library did not resolve.")
	assert(parallax != null and parallax.resource_path == "res://Parallax/SourceArt/Rooftops 2/back.png")
	assert(vfx != null and vfx.resource_path == "res://VFX/SourceArt/Pack 6/PNG sheet/Effect (1)-Sheet.png")
	var audio_manager := root.get_node_or_null("AudioManager")
	assert(audio_manager != null, "AudioManager is not registered as an autoload.")
	assert(audio_manager.get_configured_act_count() == 4, "AudioManager must configure one BGM track for each Act.")
	assert(audio_manager.get_loaded_sfx_names().size() >= 5, "AudioManager is missing required gameplay SFX.")
	assert(audio_manager.get_node("SFXPlayer00") is AudioStreamPlayer, "AudioManager did not create its SFX player pool.")

	assert(registry.get_prop_texture(1, "../icon.svg").resource_path == "res://icon.svg")
	assert(registry.get_character_scene("../Characters", "EnemyBase").resource_path == "res://scenes/EnemyBase.tscn")
	print("ASSET_REGISTRY_SMOKE_TEST_OK acts=", acts.size(), " stages=20 enemies=", enemies.size())
	quit()
