extends SceneTree

const STRESS_STAGE := preload("res://Stages/Act4_AbyssalNight/4-4_AbyssalSanctuary/Stage.tscn")
const PROJECTILE_SCENE := preload("res://scenes/systems/security/EnemyProjectile.tscn")
const WORLD_SCENE := preload("res://scenes/world/WorldRoot.tscn")
const ROOM_SCENE := preload("res://scenes/world/WorldRoom.tscn")

const PROJECTILE_STRESS_COUNT := 64
const VFX_STRESS_COUNT := 32
const MAX_STAGE_NODES := 2000
const MAX_ROOM_NODES := 650
const MAX_ROOM_LOAD_USEC := 200_000
const MAX_TRANSITION_USEC := 1_200_000
const MAX_UI_OPEN_USEC := 250_000
const MAX_SAVE_USEC := 250_000
const MAX_STATIC_MEMORY_BYTES := 512 * 1024 * 1024
const MAX_PLAYER_RENDER_SURFACES := 10
const MAX_AUTHORED_ENEMIES := 12
const MAX_AUDIO_PLAYERS := 32
const MAX_HEADLESS_SECONDS := 15.0
const MEMORY_ROOM_IDS := ["factory_engine_entry", "factory_engine_approach", "factory_engine_arena"]
const RUNTIME_ASSET_INDEX_PATH := "res://assets/runtime/resource_index.json"
const REGISTRY_LOOKUP_ROOTS := [
	"res://assets/runtime/props",
	"res://assets/runtime/characters",
	"res://assets/runtime/environments",
	"res://assets/runtime/audio/music",
	"res://assets/runtime/audio/sfx",
	"res://assets/runtime/vfx",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(25.0, true, false, true).timeout.connect(func() -> void:
		push_error("Performance budget test timed out.")
		quit(1)
	)
	var started_usec := Time.get_ticks_usec()
	var registry := root.get_node("AssetRegistry")
	var indexed_asset_count: int = registry.get_runtime_indexed_path_count()
	var expected_indexed_count := _expected_registry_indexed_count()
	assert(expected_indexed_count > 0, "Runtime resource index is empty.")
	assert(indexed_asset_count == expected_indexed_count, "Runtime asset registry lookup index is incomplete.")
	assert(not registry.has_method(&"_collect_matching_paths"), "Runtime registry still exposes a recursive scan path.")

	var audio_manager := root.get_node("AudioManager")
	var sfx_players := 0
	var music_players := 0
	for child: Node in audio_manager.get_children():
		if child.name.begins_with("SFXPlayer"):
			sfx_players += 1
		elif child.name.begins_with("BGMPlayer"):
			music_players += 1
	assert(sfx_players == 10 and music_players == 2, "Audio player pools are not fixed at 10 SFX and 2 BGM players.")
	assert(not OS.get_environment("CCP_TEST_SAVE_DIR").is_empty(), "Performance test requires an isolated save directory.")

	var game := root.get_node("GameManager")
	var save := root.get_node("SaveManager")
	save.call(&"set_active_slot", 3)
	save.call(&"reset_save", 3)
	game.call(&"new_game")
	var profile := CharacterProfile.new()
	profile.character_name = "Perf"
	profile.creation_complete = true
	assert(game.call(&"commit_character_profile", profile), "Performance test could not commit a valid character profile.")
	game.run_state.stage_scene = "res://scenes/world/WorldRoot.tscn"
	var world_root := WORLD_SCENE.instantiate() as Node2D
	root.add_child(world_root)
	var world := root.get_node("WorldManager")
	await _wait_for_room(world, WorldProgress.START_ROOM)
	await _finish_active_narrative()
	assert(world.current_room_id == WorldProgress.START_ROOM, "Performance world did not finish initial streaming.")

	var peak_transition_usec := 0
	for room_id: String in ["factory_conveyor_gauntlet", "moon_command_arena", "void_heart_arena"]:
		var transition_started_usec := Time.get_ticks_usec()
		assert(await world.call(&"_transition", room_id, "west", false, false), "Representative room transition failed for %s." % room_id)
		peak_transition_usec = maxi(peak_transition_usec, Time.get_ticks_usec() - transition_started_usec)
		await _finish_active_narrative()
	assert(peak_transition_usec <= MAX_TRANSITION_USEC, "Representative fade/load transition exceeded %.0f ms." % (MAX_TRANSITION_USEC / 1000.0))

	var pause_menu := world_root.get_node("PauseMenu") as PauseMenu
	var map_started_usec := Time.get_ticks_usec()
	pause_menu.pause(0)
	var map_open_usec := Time.get_ticks_usec() - map_started_usec
	assert(pause_menu.is_open(), "Map performance probe did not open the pause menu.")
	pause_menu.resume()
	var inventory_started_usec := Time.get_ticks_usec()
	pause_menu.pause(2)
	var inventory_open_usec := Time.get_ticks_usec() - inventory_started_usec
	assert(pause_menu.is_open(), "Inventory performance probe did not open the pause menu.")
	pause_menu.resume()
	assert(map_open_usec <= MAX_UI_OPEN_USEC and inventory_open_usec <= MAX_UI_OPEN_USEC, "Map or inventory opening exceeded %.0f ms." % (MAX_UI_OPEN_USEC / 1000.0))

	var player_visual := world_root.get_node("Player/PlayerVisual") as PlayerVisual
	var player_render_surfaces := (player_visual.get("_layers") as Array).size()
	assert(player_render_surfaces <= MAX_PLAYER_RENDER_SURFACES, "Layered player exceeds its render-surface proxy budget.")

	var peak_save_usec := 0
	for _iteration: int in range(2):
		var save_started_usec := Time.get_ticks_usec()
		assert(save.call(&"save_game", 3), "Performance save probe failed.")
		peak_save_usec = maxi(peak_save_usec, Time.get_ticks_usec() - save_started_usec)
	assert(peak_save_usec <= MAX_SAVE_USEC, "Save duration exceeded %.0f ms." % (MAX_SAVE_USEC / 1000.0))

	var room_probe_container := Node2D.new()
	room_probe_container.name = "RoomPerformanceProbe"
	room_probe_container.position = Vector2(100000, 100000)
	room_probe_container.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(room_probe_container)
	var room_probe_loader := RoomLoader.new()
	room_probe_loader.name = "ProbeRoomLoader"
	root.add_child(room_probe_loader)
	room_probe_loader.configure(room_probe_container)
	var peak_room_nodes := 0
	for room_id: String in WorldDatabase.rooms():
		if MEMORY_ROOM_IDS.has(room_id):
			continue
		var streamed_room := room_probe_loader.load_room(room_id)
		assert(streamed_room != null, "Performance probe could not stream room %s." % room_id)
		peak_room_nodes = maxi(peak_room_nodes, _count_nodes(streamed_room))
		await process_frame

	var memory_probe := Node2D.new()
	memory_probe.name = "CurrentAndAdjacentRoomMemoryProbe"
	memory_probe.position = Vector2(200000, 200000)
	memory_probe.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(memory_probe)
	var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	for room_id: String in MEMORY_ROOM_IDS:
		var adjacent_room := ROOM_SCENE.instantiate() as WorldRoom
		adjacent_room.definition = WorldDatabase.room(room_id)
		memory_probe.add_child(adjacent_room)
	await process_frame
	var memory_with_adjacent := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var adjacent_memory_delta := maxi(memory_with_adjacent - memory_before, 0)
	assert(memory_probe.get_child_count() == 3, "Current/adjacent memory probe did not hold three connected rooms.")
	assert(memory_with_adjacent <= MAX_STATIC_MEMORY_BYTES, "Current plus adjacent room resources exceeded the static-memory regression ceiling.")
	for room_id: String in MEMORY_ROOM_IDS:
		var streamed_room := room_probe_loader.load_room(room_id)
		assert(streamed_room != null, "Performance probe could not stream room %s." % room_id)
		peak_room_nodes = maxi(peak_room_nodes, _count_nodes(streamed_room))
		await process_frame
	var streamed_room_count := room_probe_loader.successful_load_count
	var peak_room_load_usec := room_probe_loader.peak_load_duration_usec
	assert(streamed_room_count == WorldDatabase.room_count(), "Performance probe did not stream every authored room.")
	assert(peak_room_load_usec <= MAX_ROOM_LOAD_USEC, "Peak room build exceeded %.0f ms." % (MAX_ROOM_LOAD_USEC / 1000.0))
	assert(peak_room_nodes <= MAX_ROOM_NODES, "A streamed room exceeds the bounded node budget.")
	var max_authored_enemies := _max_authored_enemy_count(WorldDatabase.rooms())
	assert(max_authored_enemies <= MAX_AUTHORED_ENEMIES, "An authored encounter exceeds the simultaneous enemy budget.")

	var stage := STRESS_STAGE.instantiate()
	root.add_child(stage)
	await physics_frame
	assert(_count_nodes(stage) <= MAX_STAGE_NODES, "Production stress stage exceeds the node budget.")

	var projectile_container := Node2D.new()
	projectile_container.name = "ProjectileStressContainer"
	root.add_child(projectile_container)
	for index in range(PROJECTILE_STRESS_COUNT):
		var projectile := PROJECTILE_SCENE.instantiate() as EnemyProjectile
		projectile.max_lifetime = 0.2
		projectile.position = Vector2(index * 3.0, -1000.0)
		projectile_container.add_child(projectile)
		projectile.launch(Vector2.RIGHT)
	assert(projectile_container.get_child_count() == PROJECTILE_STRESS_COUNT, "Projectile stress setup was incomplete.")

	var vfx_container := Node2D.new()
	vfx_container.name = "VFXStressContainer"
	root.add_child(vfx_container)
	var vfx_spawner := root.get_node("VFXSpawner")
	for index in range(VFX_STRESS_COUNT):
		var effect: Node = vfx_spawner.spawn_effect(&"sparks", Vector2(index * 4.0, -1000.0), Vector2.RIGHT, vfx_container)
		assert(effect != null, "VFX stress setup failed.")
	assert(vfx_container.get_child_count() == VFX_STRESS_COUNT, "VFX stress setup was incomplete.")

	for _frame in range(75):
		await physics_frame
	assert(projectile_container.get_child_count() == 0, "Lifetime-bounded projectiles did not release.")
	assert(vfx_container.get_child_count() == 0, "One-shot VFX did not release.")
	var audio_player_count := _count_audio_players(root)
	assert(audio_player_count <= MAX_AUDIO_PLAYERS, "Runtime audio player count exceeds the fixed voice budget.")

	var stage_reference: WeakRef = weakref(stage)
	stage.queue_free()
	projectile_container.queue_free()
	vfx_container.queue_free()
	memory_probe.queue_free()
	room_probe_container.queue_free()
	room_probe_loader.queue_free()
	world_root.queue_free()
	for _frame in range(3):
		await process_frame
	assert(stage_reference.get_ref() == null, "Stage transition cleanup retained the old production scene.")

	var elapsed_seconds := float(Time.get_ticks_usec() - started_usec) / 1_000_000.0
	assert(elapsed_seconds < MAX_HEADLESS_SECONDS, "Headless stress pass exceeded the regression budget.")
	print(
		"PERFORMANCE_BUDGET_TEST_OK indexed=",
		indexed_asset_count,
		" projectiles=",
		PROJECTILE_STRESS_COUNT,
		" vfx=",
		VFX_STRESS_COUNT,
		" rooms=",
		streamed_room_count,
		" peak_room_ms=",
		"%.2f" % (peak_room_load_usec / 1000.0),
		" peak_room_nodes=",
		peak_room_nodes,
		" transition_ms=",
		"%.2f" % (peak_transition_usec / 1000.0),
		" ui_ms=",
		"%.2f/%.2f" % [map_open_usec / 1000.0, inventory_open_usec / 1000.0],
		" save_ms=",
		"%.2f" % (peak_save_usec / 1000.0),
		" memory_mb=",
		"%.1f(+%.1f)" % [memory_with_adjacent / 1048576.0, adjacent_memory_delta / 1048576.0],
		" player_surfaces=",
		player_render_surfaces,
		" enemies=",
		max_authored_enemies,
		" audio_players=",
		audio_player_count,
		" elapsed=",
		"%.2f" % elapsed_seconds,
		"s"
	)
	quit()


func _wait_for_room(world: Node, room_id: String) -> void:
	for _frame: int in range(180):
		await process_frame
		if not world.transition_in_progress and world.current_room_id == room_id:
			return


func _finish_active_narrative() -> void:
	var director := root.get_node("CutsceneDirector")
	var dialogue := root.get_node("DialogueController")
	if not String(director.active_sequence_id).is_empty():
		director.call(&"request_skip")
		dialogue.call(&"cancel_current")
	for _frame: int in range(120):
		await process_frame
		if String(director.active_sequence_id).is_empty() and String(dialogue.active_entry_id).is_empty():
			return


func _max_authored_enemy_count(rooms: Dictionary) -> int:
	var maximum := 0
	for room_value: Variant in rooms.values():
		var room := room_value as Dictionary
		var resident_count := (room.get("enemies", []) as Array).size()
		maximum = maxi(maximum, resident_count)
		for encounter_value: Variant in room.get("encounters", []):
			for wave_value: Variant in (encounter_value as Dictionary).get("waves", []):
				maximum = maxi(maximum, resident_count + (wave_value as Array).size())
	return maximum


func _count_audio_players(node: Node) -> int:
	var count := 1 if node is AudioStreamPlayer or node is AudioStreamPlayer2D else 0
	for child: Node in node.get_children():
		count += _count_audio_players(child)
	return count


func _expected_registry_indexed_count() -> int:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUNTIME_ASSET_INDEX_PATH))
	assert(parsed is Dictionary, "Runtime resource index could not be parsed.")
	var expected_paths := {}
	for path_value: Variant in (parsed as Dictionary).get("paths", []):
		var path := String(path_value)
		for lookup_root: String in REGISTRY_LOOKUP_ROOTS:
			if path.begins_with(lookup_root + "/"):
				expected_paths[path] = true
				break
	return expected_paths.size()


func _count_nodes(node: Node) -> int:
	var count := 1
	for child: Node in node.get_children():
		count += _count_nodes(child)
	return count
