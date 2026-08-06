class_name WorldMapView
extends Control

signal room_selected(room_id: String)

const CELL_SIZE := Vector2(34, 26)
const REGION_COLORS := {
	"cyber_city": Color("27e8ff"),
	"robot_factory": Color("ff9b42"),
	"neon_moon": Color("a879ff"),
	"abyssal_night": Color("ff4f88"),
}

var zoom := 1.0
var pan := Vector2.ZERO
var selected_room_id := ""
var _dragging := false
var _drag_origin := Vector2.ZERO
var _pan_origin := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(620, 350)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	var game := get_node_or_null("/root/GameManager")
	if game != null:
		selected_room_id = game.world_progress.current_room_id
		game.world_progress_changed.connect(func(_room_id: String) -> void:
			selected_room_id = game.world_progress.current_room_id
			queue_redraw()
		)


func center_current() -> void:
	pan = Vector2.ZERO
	queue_redraw()


func set_zoom(value: float) -> void:
	zoom = clampf(value, 0.65, 2.25)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			set_zoom(zoom + 0.1)
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			set_zoom(zoom - 0.1)
		elif mouse.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mouse.pressed
			_drag_origin = mouse.position
			_pan_origin = pan
			if mouse.pressed:
				_select_at(mouse.position)
	elif event is InputEventMouseMotion and _dragging:
		pan = _pan_origin + (event as InputEventMouseMotion).position - _drag_origin
		queue_redraw()
	elif event.is_action_pressed(&"ui_left"):
		pan.x += 30
		queue_redraw()
	elif event.is_action_pressed(&"ui_right"):
		pan.x -= 30
		queue_redraw()
	elif event.is_action_pressed(&"ui_up"):
		pan.y += 24
		queue_redraw()
	elif event.is_action_pressed(&"ui_down"):
		pan.y -= 24
		queue_redraw()
	elif event.is_action_pressed(&"teleport"):
		set_zoom(zoom + 0.1)
	elif event.is_action_pressed(&"teleport_cancel"):
		set_zoom(zoom - 0.1)


func _draw() -> void:
	var game := get_node_or_null("/root/GameManager")
	if game == null:
		return
	var rooms := WorldDatabase.rooms()
	var discovered: Dictionary = game.world_progress.discovered_rooms
	var origin := size * 0.5 + pan + Vector2(-9.0 * CELL_SIZE.x, 0.5 * CELL_SIZE.y) * zoom
	for room_id: String in rooms:
		if not discovered.has(room_id):
			continue
		var room: Dictionary = rooms[room_id]
		var start := _cell_center(room, origin)
		for connection_value: Variant in room.get("connections", []):
			var connection := connection_value as Dictionary
			if bool(connection.get("map_hidden", false)):
				continue
			var target_id := String(connection.get("target_room", ""))
			if discovered.has(target_id) and rooms.has(target_id):
				draw_line(start, _cell_center(rooms[target_id], origin), Color(0.45, 0.58, 0.72, 0.75), maxf(2.0 * zoom, 1.0))
	for room_id: String in rooms:
		if not discovered.has(room_id):
			continue
		var room: Dictionary = rooms[room_id]
		var center := _cell_center(room, origin)
		var cell_rect := Rect2(center - CELL_SIZE * zoom * 0.42, CELL_SIZE * zoom * 0.84)
		var color: Color = REGION_COLORS.get(String(room.get("region_id", "")), Color.WHITE)
		draw_rect(cell_rect, color.darkened(0.62), true)
		draw_rect(cell_rect, Color.WHITE if room_id == selected_room_id else color, false, 3.0 if room_id == selected_room_id else 1.5)
		if room.has("save_room"):
			draw_circle(center + Vector2(-7, 0) * zoom, 3.2 * zoom, Color("58f0b4"))
		if room.has("warp_room"):
			var warp_id := String((room.warp_room as Dictionary).get("id", ""))
			if game.world_progress.activated_warp_nodes.has(warp_id):
				draw_circle(center + Vector2(7, 0) * zoom, 4.2 * zoom, Color("ffe66b"), false, 2.0)
		_draw_services(room, center)
		if _room_has_known_lock(game, room_id):
			var lock_center := center + Vector2(0, -7) * zoom
			draw_line(lock_center + Vector2(-3, -3) * zoom, lock_center + Vector2(3, 3) * zoom, Color("ffcf5c"), maxf(1.5 * zoom, 1.0))
			draw_line(lock_center + Vector2(3, -3) * zoom, lock_center + Vector2(-3, 3) * zoom, Color("ffcf5c"), maxf(1.5 * zoom, 1.0))
	var objective_room := objective_room_id(game)
	if rooms.has(objective_room):
		var objective_center := _cell_center(rooms[objective_room], origin)
		var objective_size := 9.0 * zoom
		draw_colored_polygon(PackedVector2Array([objective_center + Vector2(0,-objective_size),objective_center + Vector2(objective_size,0),objective_center + Vector2(0,objective_size),objective_center + Vector2(-objective_size,0)]), Color("ffe66b"))
		draw_circle(objective_center, 3.0 * zoom, Color("080d20"))
	if rooms.has(game.world_progress.current_room_id):
		var player_center := _cell_center(rooms[game.world_progress.current_room_id], origin)
		draw_colored_polygon(PackedVector2Array([player_center + Vector2(0,-12), player_center + Vector2(8,-3), player_center + Vector2(-8,-3)]), Color.WHITE)
	_draw_legend()
	_draw_completion(game, rooms)


