extends SceneTree

const ROOM_SCENE := preload("res://scenes/world/WorldRoom.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var output_directory := OS.get_environment("CCP_ART_CAPTURE_DIR")
	if output_directory.is_empty():
		push_error("District art capture requires CCP_ART_CAPTURE_DIR.")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(output_directory) != OK:
		push_error("District art capture could not create %s." % output_directory)
		quit(1)
		return
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var representatives := _representative_rooms()
	var requested_rooms := OS.get_environment("CCP_ART_CAPTURE_ROOMS")
	if not requested_rooms.is_empty():
		representatives.clear()
		for room_id: String in requested_rooms.split(",", false):
			var normalized := room_id.strip_edges()
			if not WorldDatabase.room(normalized).is_empty():
				representatives[normalized] = normalized
	var district_ids := PackedStringArray(representatives.keys())
	district_ids.sort()
	var requested := OS.get_environment("CCP_ART_CAPTURE_DISTRICTS")
	if not requested.is_empty():
		var selected := PackedStringArray()
		for district_id: String in requested.split(",", false):
			var normalized := district_id.strip_edges()
			if representatives.has(normalized):
				selected.append(normalized)
		district_ids = selected
	for district_id: String in district_ids:
		var room_id := String(representatives[district_id])
		print("DISTRICT_ART_CAPTURE_BUILD district=", district_id, " room=", room_id)
		var room := ROOM_SCENE.instantiate() as WorldRoom
		room.definition = WorldDatabase.room(room_id)
		root.add_child(room)
		print("DISTRICT_ART_CAPTURE_BUILT district=", district_id, " children=", room.get_child_count())
		for _frame: int in range(4):
			await process_frame
		print("DISTRICT_ART_CAPTURE_RENDER district=", district_id)
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image()
		if capture == null or capture.is_empty():
			push_error("District art capture produced no image for %s." % district_id)
			quit(1)
			return
		var destination := output_directory.path_join("%s.png" % district_id)
		if capture.save_png(destination) != OK:
			push_error("District art capture could not write %s." % destination)
			quit(1)
			return
		room.queue_free()
		await process_frame
	print("DISTRICT_ART_CAPTURE_OK districts=", district_ids.size(), " output=", output_directory)
	quit()


func _representative_rooms() -> Dictionary:
	var result := {}
	var fallback := {}
	for room_id: String in WorldDatabase.rooms():
		var definition := WorldDatabase.room(room_id)
		var district_id := String(definition.get("district_id", ""))
		if district_id.is_empty():
			continue
		if not fallback.has(district_id):
			fallback[district_id] = room_id
		if bool(definition.get("authored_expansion", false)) and not result.has(district_id):
			result[district_id] = room_id
	for district_id: String in fallback:
		if not result.has(district_id):
			result[district_id] = fallback[district_id]
	return result
