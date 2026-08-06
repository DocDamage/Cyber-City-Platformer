extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/WorldRoot.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(24.0, true, false, true).timeout.connect(func() -> void:
		push_error("Abyssal Night production test timed out.")
		quit(1)
	)
	if not _require(not OS.get_environment("CCP_TEST_SAVE_DIR").is_empty(), "Abyssal Night test requires an isolated save directory."):
		return
	var validation := WorldDatabase.validate()
	if not _require(validation.is_empty(), "Abyssal Night world data failed validation: %s" % validation):
		return
	var rooms := WorldDatabase.rooms()
	var district_minimums := {"corrupted_outpost":10,"the_dark_chasm":10,"bio_mechanical_nest":10,"abyssal_sanctuary":10,"heart_of_the_void":10}
	var abyss_count := 0
	for district_id: String in district_minimums:
		var count := _district_room_count(rooms, district_id)
		abyss_count += count
		if not _require(count >= int(district_minimums[district_id]), "Abyssal district %s is still an entry-room greybox." % district_id):
			return
	if not _require(abyss_count == 50 and WorldDatabase.reachable_rooms().size() == WorldDatabase.room_count() and WorldDatabase.room_count() == 202, "Abyssal Night is not part of the complete reachable world graph."):
		return
	for entry_id: String in ["void_outpost_entry", "void_chasm_entry", "void_nest_entry", "void_sanctuary_entry", "void_heart_entry"]:
		var pacing := _critical_path_pacing(rooms, entry_id)
		if not _require(pacing >= 900 and pacing <= 1200, "District beginning at %s is outside its 15–20 minute authored first-pass budget (%ds)." % [entry_id, pacing]):
			return
	if not _require(_hazard_count(rooms, "corruption_zone") >= 15 and _count_key(rooms, "moving_platforms") >= 7, "Abyssal Night lacks sustained corruption and traversal mastery tests."):
		return
	for hazard_type: String in ["corruption_zone", "void_pit", "rotating_laser", "laser_grid", "gravity_zone"]:
		if not _require(_hazard_count(rooms, hazard_type) > 0, "Abyssal hazard family %s is missing." % hazard_type):
			return
	if not _require(_abyss_encounters_use_roster(rooms), "Abyssal encounters do not use the endgame elite roster."):
		return
	if not _require(String((rooms.void_outpost_purifier.ability_reward as Dictionary).get("ability", "")) == "corruption_resistance" and String((rooms.void_nest_core.ability_reward as Dictionary).get("ability", "")) == "energy_field", "Abyssal ability progression is missing."):
		return
	if not _require(String((rooms.void_heart_arena.boss as Dictionary).get("id", "")) == "void_cerberus" and _connection_requires(rooms.void_sanctuary_gravity, "south", &"energy_field"), "Abyssal boss or mastery gate is missing."):
		return
	var ending_sequence := DialogueDatabase.sequence("abyssal_ending")
	if not _require(_sequence_has_command(ending_sequence, "finish_game") and rooms.void_heart_exit.has("story_triggers"), "The world finale is not connected to the ending flow."):
		return

	var game := root.get_node("GameManager")
	var save := root.get_node("SaveManager")
	save.call(&"set_active_slot", 2)
	save.call(&"reset_save", 2)
	game.call(&"new_game")
	var profile := CharacterProfile.new()
	profile.character_name = "Nyx"
	profile.pronoun_set_id = &"she_her"
	profile.portrait_id = "portrait_11"
	profile.starting_weapon_family = &"heavy"
	profile.creation_complete = true
	if not _require(game.call(&"commit_character_profile", profile), "Abyssal test could not commit its player profile."):
		return
	game.run_state.stage_scene = "res://scenes/world/WorldRoot.tscn"
	var world_root := WORLD_SCENE.instantiate() as Node2D
	root.add_child(world_root)
	current_scene = world_root
	var world := root.get_node("WorldManager")
	await _wait_for_room(world, WorldProgress.START_ROOM)
	await _clear_narrative()
	world.call(&"transition_to", "void_outpost_entry", "west", false)
	await _wait_for_room(world, "void_outpost_entry")
	await _clear_narrative()
	var corruption_zone := _first_child_of_type(world.room_loader.current_room, "CorruptionZone") as CorruptionZone
	if not _require(corruption_zone != null, "Authored corruption field did not stream into the outpost."):
		return
	world.player.call(&"cleanse_corruption")
	world.player.call(&"apply_corruption", 20.0)
	var unresisted_exposure := float(world.player.get("corruption"))
	if not _require(is_equal_approx(unresisted_exposure, 20.0), "Unfiltered corruption buildup is not deterministic."):
		return

	world.call(&"transition_to", "void_outpost_purifier", "west", false)
	await _wait_for_room(world, "void_outpost_purifier")
	await _clear_narrative()
	var resistance_pickup := _first_child_of_type(world.room_loader.current_room, "PersistentAbilityPickup") as PersistentAbilityPickup
	if not _require(resistance_pickup != null and resistance_pickup.collect_for_test() and game.abilities.has(&"corruption_resistance"), "Abyssal Filter did not grant persistent corruption resistance."):
		return
	world.player.call(&"cleanse_corruption")
	world.player.call(&"apply_corruption", 20.0)
	if not _require(float(world.player.get("corruption")) < unresisted_exposure * 0.5, "Corruption resistance does not materially reduce exposure."):
		return

	world.call(&"transition_to", "void_nest_core", "west", false)
	await _wait_for_room(world, "void_nest_core")
	await _clear_narrative()
	var field_pickup := _first_child_of_type(world.room_loader.current_room, "PersistentAbilityPickup") as PersistentAbilityPickup
	if not _require(field_pickup != null and field_pickup.collect_for_test() and game.abilities.has(&"energy_field"), "Null Energy Field did not grant endgame gate progression."):
		return

	world.call(&"transition_to", "void_heart_arena", "west", false)
	await _wait_for_room(world, "void_heart_arena")
	var boss := _first_child_of_type(world.room_loader.current_room, "BossBase") as BossBase
	var arena := _first_child_of_type(world.room_loader.current_room, "BossArenaController") as BossArenaController
	if not _require(boss != null and arena != null and boss.boss_name == "VOID CERBERUS" and boss.get_attack_roster().has(&"desperation") and boss.get_attack_roster().has(&"corruption_zone"), "Void Cerberus and its desperation arena did not stream correctly."):
		return
	boss.start_encounter()
	boss.complete_intro()
	boss.take_damage(boss.health)
	await process_frame
	if not _require(game.world_progress.defeated_bosses.has("void_cerberus") and game.has_story_flag(&"void_cerberus_defeated"), "Void Cerberus defeat did not persist final-boss state."):
		return
	if not _require(save.call(&"save_game", 2), "Pre-ending world state could not be saved."):
		return
	await _clear_narrative()

	world.call(&"transition_to", "void_heart_exit", "west", false)
	await _wait_for_room(world, "void_heart_exit")
	var director := root.get_node("CutsceneDirector")
	for _frame: int in range(90):
		await process_frame
		if String(director.get("active_sequence_id")) == "abyssal_ending":
			break
	if not _require(String(director.get("active_sequence_id")) == "abyssal_ending", "Final world trigger did not start the ending sequence."):
		return
	director.call(&"request_skip")
	for _frame: int in range(180):
		await process_frame
		if current_scene != null and current_scene.name == "EndingScreen" and not bool(game.get("_transitioning")):
			break
	if not _require(current_scene != null and current_scene.name == "EndingScreen" and game.campaign_progress.campaign_complete and game.has_story_flag(&"game_complete"), "Skippable finale did not reach post-game state and EndingScreen."):
		return
	if not _require(_find_label_containing(current_scene, "Nyx") != null and _find_label_containing(current_scene, "her") != null and _first_descendant_of_type(current_scene, "PortraitView") != null and _first_descendant_of_type(current_scene, "PlayerVisual") != null and _find_button(current_scene, "CONTINUE EXPLORING") != null, "Ending does not reflect the custom profile or expose explicit post-game continuation."):
		return
	if not _require(save.call(&"load_game", false, 2) and game.world_progress.defeated_bosses.has("void_cerberus") and game.abilities.has(&"corruption_resistance") and game.abilities.has(&"energy_field"), "Post-game save did not preserve final-region progression."):
		return

	print("ABYSSAL_NIGHT_PRODUCTION_TEST_OK rooms=", abyss_count, " boss=void_cerberus ending=Nyx/her")
	await _clean_shutdown(current_scene)
	current_scene = null
	profile = null
	save.call(&"reset_save", 2)
	CreatorAnimationCatalog.clear_runtime_cache()
	quit()


