extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/WorldRoot.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		push_error("Neon Moon production test timed out.")
		quit(1)
	)
	if not _require(not OS.get_environment("CCP_TEST_SAVE_DIR").is_empty(), "Neon Moon test requires an isolated save directory."):
		return
	var validation := WorldDatabase.validate()
	if not _require(validation.is_empty(), "Neon Moon world data failed validation: %s" % validation):
		return
	var rooms := WorldDatabase.rooms()
	var district_minimums := {"lunar_surface_arrival":10,"research_cleanrooms":10,"security_grid_shaft":10,"bio_tech_labs":10,"orbital_command":10}
	var moon_count := 0
	for district_id: String in district_minimums:
		var count := _district_room_count(rooms, district_id)
		moon_count += count
		if not _require(count >= int(district_minimums[district_id]), "Neon Moon district %s is still an entry-room greybox." % district_id):
			return
	if not _require(moon_count == 50 and WorldDatabase.reachable_rooms().size() == WorldDatabase.room_count(), "Neon Moon is not part of the fully reachable world graph."):
		return
	for entry_id: String in ["moon_surface_entry", "moon_cleanroom_entry", "moon_security_entry", "moon_biotech_entry", "moon_command_entry"]:
		var pacing := _critical_path_pacing(rooms, entry_id)
		if not _require(pacing >= 900 and pacing <= 1200, "District beginning at %s is outside its 15–20 minute authored first-pass budget (%ds)." % [entry_id, pacing]):
			return
	if not _require(_count_key(rooms, "moving_platforms") >= 8 and _hazard_count(rooms, "gravity_zone") >= 15, "Neon Moon lacks sustained low-gravity and moving-platform traversal."):
		return
	for hazard_type: String in ["gravity_zone", "rotating_laser", "laser_grid", "void_pit", "toxic_pool"]:
		if not _require(_hazard_count(rooms, hazard_type) > 0, "Neon Moon hazard family %s is missing." % hazard_type):
			return
	if not _require(_moon_encounters_use_roster(rooms), "Neon Moon encounters do not use the lunar enemy roster."):
		return
	if not _require(String((rooms.moon_biotech_core.ability_reward as Dictionary).get("ability", "")) == "gravity_anchor" and String((rooms.moon_command_arena.boss as Dictionary).get("id", "")) == "lunar_oracle", "Neon Moon ability or regional boss progression is missing."):
		return
	if not _require(_connection_requires(rooms.moon_security_lower, "south", &"gravity_anchor") and _connection_requires(rooms.moon_command_exit, "east", &"chain_teleport"), "Neon Moon backtracking or final-region gates are missing."):
		return
	if not _require(rooms.moon_surface_entry.has("warp_room") and rooms.moon_command_entry.has("save_room"), "Neon Moon is missing orbital transit or its pre-boss save room."):
		return

	var game := root.get_node("GameManager")
	var save := root.get_node("SaveManager")
	save.call(&"set_active_slot", 2)
	save.call(&"reset_save", 2)
	game.call(&"new_game")
	var profile := CharacterProfile.new()
	profile.character_name = "Selene"
	profile.creation_complete = true
	if not _require(game.call(&"commit_character_profile", profile), "Neon Moon test could not commit its player profile."):
		return
	game.run_state.stage_scene = "res://scenes/world/WorldRoot.tscn"
	var world_root := WORLD_SCENE.instantiate() as Node2D
	root.add_child(world_root)
	var world := root.get_node("WorldManager")
	await _wait_for_room(world, WorldProgress.START_ROOM)
	world.call(&"transition_to", "moon_biotech_core", "west", false)
	await _wait_for_room(world, "moon_biotech_core")
	var ability_pickup := _first_child_of_type(world.room_loader.current_room, "PersistentAbilityPickup") as PersistentAbilityPickup
	if not _require(ability_pickup != null and ability_pickup.collect_for_test() and game.abilities.has(&"gravity_anchor"), "Gravity Anchor did not grant persistent lunar progression."):
		return

	world.call(&"transition_to", "moon_command_arena", "west", false)
	await _wait_for_room(world, "moon_command_arena")
	var boss := _first_child_of_type(world.room_loader.current_room, "BossBase") as BossBase
	var arena := _first_child_of_type(world.room_loader.current_room, "BossArenaController") as BossArenaController
	if not _require(boss != null and arena != null and boss.boss_name == "LUNAR ORACLE" and boss.get_attack_roster().has(&"gravity_inversion") and boss.get_attack_roster().has(&"teleport"), "Lunar Oracle and its teleport-aware gravity arena did not stream correctly."):
		return
	boss.start_encounter()
	boss.complete_intro()
	boss.take_damage(boss.health)
	await process_frame
	if not _require(game.world_progress.defeated_bosses.has("lunar_oracle") and game.abilities.has(&"chain_teleport") and game.has_story_flag(&"lunar_oracle_defeated"), "Lunar Oracle defeat did not persist the chain-teleport progression reward."):
		return

	game.world_progress.activate_warp("warp_rooftop_overlook")
	game.world_progress.activate_warp("warp_factory_engine")
	game.world_progress.activate_warp("warp_moon_surface")
	game.call(&"set_story_flag", &"helix_warden_defeated", true, false)
	game.call(&"set_story_flag", &"assembly_colossus_defeated", true, false)
	world.call(&"transition_to", "moon_surface_entry", "east", false)
	await _wait_for_room(world, "moon_surface_entry")
	await _finish_active_cutscene()
	if not _require(await world.call(&"fast_travel", "warp_factory_engine"), "Moon-to-Factory fast travel failed."):
		return
	await _finish_active_cutscene()
	if not _require(world.current_room_id == "factory_engine_entry" and await world.call(&"fast_travel", "warp_rooftop_overlook"), "Three-region warp network did not remain coherent."):
		return
	if not _require(save.call(&"save_game", 2), "Neon Moon progression could not be saved."):
		return
	game.world_progress.defeated_bosses.clear()
	game.abilities.clear()
	if not _require(save.call(&"load_game", false, 2), "Neon Moon progression save could not be reloaded."):
		return
	if not _require(game.world_progress.defeated_bosses.has("lunar_oracle") and game.abilities.has(&"gravity_anchor") and game.abilities.has(&"chain_teleport"), "Neon Moon boss and ability state failed its save/load round trip."):
		return
	world.call(&"transition_to", "moon_command_entry", "east", false)
	await _wait_for_room(world, "moon_command_entry")
	world.call(&"transition_to", "moon_command_arena", "west", false)
	await _wait_for_room(world, "moon_command_arena")
	if not _require(_first_child_of_type(world.room_loader.current_room, "BossBase") == null, "Defeated Lunar Oracle respawned after streaming and reload."):
		return

	print("NEON_MOON_PRODUCTION_TEST_OK rooms=", moon_count, " boss=lunar_oracle warps=3")
	await _clean_shutdown(world_root)
	profile = null
	save.call(&"reset_save", 2)
	CreatorAnimationCatalog.clear_runtime_cache()
	quit()


