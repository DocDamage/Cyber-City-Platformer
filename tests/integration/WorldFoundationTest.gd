extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/WorldRoot.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(25.0, true, false, true).timeout.connect(func() -> void:
		push_error("World foundation test timed out.")
		quit(1)
	)
	var save_directory := OS.get_environment("CCP_TEST_SAVE_DIR")
	if not _require(not save_directory.is_empty(), "World test requires an isolated save directory."):
		return
	var validation := WorldDatabase.validate()
	if not _require(validation.is_empty(), "World database validation failed: %s" % validation):
		return
	var reachable := WorldDatabase.reachable_rooms()
	if not _require(reachable.size() == WorldDatabase.room_count() and reachable.size() == 202, "The player-facing world graph is not fully connected."):
		return
	var game := root.get_node("GameManager")
	var save := root.get_node("SaveManager")
	save.call(&"set_active_slot", 2)
	save.call(&"reset_save", 2)
	game.call(&"new_game")
	var profile := CharacterProfile.new()
	profile.character_name = "Circuit"
	profile.creation_complete = true
	if not _require(game.call(&"commit_character_profile", profile), "World test could not commit a valid character."):
		return
	game.run_state.stage_scene = "res://scenes/world/WorldRoot.tscn"
	var world_root := WORLD_SCENE.instantiate() as Node2D
	root.add_child(world_root)
	for _frame: int in range(8):
		await process_frame
	var world := root.get_node("WorldManager")
	var audio := root.get_node("AudioManager")
	if not _require(world.current_room_id == "cyber_rooftop_entry" and world.room_loader.current_room != null, "World did not load the stable start room."):
		return
	world.call(&"transition_to", "cyber_rooftop_lane", "west", false)
	await _wait_for_room(world, "cyber_rooftop_lane")
	world.call(&"transition_to", "cyber_rooftop_interior", "west", false)
	await _wait_for_room(world, "cyber_rooftop_interior")
	world.call(&"transition_to", "cyber_rooftop_entry", "east", false)
	await _wait_for_room(world, "cyber_rooftop_entry")
	if not _require(game.world_progress.discovered_rooms.has("cyber_rooftop_lane") and game.world_progress.discovered_rooms.has("cyber_rooftop_interior"), "Multi-room loop discovery did not persist in memory (current=%s discovered=%s)." % [world.current_room_id, game.world_progress.discovered_rooms.keys()]):
		return
	world.call(&"transition_to", "cyber_rooftop_shortcut", "west", false)
	await _wait_for_room(world, "cyber_rooftop_shortcut")
	var shortcut: PersistentShortcut
	for candidate: Node in world.room_loader.current_room.get_children():
		if candidate is PersistentShortcut:
			shortcut = candidate
			break
	if not _require(shortcut != null, "Authored shortcut was not instantiated."):
		return
	shortcut.call(&"_open")
	if not _require(bool(game.world_progress.get_object_state("shortcut_rooftop_safehouse", false)) and shortcut._barrier.collision_layer == 0, "Shortcut did not open persistently."):
		return
	world.call(&"transition_to", "rooftop_alley_opt_pirate_antenna", "return", false)
	await _wait_for_room(world, "rooftop_alley_opt_pirate_antenna")
	var cache: Node
	for candidate: Node in world.room_loader.current_room.get_children():
		if candidate.is_in_group(&"persistent_caches"):
			cache = candidate
			break
	var currency_before: int = game.inventory.currency
	if not _require(cache != null and bool(cache.call(&"collect_for_test")), "Optional district cache did not instantiate or collect."):
		return
	if not _require(game.inventory.currency == currency_before + 25 and bool(game.world_progress.get_object_state("cache_rooftop_alley_pirate_antenna", false)), "Optional cache did not grant and persist its authored currency."):
		return
	world.call(&"transition_to", "cyber_rooftop_market", "east", false)
	await _wait_for_room(world, "cyber_rooftop_market")
	var save_room: SaveRoom
	for candidate: Node in world.room_loader.current_room.get_children():
		if candidate is SaveRoom:
			save_room = candidate
			break
	if not _require(save_room != null, "Save room prototype is missing."):
		return
	save_room.call(&"_on_body_entered", world.player)
	await process_frame
	await process_frame
	if not _require(save.call(&"has_valid_save", 2), "Save room did not write the active slot."):
		return
	world.call(&"transition_to", "cyber_rooftop_overlook", "west", false)
	await _wait_for_room(world, "cyber_rooftop_overlook")
	game.world_progress.activate_warp("warp_rooftop_overlook")
	game.world_progress.activate_warp("warp_skybridge")
	game.world_progress.activate_warp("warp_factory_engine")
	game.world_progress.activate_warp("warp_moon_surface")
	game.world_progress.activate_warp("warp_void_sanctuary")
	if not _require(not WorldDatabase.fast_travel_node_available("warp_skybridge", game.story_flags) and not await world.call(&"fast_travel", "warp_skybridge") and world.current_room_id == "cyber_rooftop_overlook", "An activated warp bypassed its required Rooftop Alley story gate."):
		return
	game.call(&"set_story_flag", &"rooftop_alley_complete", true, false)
	if not _require(not WorldDatabase.fast_travel_node_available("warp_factory_engine", game.story_flags), "A later-region warp ignored its boss-completion story gate."):
		return
	var director := root.get_node("CutsceneDirector")
	director.active_sequence_id = "test_travel_lock"
	if not _require(not world.call(&"can_fast_travel_to", "warp_skybridge") and not await world.call(&"fast_travel", "warp_skybridge"), "Fast travel remained available during an active cutscene."):
		return
	director.active_sequence_id = ""
	var arena := BossArenaController.new()
	arena.configure(Rect2(180, 80, 600, 420), null, null)
	world_root.add_child(arena)
	await process_frame
	arena.call(&"_on_encounter_started")
	if not _require(arena.is_locked() and not world.call(&"can_fast_travel_to", "warp_skybridge") and not await world.call(&"fast_travel", "warp_skybridge"), "Boss arena lock did not prevent an illegal warp."):
		return
	arena.call(&"_on_boss_defeated")
	if not _require(not arena.is_locked() and world.call(&"can_fast_travel_to", "warp_skybridge"), "Boss defeat did not reopen the permanent travel route."):
		return
	arena.queue_free()
	if not _require(await world.call(&"fast_travel", "warp_skybridge"), "Activated warp-room travel failed."):
		return
	if not _require(world.current_room_id == "cyber_skybridge_entry", "Warp arrived in the wrong room."):
		return
	await _finish_active_narrative()
	game.call(&"set_story_flag", &"helix_warden_defeated", true, false)
	game.call(&"set_story_flag", &"assembly_colossus_defeated", true, false)
	game.call(&"set_story_flag", &"lunar_oracle_defeated", true, false)
	for destination: Dictionary in [
		{"node":"warp_factory_engine", "room":"factory_engine_entry"},
		{"node":"warp_moon_surface", "room":"moon_surface_entry"},
		{"node":"warp_void_sanctuary", "room":"void_sanctuary_entry"},
		{"node":"warp_rooftop_overlook", "room":"cyber_rooftop_overlook"},
	]:
		if not _require(await world.call(&"fast_travel", String(destination.node)) and world.current_room_id == String(destination.room), "Warp destination did not complete safely: %s" % destination.node):
			return
		var expected_region := String(WorldDatabase.room(String(destination.room)).get("region_id", ""))
		if not _require(String(audio.call(&"get_current_ambience_region")) == expected_region, "Regional ambience did not follow warp arrival into %s." % expected_region):
			return
		await _finish_active_narrative()
	game.world_progress.persistent_object_states.clear()
	if not _require(save.call(&"load_game", false, 2), "Saved world state did not reload."):
		return
	if not _require(bool(game.world_progress.get_object_state("shortcut_rooftop_safehouse", false)) and bool(game.world_progress.get_object_state("cache_rooftop_alley_pirate_antenna", false)) and game.inventory.currency == currency_before + 25 and game.character_profile.character_name == "Circuit", "World/profile/cache state did not survive save/load."):
		return
	print("WORLD_FOUNDATION_TEST_OK rooms=", reachable.size(), " discovered=", game.world_progress.discovered_rooms.size(), " warps=5 slot=2")
	world_root.queue_free()
	await process_frame
	CreatorAnimationCatalog.clear_runtime_cache()
	save.call(&"reset_save", 2)
	quit()


func _wait_for_room(world: Node, room_id: String) -> void:
	for _frame: int in range(90):
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


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
