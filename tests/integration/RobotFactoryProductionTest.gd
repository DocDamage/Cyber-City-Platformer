extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/WorldRoot.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		push_error("Robot Factory production test timed out.")
		quit(1)
	)
	if not _require(not OS.get_environment("CCP_TEST_SAVE_DIR").is_empty(), "Robot Factory test requires an isolated save directory."):
		return
	var validation := WorldDatabase.validate()
	if not _require(validation.is_empty(), "Factory world data failed validation: %s" % validation):
		return
	var rooms := WorldDatabase.rooms()
	var district_minimums := {
		"sub_level_intake": 10,
		"conveyor_assembly": 10,
		"smelting_core": 10,
		"robotic_maintenance": 10,
		"assembly_engine": 10,
	}
	var factory_count := 0
	for district_id: String in district_minimums:
		var count := _district_room_count(rooms, district_id)
		factory_count += count
		if not _require(count >= int(district_minimums[district_id]), "Factory district %s is still an entry-room greybox." % district_id):
			return
	if not _require(factory_count == 50 and WorldDatabase.reachable_rooms().size() == WorldDatabase.room_count(), "Factory expansion is not part of one fully reachable world graph."):
		return

	for entry_id: String in ["factory_intake_entry", "factory_conveyor_entry", "factory_smelting_entry", "factory_maintenance_entry", "factory_engine_entry"]:
		var pacing := _critical_path_pacing(rooms, entry_id)
		if not _require(pacing >= 900 and pacing <= 1200, "District beginning at %s is outside its 15–20 minute authored first-pass budget (%ds)." % [entry_id, pacing]):
			return
	if not _require(_count_key(rooms, "conveyors") >= 10 and _count_key(rooms, "moving_platforms") >= 7, "Factory lacks its authored conveyor and lift cadence."):
		return
	for hazard_type: String in ["steam_vent", "toxic_pool", "crusher", "falling", "laser_grid", "electrical_floor", "void_pit"]:
		if not _require(_has_factory_hazard(rooms, hazard_type), "Factory hazard family %s is missing." % hazard_type):
			return
	if not _require(_factory_encounters_use_roster(rooms), "Factory encounters do not use the industrial enemy roster."):
		return
	if not _require(String((rooms.factory_conveyor_control.reward as Dictionary).get("family", "")) == "heavy" and String((rooms.factory_smelting_coolant.reward as Dictionary).get("family", "")) == "staff" and String((rooms.factory_maintenance_archive.reward as Dictionary).get("family", "")) == "dagger", "Factory optional routes are missing weapon-family rewards."):
		return
	if not _require(String((rooms.factory_smelting_ascent.ability_reward as Dictionary).get("ability", "")) == "heavy_ground_break", "Factory progression does not grant Kinetic Ground Break."):
		return
	if not _require(String((rooms.factory_engine_arena.boss as Dictionary).get("id", "")) == "assembly_colossus", "Assembly Colossus is missing from the region finale."):
		return
	if not _require(_connection_requires(rooms.cyber_helipad_descent, "east", &"phase_barrier") and rooms.factory_intake_lift.has("shortcut"), "Factory is missing its boss gate or cross-region elevator shortcut."):
		return

	var game := root.get_node("GameManager")
	var save := root.get_node("SaveManager")
	save.call(&"set_active_slot", 2)
	save.call(&"reset_save", 2)
	game.call(&"new_game")
	var profile := CharacterProfile.new()
	profile.character_name = "Forge"
	profile.creation_complete = true
	if not _require(game.call(&"commit_character_profile", profile), "Factory test could not commit its player profile."):
		return
	game.run_state.stage_scene = "res://scenes/world/WorldRoot.tscn"
	var world_root := WORLD_SCENE.instantiate() as Node2D
	root.add_child(world_root)
	var world := root.get_node("WorldManager")
	await _wait_for_room(world, WorldProgress.START_ROOM)
	world.call(&"transition_to", "factory_smelting_ascent", "west", false)
	await _wait_for_room(world, "factory_smelting_ascent")
	var ability_pickup := _first_child_of_type(world.room_loader.current_room, "PersistentAbilityPickup") as PersistentAbilityPickup
	if not _require(ability_pickup != null and ability_pickup.collect_for_test() and game.abilities.has(&"heavy_ground_break"), "Kinetic Ground Break did not grant persistent factory progression."):
		return

	world.call(&"transition_to", "factory_conveyor_switchyard", "west", false)
	await _wait_for_room(world, "factory_conveyor_switchyard")
	var switchyard_room: Node = world.room_loader.current_room
	var controlled_belt := switchyard_room.get_node_or_null("ConveyorSwitchyardWest") as Conveyor
	var belt_switch := switchyard_room.get_node_or_null("SwitchConveyorWest") as InteractiveTerminal
	if not _require(controlled_belt != null and belt_switch != null, "Conveyor Assembly did not stream its manual reversal controls."):
		return
	var direction_before := controlled_belt.current_direction()
	belt_switch.activate()
	if not _require(controlled_belt.current_direction() == -direction_before and bool(game.world_progress.get_object_state("switch_conveyor_west", false)), "Conveyor switch did not reverse and persist its target belt."):
		return

	world.call(&"transition_to", "factory_conveyor_control", "north", false)
	await _wait_for_room(world, "factory_conveyor_control")
	var control_room: Node = world.room_loader.current_room
	var cache_gate := control_room.get_node_or_null("GateConveyorServiceCache") as SecurityGate
	var cache_switch_a := control_room.get_node_or_null("SwitchConveyorServiceA") as InteractiveTerminal
	var cache_switch_b := control_room.get_node_or_null("SwitchConveyorServiceB") as InteractiveTerminal
	if not _require(cache_gate != null and cache_switch_a != null and cache_switch_b != null, "Optional conveyor switch-order cache did not stream."):
		return
	cache_switch_a.activate()
	if not _require(not cache_gate.is_open, "Two-switch conveyor cache opened after only one control."):
		return
	cache_switch_b.activate()
	await process_frame
	if not _require(cache_gate.is_open and bool(game.world_progress.get_object_state("gate_conveyor_service_cache", false)), "Two-switch conveyor cache did not open and persist after both controls."):
		return

	world.call(&"transition_to", "factory_maintenance_control", "west", false)
	await _wait_for_room(world, "factory_maintenance_control")
	var shortcut := _first_child_of_type(world.room_loader.current_room, "PersistentShortcut") as PersistentShortcut
	if not _require(shortcut != null, "Maintenance control did not stream its persistent shortcut."):
		return
	shortcut.call(&"_open")
	if not _require(bool(game.world_progress.get_object_state("shortcut_maintenance_service", false)), "Factory shortcut state did not persist in world progress."):
		return

	world.call(&"transition_to", "factory_engine_arena", "west", false)
	await _wait_for_room(world, "factory_engine_arena")
	var boss := _first_child_of_type(world.room_loader.current_room, "BossBase") as BossBase
	var arena := _first_child_of_type(world.room_loader.current_room, "BossArenaController") as BossArenaController
	if not _require(boss != null and arena != null and boss.boss_name == "ASSEMBLY COLOSSUS" and boss.get_attack_roster().has(&"vulnerability_window"), "Assembly Colossus and its multi-phase arena did not stream correctly."):
		return
	boss.start_encounter()
	boss.complete_intro()
	boss.take_damage(boss.health)
	await process_frame
	if not _require(game.world_progress.defeated_bosses.has("assembly_colossus") and game.has_story_flag(&"assembly_colossus_defeated"), "Assembly Colossus defeat did not persist its factory completion state."):
		return
	if not _require(save.call(&"save_game", 2), "Factory progression could not be saved."):
		return
	game.world_progress.defeated_bosses.clear()
	game.world_progress.persistent_object_states.clear()
	game.abilities.clear()
	if not _require(save.call(&"load_game", false, 2), "Factory progression save could not be reloaded."):
		return
	if not _require(game.world_progress.defeated_bosses.has("assembly_colossus") and game.abilities.has(&"heavy_ground_break") and bool(game.world_progress.get_object_state("shortcut_maintenance_service", false)) and bool(game.world_progress.get_object_state("gate_conveyor_service_cache", false)), "Factory boss, ability, shortcut, or security-control state failed its save/load round trip."):
		return
	world.call(&"transition_to", "factory_conveyor_control", "north", false)
	await _wait_for_room(world, "factory_conveyor_control")
	cache_gate = world.room_loader.current_room.get_node_or_null("GateConveyorServiceCache") as SecurityGate
	await process_frame
	if not _require(cache_gate != null and cache_gate.is_open, "Persisted conveyor control gate did not restore after room streaming and reload."):
		return
	world.call(&"transition_to", "factory_engine_entry", "east", false)
	await _wait_for_room(world, "factory_engine_entry")
	world.call(&"transition_to", "factory_engine_arena", "west", false)
	await _wait_for_room(world, "factory_engine_arena")
	if not _require(_first_child_of_type(world.room_loader.current_room, "BossBase") == null, "Defeated Assembly Colossus respawned after streaming and reload."):
		return

	print("ROBOT_FACTORY_PRODUCTION_TEST_OK rooms=", factory_count, " boss=assembly_colossus ability=", game.abilities.has(&"heavy_ground_break"))
	await _clean_shutdown(world_root)
	profile = null
	save.call(&"reset_save", 2)
	CreatorAnimationCatalog.clear_runtime_cache()
	quit()


