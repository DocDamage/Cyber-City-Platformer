extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var displays: Array[Dictionary] = []
	for screen_id: int in range(DisplayServer.get_screen_count()):
		displays.append({
			"id": screen_id,
			"position": _vector_to_array(DisplayServer.screen_get_position(screen_id)),
			"size": _vector_to_array(DisplayServer.screen_get_size(screen_id)),
			"usable_rect": _rect_to_array(DisplayServer.screen_get_usable_rect(screen_id)),
			"refresh_rate": DisplayServer.screen_get_refresh_rate(screen_id),
		})
	var controllers: Array[Dictionary] = []
	for device_id: int in Input.get_connected_joypads():
		controllers.append({
			"id": device_id,
			"name": Input.get_joy_name(device_id),
			"guid": Input.get_joy_guid(device_id),
			"info": Input.get_joy_info(device_id),
		})
	var report := {
		"display_server": DisplayServer.get_name(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"displays": displays,
		"controllers": controllers,
	}
	print("HARDWARE_DISPLAY_PROBE_OK ", JSON.stringify(report))
	quit()


func _vector_to_array(value: Vector2i) -> Array[int]:
	return [value.x, value.y]


func _rect_to_array(value: Rect2i) -> Array[int]:
	return [value.position.x, value.position.y, value.size.x, value.size.y]
