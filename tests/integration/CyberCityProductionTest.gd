extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/WorldRoot.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(18.0, true, false, true).timeout.connect(func() -> void:
		push_error("Cyber City production test timed out.")
		quit(1)
	)
	var rooms := WorldDatabase.rooms()
	var districts := {
		"rooftop_alley": 12,
		"billboard_highway": 10,
		"communication_spire": 10,
		"skybridge_junction": 10,
		"executive_helipad": 10,
	}
	var cyber_count := 0
	for district_id: String in districts:
		var district_rooms: Array[String] = []
		for room_id: String in rooms:
			var room := rooms[room_id] as Dictionary
			if String(room.get("region_id", "")) == "cyber_city" and String(room.get("district_id", "")) == district_id:
				district_rooms.append(room_id)
		cyber_count += district_rooms.size()
		if not _require(district_rooms.size() >= int(districts[district_id]), "District %s is still an entry-room greybox." % district_id):
			return
	if not _require(cyber_count == 52 and WorldDatabase.reachable_rooms().size() == WorldDatabase.room_count(), "Expanded Cyber City is not part of one fully reachable world graph."):
		return

	for entry_id: String in ["cyber_billboard_entry", "cyber_spire_entry", "cyber_skybridge_entry", "cyber_helipad_entry"]:
		var pacing := _critical_path_pacing(rooms, entry_id)
		if not _require(pacing >= 900 and pacing <= 1200, "District beginning at %s is outside its 15–20 minute authored first-pass budget (%ds)." % [entry_id, pacing]):
			return
	if not _require(_count_key(rooms, "moving_platforms", "cyber_city") >= 5 and _count_key(rooms, "breakaway_platforms", "cyber_city") >= 4, "Cyber City lacks its moving/breakaway traversal cadence."):
		return
	if not _require(_has_hazard(rooms, "laser_grid") and _has_hazard(rooms, "rotating_laser") and _has_hazard(rooms, "gravity_zone") and _has_hazard(rooms, "void_pit"), "Cyber City does not instantiate its authored hazard families."):
		return
	if not _require(String((rooms.cyber_billboard_underdeck.reward as Dictionary).get("family", "")) == "bow" and String((rooms.cyber_skybridge_challenge.reward as Dictionary).get("family", "")) == "spear", "Cyber City optional routes are missing their Bow/Spear rewards."):
		return
	if not _require(String((rooms.cyber_spire_crown.ability_reward as Dictionary).get("ability", "")) == "magnetic_rail" and String((rooms.cyber_helipad_arena.boss as Dictionary).get("id", "")) == "helix_warden", "Cyber City progression ability or regional boss is missing."):
		return

	var game := root.get_node("GameManager")
	game.call(&"new_game")
	var profile := CharacterProfile.new()
	profile.creation_complete = true
	if not _require(game.call(&"commit_character_profile", profile), "Cyber City test could not commit its player profile."):
		return
	var world_root := WORLD_SCENE.instantiate() as Node2D
	root.add_child(world_root)
	var world := root.get_node("WorldManager")
	await _wait_for_room(world, WorldProgress.START_ROOM)
	world.call(&"transition_to", "cyber_spire_crown", "south", false)
	await _wait_for_room(world, "cyber_spire_crown")
	var ability_pickup := _first_child_of_type(world.room_loader.current_room, "PersistentAbilityPickup") as PersistentAbilityPickup
	if not _require(ability_pickup != null and ability_pickup.collect_for_test() and game.abilities.has(&"magnetic_rail"), "Magnetic Rail reward did not grant persistent progression."):
		return
	await process_frame
	world.call(&"transition_to", "cyber_helipad_arena", "west", false)
	await _wait_for_room(world, "cyber_helipad_arena")
	var boss := _first_child_of_type(world.room_loader.current_room, "BossBase") as BossBase
	var arena := _first_child_of_type(world.room_loader.current_room, "BossArenaController") as BossArenaController
	if not _require(boss != null and arena != null and boss.boss_name == "HELIX WARDEN", "Helix Warden and its teleport-safe arena did not stream into the helipad."):
		return
	boss.start_encounter()
	await process_frame
	if not _require(arena.is_locked() and _all_arena_barriers_visible(arena), "Helix Warden encounter did not close both authored arena exits."):
		return
	boss.complete_intro()
	boss.take_damage(boss.health)
	await process_frame
	if not _require(not arena.is_locked() and not _any_arena_barrier_visible(arena) and game.world_progress.defeated_bosses.has("helix_warden") and game.abilities.has(&"phase_barrier") and game.has_story_flag(&"helix_warden_defeated"), "Helix Warden defeat did not permanently reopen the route, persist, or grant the Phase Barrier reward."):
		return
	world.call(&"transition_to", "cyber_helipad_checkpoint", "east", false)
	await _wait_for_room(world, "cyber_helipad_checkpoint")
	world.call(&"transition_to", "cyber_helipad_arena", "west", false)
	await _wait_for_room(world, "cyber_helipad_arena")
	if not _require(_first_child_of_type(world.room_loader.current_room, "BossBase") == null, "Defeated Helix Warden respawned after room streaming."):
		return

	print("CYBER_CITY_PRODUCTION_TEST_OK rooms=", cyber_count, " boss=helix_warden ability=", game.abilities.has(&"phase_barrier"))
	world_root.queue_free()
	profile = null
	await process_frame
	CreatorAnimationCatalog.clear_runtime_cache()
	quit()


