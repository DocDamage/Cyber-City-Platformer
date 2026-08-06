extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/WorldRoot.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(12.0, true, false, true).timeout.connect(func() -> void:
		push_error("Ability barrier test timed out.")
		quit(1)
	)
	var game := root.get_node("GameManager")
	game.call(&"new_game")
	var profile := CharacterProfile.new()
	profile.creation_complete = true
	if not _require(game.call(&"commit_character_profile", profile), "Ability barrier test could not commit its player profile."):
		return
	var world_root := WORLD_SCENE.instantiate() as Node2D
	root.add_child(world_root)
	var world := root.get_node("WorldManager")
	await _wait_for_room(world, WorldProgress.START_ROOM)
	world.call(&"transition_to", "cyber_rooftop_guardian", "west", false)
	await _wait_for_room(world, "cyber_rooftop_guardian")
	var connection: RoomConnection
	for candidate: Node in world.room_loader.current_room.get_children():
		if candidate is RoomConnection and (candidate as RoomConnection).connection_id == "magnetic_rail":
			connection = candidate as RoomConnection
			break
	if not _require(connection != null and connection.is_locked(), "Rooftop Alley is missing its locked magnetic-rail backtracking route."):
		return
	if not _require(connection._barrier != null and connection._barrier.collision_layer == 1 and connection._barrier.visible, "Locked route did not install a visible world-collision barrier."):
		return
	connection.call(&"_on_body_entered", world.player)
	await process_frame
	if not _require(world.current_room_id == "cyber_rooftop_guardian", "A player without Magnetic Rail bypassed the locked connection."):
		return
	var record: Dictionary = game.world_progress.known_locked_barriers.get("barrier_rooftop_spire_rail", {})
	if not _require(String(record.get("room_id", "")) == "cyber_rooftop_guardian" and String(record.get("required_ability", "")) == "magnetic_rail", "Encountering the barrier did not reveal it on persistent map state."):
		return
	var restored := WorldProgress.new()
	if not _require(restored.load_dict(game.world_progress.to_dict()) and restored.known_locked_barriers.has("barrier_rooftop_spire_rail"), "Known locked barrier did not survive a state round trip."):
		return
	if not _require(game.call(&"grant_ability", &"magnetic_rail"), "Magnetic Rail ability could not be granted."):
		return
	await process_frame
	if not _require(not connection.is_locked() and connection._barrier.collision_layer == 0 and not connection._barrier.visible, "Unlocking Magnetic Rail did not open the route."):
		return
	connection.call(&"_on_body_entered", world.player)
	await _wait_for_room(world, "cyber_spire_entry")
	if not _require(world.current_room_id == "cyber_spire_entry" and game.world_progress.discovered_rooms.has("cyber_spire_entry"), "Unlocked backtracking route did not reach and discover Communication Spire."):
		return

	print("ABILITY_BARRIER_TEST_OK barrier=barrier_rooftop_spire_rail target=", world.current_room_id)
	world_root.queue_free()
	profile = null
	restored = null
	await process_frame
	CreatorAnimationCatalog.clear_runtime_cache()
	quit()


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
