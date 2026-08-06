extends SceneTree

const TITLE_SCENE := preload("res://scenes/ui/TitleScreen.tscn")
const WORLD_SCENE := preload("res://scenes/world/WorldRoot.tscn")
const DESIGN_SIZE := Vector2i(960, 540)
const CAPTURE_SIZES: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3440, 1440),
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var output_directory := OS.get_environment("CCP_DISPLAY_CAPTURE_DIR")
	if output_directory.is_empty():
		push_error("Display matrix capture requires CCP_DISPLAY_CAPTURE_DIR.")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(output_directory) != OK:
		push_error("Display matrix capture could not create %s." % output_directory)
		quit(1)
		return
	root.content_scale_size = DESIGN_SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var game := root.get_node("GameManager")
	var dialogue := root.get_node("DialogueController")
	var world_manager := root.get_node("WorldManager")
	# Let autoloads finish applying the isolated default settings before the capture
	# driver takes ownership of the viewport size.
	await _settle(4)
	for capture_size: Vector2i in CAPTURE_SIZES:
		if not String(dialogue.get("active_entry_id")).is_empty():
			dialogue.call(&"cancel_current")
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(capture_size)
		root.size = capture_size
		await _settle(4)
		var suffix := "%dx%d" % [capture_size.x, capture_size.y]
		var title := TITLE_SCENE.instantiate() as Control
		root.add_child(title)
		await _settle(4)
		if not _save_capture(output_directory.path_join("title-%s.png" % suffix), capture_size):
			return
		title.free()
		await process_frame

		game.call(&"new_game")
		var world := WORLD_SCENE.instantiate() as Node2D
		root.add_child(world)
		await _settle(12)
		if not String(dialogue.get("active_entry_id")).is_empty():
			dialogue.call(&"cancel_current")
			await _settle(2)
		if not _save_capture(output_directory.path_join("world-%s.png" % suffix), capture_size):
			return
		var pause_menu := world.get_node("PauseMenu") as PauseMenu
		pause_menu.pause(0)
		await _settle(4)
		if not _save_capture(output_directory.path_join("pause-map-%s.png" % suffix), capture_size):
			return
		pause_menu.resume()
		world_manager.room_loader.current_room = null
		world_manager.room_loader.configure(null)
		world_manager.world_root = null
		world_manager.player = null
		world_manager.current_room_id = ""
		world.free()
		await _settle(3)
	print("DISPLAY_MATRIX_CAPTURE_OK sizes=", CAPTURE_SIZES.size(), " surfaces=3 output=", output_directory)
	quit()


func _settle(frame_count: int) -> void:
	for _frame: int in range(frame_count):
		await process_frame
	await RenderingServer.frame_post_draw


func _save_capture(destination: String, expected_size: Vector2i) -> bool:
	var capture := root.get_texture().get_image()
	if capture == null or capture.is_empty():
		push_error("Display matrix capture produced no image for %s." % destination)
		quit(1)
		return false
	if capture.get_size() != expected_size:
		push_error("Display matrix capture size mismatch for %s: expected %s, got %s." % [destination, expected_size, capture.get_size()])
		quit(1)
		return false
	if capture.save_png(destination) != OK:
		push_error("Display matrix capture could not write %s." % destination)
		quit(1)
		return false
	return true
