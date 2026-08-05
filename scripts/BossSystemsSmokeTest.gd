extends SceneTree

const BOSS_SCENES := [
	"res://Characters/Bosses/Scenes/act1_helix_warden.tscn",
	"res://Characters/Bosses/Scenes/act2_assembly_colossus.tscn",
	"res://Characters/Bosses/Scenes/act3_lunar_oracle.tscn",
	"res://Characters/Bosses/Scenes/act4_void_cerberus.tscn",
]

const BOSS_STAGE_SCENES := [
	"res://Stages/Act1_CyberCity/1-5_ExecutiveHelipad/Stage.tscn",
	"res://Stages/Act2_RobotFactory/2-5_AssemblyEngine/Stage.tscn",
	"res://Stages/Act3_NeonMoon/3-5_OrbitalCommand/Stage.tscn",
	"res://Stages/Act4_AbyssalNight/4-5_HeartOfTheVoid/Stage.tscn",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		push_error("Boss/VFX/audio smoke test timed out.")
		quit(1)
	)
	var audio_manager := root.get_node_or_null("AudioManager")
	var vfx_spawner := root.get_node_or_null("VFXSpawner")
	assert(audio_manager != null and audio_manager.get_configured_act_count() == 4, "Four-Act AudioManager configuration is incomplete.")
	assert(vfx_spawner != null, "VFXSpawner autoload is missing.")
	assert(audio_manager.get_node("BGMPlayer0") is AudioStreamPlayer, "BGM channel is missing.")
	assert(audio_manager.get_node("SFXPlayer00") is AudioStreamPlayer, "SFX channel is missing.")

	var target := CharacterBody2D.new()
	target.name = "BossTestTarget"
	target.add_to_group(&"player")
	target.position = Vector2(180.0, 0.0)
	root.add_child(target)
	var defeated_bosses: Array[String] = []
	for scene_path: String in BOSS_SCENES:
		var packed := load(scene_path) as PackedScene
		assert(packed != null, "Boss scene is not loadable: %s" % scene_path)
		var boss := packed.instantiate() as BossBase
		root.add_child(boss)
		await process_frame
		assert(boss.get_node("AnimatedSprite2D") is AnimatedSprite2D, "Boss is missing AnimatedSprite2D.")
		assert(boss.get_node("Hurtbox") is Hurtbox, "Boss is missing Hurtbox.")
		assert(boss.get_node("SlashHitbox") is Hitbox, "Boss is missing slash Hitbox.")
		assert(boss.get_phase_number() == 1 and is_equal_approx(boss.get_health_percentage(), 1.0), "Boss did not initialize in Phase 1.")
		if scene_path == BOSS_SCENES[0]:
			boss.start_encounter()
			boss.set("_attack_cooldown", 0.0)
			await physics_frame
			await physics_frame
			assert(root.find_child("BossProjectile", true, false) != null, "Phase 1 did not fire a ranged projectile.")
		boss.take_damage(boss.health - floori(boss.max_health * boss.phase_two_threshold))
		assert(boss.state == BossBase.State.PHASE_2, "50%% health gate did not enter Phase 2.")
		if scene_path == BOSS_SCENES[0]:
			boss.set("_attack_cooldown", 0.0)
			await physics_frame
			await physics_frame
			assert((boss.get_node("SlashHitbox") as Hitbox).is_active(), "Phase 2 did not activate its dash-slash hitbox.")
		boss.take_damage(boss.health - floori(boss.max_health * boss.phase_three_threshold))
		assert(boss.state == BossBase.State.PHASE_3, "desperation health gate did not enter Phase 3.")
		if scene_path == BOSS_SCENES[0]:
			boss.set("_attack_cooldown", 0.0)
			await physics_frame
			await physics_frame
			assert((boss.get_node("LaserPivot/LaserHitbox/LaserVisual") as Line2D).visible, "Phase 3 did not start its sweeping laser.")
		boss.boss_defeated.connect(func() -> void: defeated_bosses.append(boss.boss_name))
		boss.take_damage(999)
		assert(boss.is_defeated, "Boss did not enter defeated state at zero health.")
		boss.free()

	assert(defeated_bosses.size() == 4, "boss_defeated did not emit for every Act boss.")
	target.free()
	for stage_path: String in BOSS_STAGE_SCENES:
		var stage := (load(stage_path) as PackedScene).instantiate()
		root.add_child(stage)
		await physics_frame
		await physics_frame
		var stage_bosses: Array[BossBase] = []
		for child: Node in stage.find_children("*", "CharacterBody2D", true, false):
			if child is BossBase:
				stage_bosses.append(child as BossBase)
		assert(stage_bosses.size() == 1, "X-5 stage must contain exactly one BossBase: %s" % stage_path)
		var stage_exit := stage.find_child("StageExit", true, false) as StageExit
		assert(stage_exit != null and stage_exit.is_locked, "X-5 exit was not locked by its boss: %s" % stage_path)
		stage_bosses[0].start_encounter()
		await process_frame
		var hud := stage.find_child("HUD", true, false) as CanvasLayer
		assert(hud != null and hud.get_node("Layout/BossPanel").visible, "Boss HUD did not appear when the encounter started.")
		stage.free()
		await process_frame
	var effect: GPUParticles2D = vfx_spawner.spawn_effect(&"explosion_ring", Vector2.ZERO)
	assert(effect is GPUParticles2D and effect.one_shot, "Explosion ring is not a one-shot GPUParticles2D.")
	effect.free()
	var player_scene := load("res://scenes/Player.tscn") as PackedScene
	var player := player_scene.instantiate()
	root.add_child(player)
	await process_frame
	assert(player.get_node("WallSlideDust") is GPUParticles2D, "Player has no wall-slide particle emitter.")
	player.free()
	for projectile: Node in get_nodes_in_group(&"boss_projectiles"):
		projectile.free()
	await create_timer(0.95, true, false, true).timeout
	audio_manager.stop_all_sfx()
	await audio_manager.stop_music(0.0)
	await process_frame
	print("BOSS_SYSTEMS_SMOKE_TEST_OK bosses=", defeated_bosses.size(), " acts=", audio_manager.get_configured_act_count())
	quit()