func _critical_path_pacing(rooms: Dictionary, entry_id: String) -> int:
	var district_id := String((rooms[entry_id] as Dictionary).get("district_id", ""))
	var main_connection := "north" if district_id == "communication_spire" else "east"
	var room_id := entry_id
	var visited: Dictionary = {}
	var total := 0
	while rooms.has(room_id) and String((rooms[room_id] as Dictionary).get("district_id", "")) == district_id and not visited.has(room_id):
		visited[room_id] = true
		total += int(((rooms[room_id] as Dictionary).get("pacing", {}) as Dictionary).get("first_pass_seconds", 0))
		var next_id := ""
		for connection_value: Variant in (rooms[room_id] as Dictionary).get("connections", []):
			if String((connection_value as Dictionary).get("id", "")) == main_connection:
				next_id = String((connection_value as Dictionary).get("target_room", ""))
				break
		room_id = next_id
	return total


func _count_key(rooms: Dictionary, key: String, region_id: String) -> int:
	var total := 0
	for room_value: Variant in rooms.values():
		var room := room_value as Dictionary
		if String(room.get("region_id", "")) == region_id:
			total += (room.get(key, []) as Array).size()
	return total


func _has_hazard(rooms: Dictionary, hazard_type: String) -> bool:
	for room_value: Variant in rooms.values():
		for hazard_value: Variant in (room_value as Dictionary).get("hazards", []):
			if String((hazard_value as Dictionary).get("type", "")) == hazard_type:
				return true
	return false


func _first_child_of_type(room: Node, class_type: String) -> Node:
	for child: Node in room.get_children():
		if child.is_class(class_type) or (class_type == "PersistentAbilityPickup" and child is PersistentAbilityPickup) or (class_type == "BossArenaController" and child is BossArenaController) or (class_type == "BossBase" and child is BossBase):
			return child
	return null


func _all_arena_barriers_visible(arena: BossArenaController) -> bool:
	if arena._barriers.size() != 2:
		return false
	for barrier: StaticBody2D in arena._barriers:
		if not barrier.visible or barrier.process_mode == Node.PROCESS_MODE_DISABLED:
			return false
	return true


func _any_arena_barrier_visible(arena: BossArenaController) -> bool:
	for barrier: StaticBody2D in arena._barriers:
		if barrier.visible or barrier.process_mode != Node.PROCESS_MODE_DISABLED:
			return true
	return false


func _wait_for_room(world: Node, room_id: String) -> void:
	for _frame: int in range(150):
		await process_frame
		if not world.transition_in_progress and world.current_room_id == room_id:
			return


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