func _district_room_count(rooms: Dictionary, district_id: String) -> int:
	var count := 0
	for room_value: Variant in rooms.values():
		var room := room_value as Dictionary
		if String(room.get("region_id", "")) == "neon_moon" and String(room.get("district_id", "")) == district_id:
			count += 1
	return count


func _critical_path_pacing(rooms: Dictionary, entry_id: String) -> int:
	var district_id := String((rooms[entry_id] as Dictionary).get("district_id", ""))
	var room_id := entry_id
	var visited: Dictionary = {}
	var total := 0
	while rooms.has(room_id) and String((rooms[room_id] as Dictionary).get("district_id", "")) == district_id and not visited.has(room_id):
		visited[room_id] = true
		total += int(((rooms[room_id] as Dictionary).get("pacing", {}) as Dictionary).get("first_pass_seconds", 0))
		var next_id := ""
		for connection_value: Variant in (rooms[room_id] as Dictionary).get("connections", []):
			if String((connection_value as Dictionary).get("id", "")) == "east":
				next_id = String((connection_value as Dictionary).get("target_room", ""))
				break
		room_id = next_id
	return total


func _count_key(rooms: Dictionary, key: String) -> int:
	var total := 0
	for room_value: Variant in rooms.values():
		var room := room_value as Dictionary
		if String(room.get("region_id", "")) == "neon_moon":
			total += (room.get(key, []) as Array).size()
	return total


func _hazard_count(rooms: Dictionary, hazard_type: String) -> int:
	var total := 0
	for room_value: Variant in rooms.values():
		var room := room_value as Dictionary
		if String(room.get("region_id", "")) != "neon_moon":
			continue
		for hazard_value: Variant in room.get("hazards", []):
			if String((hazard_value as Dictionary).get("type", "")) == hazard_type:
				total += 1
	return total


func _moon_encounters_use_roster(rooms: Dictionary) -> bool:
	var roster := {"harpy":true,"poison_skull":true,"gargoyle":true,"gryphon":true,"medusa":true,"mimic":true,"demon_boss":true}
	var found: Dictionary = {}
	for room_value: Variant in rooms.values():
		var room := room_value as Dictionary
		if String(room.get("region_id", "")) != "neon_moon":
			continue
		for encounter_value: Variant in room.get("encounters", []):
			for wave_value: Variant in (encounter_value as Dictionary).get("waves", []):
				for enemy_value: Variant in wave_value as Array:
					var enemy_id := String((enemy_value as Dictionary).get("enemy", ""))
					if roster.has(enemy_id):
						found[enemy_id] = true
	return found.size() >= 7


func _connection_requires(room: Dictionary, connection_id: String, ability_id: StringName) -> bool:
	for connection_value: Variant in room.get("connections", []):
		var connection := connection_value as Dictionary
		if String(connection.get("id", "")) == connection_id and StringName(connection.get("required_ability", "")) == ability_id:
			return true
	return false


func _first_child_of_type(room: Node, class_type: String) -> Node:
	for child: Node in room.get_children():
		if child.is_class(class_type) or (class_type == "PersistentAbilityPickup" and child is PersistentAbilityPickup) or (class_type == "BossArenaController" and child is BossArenaController) or (class_type == "BossBase" and child is BossBase):
			return child
	return null


func _wait_for_room(world: Node, room_id: String) -> void:
	for _frame: int in range(180):
		await process_frame
		if not world.transition_in_progress and world.current_room_id == room_id:
			return


func _clean_shutdown(world_root: Node) -> void:
	var dialogue := root.get_node("DialogueController")
	dialogue.call(&"cancel_current")
	await process_frame
	var voice := dialogue.get("_voice") as VoiceBarkPlayer
	if voice != null:
		voice.stop_bark()
	for bark_node: Node in world_root.find_children("*", "VoiceBarkPlayer", true, false):
		(bark_node as VoiceBarkPlayer).stop_bark()
	world_root.queue_free()
	for _frame: int in range(4):
		await process_frame


func _finish_active_cutscene() -> void:
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
