class_name RoomLoader
extends Node

const ROOM_SCENE := preload("res://scenes/world/WorldRoom.tscn")

signal room_load_started(room_id: String)
signal room_loaded(room: WorldRoom)
signal room_load_failed(room_id: String, reason: String)

var current_room: WorldRoom
var last_load_duration_usec := 0
var peak_load_duration_usec := 0
var successful_load_count := 0
var _container: Node2D


func configure(container: Node2D) -> void:
	_container = container


func load_room(room_id: String) -> WorldRoom:
	var started_usec := Time.get_ticks_usec()
	if _container == null:
		room_load_failed.emit(room_id, "Room container is not configured.")
		return null
	var definition := WorldDatabase.room(room_id)
	if definition.is_empty():
		room_load_failed.emit(room_id, "Room definition is missing.")
		return null
	room_load_started.emit(room_id)
	var previous := current_room
	if previous != null:
		previous.process_mode = Node.PROCESS_MODE_DISABLED
	var next_room := ROOM_SCENE.instantiate() as WorldRoom
	next_room.definition = definition
	_container.add_child(next_room)
	current_room = next_room
	last_load_duration_usec = Time.get_ticks_usec() - started_usec
	peak_load_duration_usec = maxi(peak_load_duration_usec, last_load_duration_usec)
	successful_load_count += 1
	if previous != null:
		previous.queue_free()
	room_loaded.emit(current_room)
	return current_room
