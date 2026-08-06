extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/WorldRoot.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(15.0, true, false, true).timeout.connect(func() -> void:
		push_error("Rooftop vertical-slice test timed out.")
		quit(1)
	)
	var rooms := WorldDatabase.rooms()
	var rooftop_ids: Array[String] = []
	for room_id: String in rooms:
		if String((rooms[room_id] as Dictionary).get("district_id", "")) == "rooftop_alley":
			rooftop_ids.append(room_id)
	if not _require(rooftop_ids.size() == 12, "Rooftop Alley must contain ten critical-path rooms plus two optional routes."):
		return

	var critical_path: Array[String] = []
	var current_id := WorldProgress.START_ROOM
	while rooms.has(current_id) and String((rooms[current_id] as Dictionary).get("district_id", "")) == "rooftop_alley":
		if critical_path.has(current_id):
			break
		critical_path.append(current_id)
		var east_target := ""
		for connection_value: Variant in (rooms[current_id] as Dictionary).get("connections", []):
			var connection := connection_value as Dictionary
			if String(connection.get("id", "")) == "east":
				east_target = String(connection.get("target_room", ""))
				break
		current_id = east_target
	if not _require(critical_path.size() == 10 and current_id == "cyber_billboard_entry", "Rooftop critical path does not reach Billboard Highway through ten stable rooms."):
		return

	var first_pass_seconds := 0
	var expert_seconds := 0
	var encounter_count := 0
	var authored_enemies := 0
	var tutorials: Dictionary = {}
	for room_id: String in rooftop_ids:
		var room: Dictionary = rooms[room_id]
		if critical_path.has(room_id):
			var pacing: Dictionary = room.get("pacing", {})
			first_pass_seconds += int(pacing.get("first_pass_seconds", 0))
			expert_seconds += int(pacing.get("expert_seconds", 0))
		var tutorial_id := String(room.get("tutorial", ""))
		if not tutorial_id.is_empty():
			tutorials[tutorial_id] = true
		for encounter_value: Variant in room.get("encounters", []):
			encounter_count += 1
			for wave_value: Variant in (encounter_value as Dictionary).get("waves", []):
				authored_enemies += (wave_value as Array).size()
		for spawn_value: Variant in (room.get("spawns", {}) as Dictionary).values():
			var spawn: Array = spawn_value as Array
			if not _require(spawn.size() == 2 and Rect2(0, 0, 960, 540).grow(-8.0).has_point(Vector2(float(spawn[0]), float(spawn[1]))), "Room %s contains an out-of-bounds spawn." % room_id):
				return
	if not _require(first_pass_seconds >= 900 and first_pass_seconds <= 1200 and expert_seconds <= 420, "Authored Rooftop pacing is outside the 15–20 minute first-pass / sub-7-minute expert targets."):
		return
	if not _require(tutorials.has("movement") and tutorials.has("combat") and tutorials.has("teleport"), "Rooftop Alley does not cover movement, combat, and teleport onboarding."):
		return
	if not _require(encounter_count >= 4 and authored_enemies >= 9, "Rooftop Alley lacks the planned combat escalation and guardian cadence."):
		return
	var cache: Dictionary = rooms.get("cyber_rooftop_cache", {})
	var market: Dictionary = rooms.get("cyber_rooftop_market", {})
	var shortcut: Dictionary = rooms.get("cyber_rooftop_shortcut", {})
	var overlook: Dictionary = rooms.get("cyber_rooftop_overlook", {})
	var guardian: Dictionary = rooms.get("cyber_rooftop_guardian", {})
	if not _require(cache.has("reward") and String((cache.reward as Dictionary).get("family", "")) == "dagger", "Optional teleport cache does not contain the alternate weapon reward."):
		return
	if not _require(market.has("save_room") and (market.get("services", []) as Array).size() >= 3, "Night Market does not provide save, Mara, barber, and tailor services."):
		return
	if not _require(shortcut.has("shortcut") and overlook.has("warp_room") and _has_required_connection(guardian, &"magnetic_rail"), "Rooftop shortcut, warp, or visible backtracking hook is missing."):
		return

	var game := root.get_node("GameManager")
	game.call(&"new_game")
	var profile := CharacterProfile.new()
	profile.creation_complete = true
	if not _require(game.call(&"commit_character_profile", profile), "Rooftop test could not commit its player profile."):
		return
	var world_root := WORLD_SCENE.instantiate() as Node2D
	root.add_child(world_root)
	var world := root.get_node("WorldManager")
	await _wait_for_room(world, WorldProgress.START_ROOM)
	world.call(&"transition_to", "cyber_rooftop_signworks", "west", false)
	await _wait_for_room(world, "cyber_rooftop_signworks")
	var encounter := _find_encounter(world.room_loader.current_room, &"rooftop_signworks_lockdown")
	if not _require(encounter != null and not encounter.is_active() and encounter.get_live_enemy_count() == 2 and encounter.get_wave_count() == 2, "Streamed Signworks encounter did not begin dormant with its authored first wave."):
		return
	encounter.call(&"_on_body_entered", world.player)
	for _pass: int in range(6):
		for enemy: EnemyBase in encounter.get_live_enemies():
			enemy.take_damage(enemy.health)
		await process_frame
		if encounter.is_complete():
			break
	if not _require(encounter.is_complete() and bool(game.world_progress.get_object_state("encounter::rooftop_signworks_lockdown", false)), "Multi-wave Signworks encounter did not complete persistently."):
		return
	world.call(&"transition_to", "cyber_rooftop_phase_tutorial", "east", false)
	await _wait_for_room(world, "cyber_rooftop_phase_tutorial")
	world.call(&"transition_to", "cyber_rooftop_signworks", "west", false)
	await _wait_for_room(world, "cyber_rooftop_signworks")
	encounter = _find_encounter(world.room_loader.current_room, &"rooftop_signworks_lockdown")
	if not _require(encounter != null and encounter.is_complete() and encounter.get_live_enemy_count() == 0, "Completed streamed encounter respawned after leaving and returning to the room."):
		return

	print("ROOFTOP_VERTICAL_SLICE_TEST_OK rooms=", rooftop_ids.size(), " pacing=", first_pass_seconds, "s encounters=", encounter_count, " enemies=", authored_enemies)
	world_root.queue_free()
	profile = null
	await process_frame
	CreatorAnimationCatalog.clear_runtime_cache()
	quit()


func _has_required_connection(room: Dictionary, ability_id: StringName) -> bool:
	for connection_value: Variant in room.get("connections", []):
		if StringName((connection_value as Dictionary).get("required_ability", "")) == ability_id:
			return true
	return false


func _find_encounter(room: Node, encounter_id: StringName) -> EncounterController:
	for candidate: Node in room.get_children():
		if candidate is EncounterController and (candidate as EncounterController).encounter_id == encounter_id:
			return candidate as EncounterController
	return null


func _wait_for_room(world: Node, room_id: String) -> void:
	for _frame: int in range(120):
		await process_frame
		if not world.transition_in_progress and world.current_room_id == room_id:
			return


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
