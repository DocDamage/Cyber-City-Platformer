class_name WorldProgress
extends RefCounted

const START_ROOM := "cyber_rooftop_entry"

var current_region_id := "cyber_city"
var current_district_id := "rooftop_alley"
var current_room_id := START_ROOM
var spawn_connection_id := "new_game"
var last_safe_save_room_id := ""
var discovered_rooms: Dictionary = {}
var discovered_save_rooms: Dictionary = {}
var known_locked_barriers: Dictionary = {}
var persistent_object_states: Dictionary = {}
var activated_warp_nodes: Dictionary = {}
var defeated_bosses: Dictionary = {}


func clear() -> void:
	current_region_id = "cyber_city"
	current_district_id = "rooftop_alley"
	current_room_id = START_ROOM
	spawn_connection_id = "new_game"
	last_safe_save_room_id = ""
	discovered_rooms = {START_ROOM: true}
	discovered_save_rooms.clear()
	known_locked_barriers.clear()
	persistent_object_states.clear()
	activated_warp_nodes.clear()
	defeated_bosses.clear()


func discover_room(room_id: String) -> bool:
	if room_id.is_empty() or discovered_rooms.has(room_id):
		return false
	discovered_rooms[room_id] = true
	return true


func set_object_state(object_id: String, value: Variant) -> bool:
	if object_id.is_empty():
		return false
	persistent_object_states[object_id] = value
	return true


func get_object_state(object_id: String, fallback: Variant = null) -> Variant:
	return persistent_object_states.get(object_id, fallback)


func activate_warp(warp_id: String) -> bool:
	if warp_id.is_empty() or activated_warp_nodes.has(warp_id):
		return false
	activated_warp_nodes[warp_id] = true
	return true


func discover_locked_barrier(barrier_id: String, room_id: String, required_ability: StringName) -> bool:
	if barrier_id.is_empty() or room_id.is_empty() or required_ability.is_empty() or known_locked_barriers.has(barrier_id):
		return false
	known_locked_barriers[barrier_id] = {
		"room_id": room_id,
		"required_ability": String(required_ability),
	}
	return true


func map_completion(total_room_count: int) -> float:
	return 0.0 if total_room_count <= 0 else clampf(float(discovered_rooms.size()) / float(total_room_count), 0.0, 1.0)


func to_dict() -> Dictionary:
	return {
		"current_region_id": current_region_id,
		"current_district_id": current_district_id,
		"current_room_id": current_room_id,
		"spawn_connection_id": spawn_connection_id,
		"last_safe_save_room_id": last_safe_save_room_id,
		"discovered_rooms": discovered_rooms.duplicate(true),
		"discovered_save_rooms": discovered_save_rooms.duplicate(true),
		"known_locked_barriers": known_locked_barriers.duplicate(true),
		"persistent_object_states": persistent_object_states.duplicate(true),
		"activated_warp_nodes": activated_warp_nodes.duplicate(true),
		"defeated_bosses": defeated_bosses.duplicate(true),
	}


func load_dict(data: Variant) -> bool:
	if data is not Dictionary:
		return false
	var values := data as Dictionary
	current_region_id = String(values.get("current_region_id", "cyber_city"))
	current_district_id = String(values.get("current_district_id", "rooftop_alley"))
	current_room_id = String(values.get("current_room_id", START_ROOM))
	spawn_connection_id = String(values.get("spawn_connection_id", "new_game"))
	last_safe_save_room_id = String(values.get("last_safe_save_room_id", ""))
	discovered_rooms = _truthy_keys(values.get("discovered_rooms", {}))
	discovered_save_rooms = _truthy_keys(values.get("discovered_save_rooms", {}))
	known_locked_barriers = _barrier_records(values.get("known_locked_barriers", {}))
	persistent_object_states = (values.get("persistent_object_states", {}) as Dictionary).duplicate(true)
	activated_warp_nodes = _truthy_keys(values.get("activated_warp_nodes", {}))
	defeated_bosses = _truthy_keys(values.get("defeated_bosses", {}))
	if current_room_id.is_empty():
		current_room_id = START_ROOM
	discovered_rooms[current_room_id] = true
	return true


func _truthy_keys(value: Variant) -> Dictionary:
	var result := {}
	if value is Dictionary:
		for key: Variant in value:
			if bool(value[key]):
				result[String(key)] = true
	return result


func _barrier_records(value: Variant) -> Dictionary:
	var result := {}
	if value is Dictionary:
		for key: Variant in value:
			var record: Variant = value[key]
			if record is Dictionary and not String((record as Dictionary).get("room_id", "")).is_empty() and not String((record as Dictionary).get("required_ability", "")).is_empty():
				result[String(key)] = (record as Dictionary).duplicate(true)
	return result