func _district_room_count(rooms: Dictionary, district_id: String) -> int:
	var count := 0
	for room_value: Variant in rooms.values():
		var room := room_value as Dictionary
		if String(room.get("region_id", "")) == "robot_factory" and String(room.get("district_id", "")) == district_id:
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
		if String(room.get("region_id", "")) == "robot_factory":
			total += (room.get(key, []) as Array).size()
	return total


func _has_factory_hazard(rooms: Dictionary, hazard_type: String) -> bool:
	for room_value: Variant in rooms.values():
		var room := room_value as Dictionary
		if String(room.get("region_id", "")) != "robot_factory":
			continue
		for hazard_value: Variant in room.get("hazards", []):
			if String((hazard_value as Dictionary).get("type", "")) == hazard_type:
				return true
	return false


func _factory_encounters_use_roster(rooms: Dictionary) -> bool:
	var roster := {"stone_golem":true,"pyromancer":true,"cyclops":true,"imp":true,"minotaur":true}
	var found: Dictionary = {}
	for room_value: Variant in rooms.values():
		var room := room_value as Dictionary
		if String(room.get("region_id", "")) != "robot_factory":
			continue
		for encounter_value: Variant in room.get("encounters", []):
			for wave_value: Variant in (encounter_value as Dictionary).get("waves", []):
				for enemy_value: Variant in wave_value as Array:
					var enemy_id := String((enemy_value as Dictionary).get("enemy", ""))
					if roster.has(enemy_id):
						found[enemy_id] = true
	return found.size() >= 5


func _connection_requires(room: Dictionary, connection_id: String, ability_id: StringName) -> bool:
	for connection_value: Variant in room.get("connections", []):
		var connection := connection_value as Dictionary
		if String(connection.get("id", "")) == connection_id and StringName(connection.get("required_ability", "")) == ability_id:
			return true
	return false


func _first_child_of_type(room: Node, class_type: String) -> Node:
	for child: Node in room.get_children():
		if child.is_class(class_type) or (class_type == "PersistentAbilityPickup" and child is PersistentAbilityPickup) or (class_type == "PersistentShortcut" and child is PersistentShortcut) or (class_type == "BossArenaController" and child is BossArenaController) or (class_type == "BossBase" and child is BossBase):
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


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
