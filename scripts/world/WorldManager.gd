extends Node

signal world_bound
signal transition_started(from_room_id: String, to_room_id: String)
signal transition_completed(room_id: String, spawn_connection_id: String)
signal transition_failed(room_id: String, reason: String)
signal fast_travel_completed(warp_node_id: String)

var world_root: Node2D
var player: CharacterBody2D
var room_loader := RoomLoader.new()
var current_room_id := ""
var transition_in_progress := false
var _current_region_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	room_loader.name = "RoomLoader"
	add_child(room_loader)


func bind_world(root_node: Node2D, room_container: Node2D, player_node: CharacterBody2D) -> bool:
	if root_node == null or room_container == null or player_node == null:
		return false
	world_root = root_node
	player = player_node
	room_loader.configure(room_container)
	world_bound.emit()
	return true


func load_initial_room() -> bool:
	var manager := get_node_or_null("/root/GameManager")
	var room_id := WorldDatabase.start_room_id()
	var spawn_id := "new_game"
	if manager != null and manager.get("world_progress") is WorldProgress:
		var progress := manager.world_progress as WorldProgress
		room_id = progress.current_room_id if not progress.current_room_id.is_empty() else room_id
		spawn_id = progress.spawn_connection_id if not progress.spawn_connection_id.is_empty() else spawn_id
	return await _transition(room_id, spawn_id, false, true)


func transition_to(room_id: String, spawn_connection_id: String, preserve_velocity := false) -> void:
	if transition_in_progress:
		return
	_transition.call_deferred(room_id, spawn_connection_id, preserve_velocity, false)


func fast_travel(warp_node_id: String) -> bool:
	if not can_fast_travel_to(warp_node_id):
		return false
	var node := WorldDatabase.fast_travel_node(warp_node_id)
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		save_manager.call(&"save_game")
	var success := await _transition(String(node.room_id), "warp", false, false)
	if success:
		if save_manager != null:
			save_manager.call(&"save_game")
		fast_travel_completed.emit(warp_node_id)
	return success


func can_fast_travel_from_current_room() -> bool:
	return not transition_in_progress and not _world_travel_locked() and _current_room_has_active_warp()


func can_fast_travel_to(warp_node_id: String) -> bool:
	if not can_fast_travel_from_current_room():
		return false
	var manager := get_node_or_null("/root/GameManager")
	if manager == null or not manager.world_progress.activated_warp_nodes.has(warp_node_id):
		return false
	var node := WorldDatabase.fast_travel_node(warp_node_id)
	if node.is_empty() or String(node.get("room_id", "")) == current_room_id:
		return false
	return WorldDatabase.fast_travel_node_available(warp_node_id, manager.story_flags)


func _transition(room_id: String, spawn_connection_id: String, preserve_velocity: bool, initial: bool) -> bool:
	if transition_in_progress or player == null:
		return false
	var definition := WorldDatabase.room(room_id)
	if definition.is_empty():
		transition_failed.emit(room_id, "Unknown room.")
		return false
	transition_in_progress = true
	var from_room := current_room_id
	transition_started.emit(from_room, room_id)
	var retained_velocity := player.velocity if preserve_velocity else Vector2.ZERO
	player.call(&"set_input_disabled", true)
	var transition := get_node_or_null("/root/SceneTransition")
	if not initial and transition != null and transition.has_method(&"fade_out"):
		await transition.call(&"fade_out")
	var room := room_loader.load_room(room_id)
	if room == null:
		player.call(&"set_input_disabled", false)
		transition_in_progress = false
		transition_failed.emit(room_id, "Room loader rejected the destination.")
		return false
	current_room_id = room_id
	_update_region_audio(String(definition.get("region_id", "cyber_city")))
	player.global_position = room.spawn_position(spawn_connection_id)
	player.velocity = retained_velocity
	_update_player_room_bounds(room)
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.call(&"enter_world_room", String(definition.region_id), String(definition.district_id), room_id, spawn_connection_id)
	player.call(&"set_input_disabled", false)
	if not initial and transition != null and transition.has_method(&"fade_in"):
		await transition.call(&"fade_in")
	transition_in_progress = false
	transition_completed.emit(room_id, spawn_connection_id)
	return true


func _update_player_room_bounds(room: WorldRoom) -> void:
	if player == null:
		return
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.limit_left = int(room.bounds.position.x)
		camera.limit_top = int(room.bounds.position.y)
		camera.limit_right = int(room.bounds.end.x)
		camera.limit_bottom = int(room.bounds.end.y)
		camera.reset_smoothing()
		camera.force_update_scroll()
	var teleport := player.get_node_or_null("TeleportController") as TeleportController
	if teleport != null and teleport.resolver != null:
		teleport.resolver.world_bounds = room.bounds


func _current_room_has_active_warp() -> bool:
	var definition := WorldDatabase.room(current_room_id)
	if not definition.has("warp_room"):
		return false
	var warp_id := String((definition.warp_room as Dictionary).get("id", ""))
	var manager := get_node_or_null("/root/GameManager")
	return manager != null and manager.world_progress.activated_warp_nodes.has(warp_id)


func _world_travel_locked() -> bool:
	var director := get_node_or_null("/root/CutsceneDirector")
	if director != null and not String(director.get("active_sequence_id")).is_empty():
		return true
	if get_tree() == null:
		return false
	for arena: Node in get_tree().get_nodes_in_group(&"boss_arenas"):
		if arena.has_method(&"is_locked") and bool(arena.call(&"is_locked")):
			return true
	return false


func _update_region_audio(region_id: String) -> void:
	if region_id == _current_region_id:
		return
	_current_region_id = region_id
	var act_by_region := {"cyber_city":1, "robot_factory":2, "neon_moon":3, "abyssal_night":4}
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call(&"play_bgm", int(act_by_region.get(region_id, 1)))
		audio.call(&"play_region_ambience", region_id)