func _district_room_count(rooms: Dictionary, district_id: String) -> int:
	var count := 0
	for room_value: Variant in rooms.values():
		var room := room_value as Dictionary
		if String(room.get("region_id", "")) == "abyssal_night" and String(room.get("district_id", "")) == district_id:
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
		if String(room.get("region_id", "")) == "abyssal_night":
			total += (room.get(key, []) as Array).size()
	return total


func _hazard_count(rooms: Dictionary, hazard_type: String) -> int:
	var total := 0
	for room_value: Variant in rooms.values():
		var room := room_value as Dictionary
		if String(room.get("region_id", "")) != "abyssal_night":
			continue
		for hazard_value: Variant in room.get("hazards", []):
			if String((hazard_value as Dictionary).get("type", "")) == hazard_type:
				total += 1
	return total


func _abyss_encounters_use_roster(rooms: Dictionary) -> bool:
	var roster := {"death_knight":true,"werewolf":true,"demon_boss":true,"gargoyle":true,"headless_horseman":true,"harpy":true,"mimic":true,"cerberus":true,"witch":true,"stone_golem":true,"poison_skull":true}
	var found: Dictionary = {}
	for room_value: Variant in rooms.values():
		var room := room_value as Dictionary
		if String(room.get("region_id", "")) != "abyssal_night":
			continue
		for encounter_value: Variant in room.get("encounters", []):
			for wave_value: Variant in (encounter_value as Dictionary).get("waves", []):
				for enemy_value: Variant in wave_value as Array:
					var enemy_id := String((enemy_value as Dictionary).get("enemy", ""))
					if roster.has(enemy_id):
						found[enemy_id] = true
	return found.size() >= 11