func _draw_legend() -> void:
	var y := 18.0
	for region_id: String in REGION_COLORS:
		draw_rect(Rect2(14, y, 12, 12), REGION_COLORS[region_id], true)
		draw_string(ThemeDB.fallback_font, Vector2(32, y + 11), WorldDatabase.region_display_name(region_id), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85,0.9,1))
		y += 19
	draw_circle(Vector2(20, y + 7), 4, Color("58f0b4"))
	draw_string(ThemeDB.fallback_font, Vector2(32, y + 11), "Save", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85,0.9,1))
	draw_circle(Vector2(88, y + 7), 5, Color("ffe66b"), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(99, y + 11), "Warp", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85,0.9,1))
	draw_line(Vector2(154, y + 3), Vector2(162, y + 11), Color("ffcf5c"), 2)
	draw_line(Vector2(162, y + 3), Vector2(154, y + 11), Color("ffcf5c"), 2)
	draw_string(ThemeDB.fallback_font, Vector2(168, y + 11), "Locked route", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85,0.9,1))
	y += 20
	draw_circle(Vector2(20, y + 7), 4, Color("ff75c8"))
	draw_string(ThemeDB.fallback_font, Vector2(32, y + 11), "Service", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85,0.9,1))
	var objective_center := Vector2(108, y + 7)
	draw_colored_polygon(PackedVector2Array([objective_center + Vector2(0,-6),objective_center + Vector2(6,0),objective_center + Vector2(0,6),objective_center + Vector2(-6,0)]), Color("ffe66b"))
	draw_string(ThemeDB.fallback_font, Vector2(120, y + 11), "Objective", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85,0.9,1))


func _draw_services(room: Dictionary, center: Vector2) -> void:
	var services := room.get("services", []) as Array
	for index: int in range(services.size()):
		var service := services[index] as Dictionary
		var service_type := String(service.get("type", "npc"))
		var colors := {"barber":Color("ff75c8"),"tailor":Color("a879ff"),"npc":Color("65ffb8"),"shop":Color("ffe66b")}
		var offset := Vector2((float(index) - float(services.size() - 1) * 0.5) * 7.0, 7.0) * zoom
		draw_circle(center + offset, 2.7 * zoom, colors.get(service_type, Color("ff75c8")))


func _draw_completion(game: Node, rooms: Dictionary) -> void:
	var percentages := completion_percentages(game, rooms)
	var x := maxf(size.x - 188.0, 390.0)
	var y := 20.0
	draw_string(ThemeDB.fallback_font, Vector2(x, y), "MAP COMPLETION  %d%%" % int(percentages.get("overall", 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffe66b"))
	y += 19
	for region_id: String in REGION_COLORS:
		draw_string(ThemeDB.fallback_font, Vector2(x, y), "%s  %d%%" % [WorldDatabase.region_display_name(region_id), int(percentages.get(region_id, 0))], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, REGION_COLORS[region_id].lightened(0.18))
		y += 18


func objective_room_id(game: Node) -> String:
	if game == null or not game.has_method(&"current_quest_objective"):
		return ""
	var objective := game.call(&"current_quest_objective") as Dictionary
	return String(objective.get("target_room_id", ""))


func completion_percentages(game: Node, rooms_value: Dictionary = {}) -> Dictionary:
	var rooms := rooms_value if not rooms_value.is_empty() else WorldDatabase.rooms()
	var totals: Dictionary = {}
	var discovered: Dictionary = {}
	for region_id: String in REGION_COLORS:
		totals[region_id] = 0
		discovered[region_id] = 0
	var discovered_rooms: Dictionary = game.world_progress.discovered_rooms if game != null else {}
	var discovered_total := 0
	for room_id: String in rooms:
		var region_id := String((rooms[room_id] as Dictionary).get("region_id", ""))
		if not totals.has(region_id):
			continue
		totals[region_id] = int(totals[region_id]) + 1
		if discovered_rooms.has(room_id):
			discovered[region_id] = int(discovered[region_id]) + 1
			discovered_total += 1
	var result: Dictionary = {"overall": roundi(100.0 * float(discovered_total) / maxf(float(rooms.size()), 1.0))}
	for region_id: String in REGION_COLORS:
		result[region_id] = roundi(100.0 * float(discovered[region_id]) / maxf(float(totals[region_id]), 1.0))
	return result


func _room_has_known_lock(game: Node, room_id: String) -> bool:
	for record_value: Variant in game.world_progress.known_locked_barriers.values():
		if record_value is not Dictionary:
			continue
		var record := record_value as Dictionary
		var required := StringName(record.get("required_ability", ""))
		if String(record.get("room_id", "")) == room_id and not game.abilities.has(required):
			return true
	return false


func _select_at(local_position: Vector2) -> void:
	var game := get_node_or_null("/root/GameManager")
	if game == null:
		return
	var rooms := WorldDatabase.rooms()
	var origin := size * 0.5 + pan + Vector2(-9.0 * CELL_SIZE.x, 0.5 * CELL_SIZE.y) * zoom
	for room_id: String in game.world_progress.discovered_rooms:
		if rooms.has(room_id) and local_position.distance_to(_cell_center(rooms[room_id], origin)) <= CELL_SIZE.length() * zoom * 0.45:
			selected_room_id = room_id
			room_selected.emit(room_id)
			queue_redraw()
			return


func _cell_center(room: Dictionary, origin: Vector2) -> Vector2:
	var values: Array = room.get("map_cell", [0, 0])
	return origin + Vector2(float(values[0]) * CELL_SIZE.x, float(values[1]) * CELL_SIZE.y) * zoom