func _connection_requires(room: Dictionary, connection_id: String, ability_id: StringName) -> bool:
	for connection_value: Variant in room.get("connections", []):
		var connection := connection_value as Dictionary
		if String(connection.get("id", "")) == connection_id and StringName(connection.get("required_ability", "")) == ability_id:
			return true
	return false


func _sequence_has_command(sequence: Dictionary, command_type: String) -> bool:
	for command_value: Variant in sequence.get("commands", []):
		if String((command_value as Dictionary).get("type", "")) == command_type:
			return true
	return false


func _first_child_of_type(room: Node, class_type: String) -> Node:
	for child: Node in room.get_children():
		if child.is_class(class_type) or (class_type == "CorruptionZone" and child is CorruptionZone) or (class_type == "PersistentAbilityPickup" and child is PersistentAbilityPickup) or (class_type == "BossArenaController" and child is BossArenaController) or (class_type == "BossBase" and child is BossBase):
			return child
	return null


func _first_descendant_of_type(node: Node, class_type: String) -> Node:
	for child: Node in node.get_children():
		if (class_type == "PortraitView" and child is PortraitView) or (class_type == "PlayerVisual" and child is PlayerVisual):
			return child
		var found := _first_descendant_of_type(child, class_type)
		if found != null:
			return found
	return null


func _find_label_containing(node: Node, text: String) -> Label:
	if node is Label and text.to_lower() in (node as Label).text.to_lower():
		return node as Label
	for child: Node in node.get_children():
		var found := _find_label_containing(child, text)
		if found != null:
			return found
	return null


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for child: Node in node.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


func _wait_for_room(world: Node, room_id: String) -> void:
	for _frame: int in range(180):
		await process_frame
		if not world.transition_in_progress and world.current_room_id == room_id:
			return


func _clear_narrative() -> void:
	var director := root.get_node("CutsceneDirector")
	var dialogue := root.get_node("DialogueController")
	dialogue.call(&"cancel_current")
	if not String(director.get("active_sequence_id")).is_empty():
		director.call(&"request_skip")
	for _frame: int in range(90):
		await process_frame
		if String(director.get("active_sequence_id")).is_empty() and String(dialogue.get("active_entry_id")).is_empty():
			return


func _clean_shutdown(scene: Node) -> void:
	var dialogue := root.get_node("DialogueController")
	dialogue.call(&"cancel_current")
	await process_frame
	var voice := dialogue.get("_voice") as VoiceBarkPlayer
	if voice != null:
		voice.stop_bark()
	if scene != null:
		for bark_node: Node in scene.find_children("*", "VoiceBarkPlayer", true, false):
			(bark_node as VoiceBarkPlayer).stop_bark()
		scene.queue_free()
	for _frame: int in range(5):
		await process_frame


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
