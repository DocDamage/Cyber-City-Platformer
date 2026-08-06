extends SceneTree

const ROOM_SCENE := preload("res://scenes/world/WorldRoom.tscn")
const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const PROBE_PATH := "res://data/world/traversal_probes.json"
const REQUIRED_TYPES := [
	"standard_jump",
	"wall_jump",
	"dash_gap",
	"teleport",
	"low_gravity",
	"moving_platform",
	"fall_recovery",
]

var _player_radius := 13.0
var _player_half_height := 27.0
var _player_shape_offset := Vector2(0.0, 2.0)
var _player_speed := 0.0
var _jump_velocity := 0.0
var _wall_jump_velocity := Vector2.ZERO
var _dash_speed := 0.0
var _dash_duration := 0.0
var _gravity := 0.0
var _probe_count := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(35.0, true, false, true).timeout.connect(func() -> void:
		_release_inputs()
		push_error("World traversal probe test timed out.")
		quit(1)
	)
	var manager := root.get_node("GameManager")
	manager.call(&"new_game")
	if not _read_production_player_parameters():
		return
	var document := _load_json(PROBE_PATH)
	var probes: Array = document.get("probes", [])
	if not _require(int(document.get("schema_version", 0)) == 1 and probes.size() == REQUIRED_TYPES.size(), "Traversal probe schema or probe count is invalid."):
		return
	var seen_ids: Dictionary = {}
	var seen_types: Dictionary = {}
	for probe_value: Variant in probes:
		if probe_value is not Dictionary:
			if not _require(false, "Traversal probe entry is not an object."):
				return
		var probe := probe_value as Dictionary
		var probe_id := String(probe.get("id", ""))
		var probe_type := String(probe.get("type", ""))
		if not _require(not probe_id.is_empty() and not seen_ids.has(probe_id), "Traversal probe id is missing or duplicated: %s" % probe_id):
			return
		if not _require(probe_type in REQUIRED_TYPES and not seen_types.has(probe_type), "Traversal probe type is missing, unsupported, or duplicated: %s" % probe_type):
			return
		seen_ids[probe_id] = true
		seen_types[probe_type] = true
		if not await _run_probe(probe):
			return
		_probe_count += 1
	for required_type: String in REQUIRED_TYPES:
		if not _require(seen_types.has(required_type), "Missing traversal probe type %s." % required_type):
			return
	_release_inputs()
	print("WORLD_TRAVERSAL_PROBE_TEST_OK probes=", _probe_count, " jump_apex=", snappedf(_maximum_rise(1.0), 0.1), " dash=", snappedf(_dash_speed * _dash_duration, 0.1), " teleport=420")
	quit()


func _read_production_player_parameters() -> bool:
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	if not _require(player != null, "Production player scene could not instantiate."):
		return false
	var collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not _require(collision != null and collision.shape is CapsuleShape2D, "Production player collision is not a capsule."):
		player.free()
		return false
	var capsule := collision.shape as CapsuleShape2D
	_player_radius = capsule.radius
	_player_half_height = capsule.height * 0.5
	_player_shape_offset = collision.position
	_player_speed = float(player.get("speed"))
	_jump_velocity = float(player.get("jump_velocity"))
	_wall_jump_velocity = player.get("wall_jump_velocity") as Vector2
	_dash_speed = float(player.get("dash_speed"))
	_dash_duration = float(player.get("dash_duration"))
	_gravity = float(player.get("gravity"))
	player.free()
	return _require(_player_speed > 0.0 and _jump_velocity < 0.0 and _wall_jump_velocity.y < 0.0 and _dash_speed > _player_speed and _gravity > 0.0, "Production movement parameters are invalid.")


func _run_probe(probe: Dictionary) -> bool:
	var room_id := String(probe.get("room_id", ""))
	var definition := WorldDatabase.room(StringName(room_id))
	if not _require(not definition.is_empty(), "Probe %s references missing room %s." % [probe.get("id", ""), room_id]):
		return false
	var room := ROOM_SCENE.instantiate() as WorldRoom
	room.definition = definition
	root.add_child(room)
	await process_frame
	if not _validate_runtime_platform_geometry(room, definition):
		room.queue_free()
		await process_frame
		return false
	var passed := false
	match String(probe.get("type", "")):
		"standard_jump": passed = await _probe_jump(room, definition, probe, 1.0, true)
		"wall_jump": passed = await _probe_wall_jump(room, definition, probe)
		"dash_gap": passed = await _probe_dash_gap(room, definition, probe)
		"teleport": passed = await _probe_teleport(room, definition, probe)
		"low_gravity": passed = await _probe_low_gravity(room, definition, probe)
		"moving_platform": passed = await _probe_moving_platform(room, definition, probe)
		"fall_recovery": passed = await _probe_fall_recovery(room, definition, probe)
	room.queue_free()
	await process_frame
	_release_inputs()
	return passed


func _probe_jump(room: WorldRoom, definition: Dictionary, probe: Dictionary, gravity_multiplier: float, near_limit: bool) -> bool:
	var source := _platform_rect(definition, int(probe.get("source_platform", -1)))
	var target := _platform_rect(definition, int(probe.get("target_platform", -1)))
	if not _require(source.has_area() and target.has_area(), "Jump probe references invalid platforms."):
		return false
	var rise := source.position.y - target.position.y
	var maximum_rise := _maximum_rise(gravity_multiplier)
	if not _require(rise > 0.0 and rise <= maximum_rise, "Jump rise %.1f exceeds the production %.1f maximum." % [rise, maximum_rise]):
		return false
	if near_limit and not _require(rise >= maximum_rise * float(probe.get("minimum_apex_ratio", 0.8)), "Standard jump probe is not close enough to the production limit."):
		return false
	var direction := signf(float(probe.get("direction", 1)))
	var player := await _spawn_player(room, Vector2(source.get_center().x - direction * source.size.x * 0.12, _standing_y(source.position.y)))
	if not _require(player.is_on_floor(), "Jump probe player did not settle on its authored source platform."):
		return false
	_press_direction(direction)
	for _frame: int in range(int(probe.get("runup_frames", 10))):
		await physics_frame
	player.call(&"request_jump")
	var left_floor := false
	var landed := false
	var apex_y := player.global_position.y
	for _frame: int in range(110):
		await physics_frame
		apex_y = minf(apex_y, player.global_position.y)
		if not player.is_on_floor():
			left_floor = true
		if direction > 0.0 and player.global_position.x >= target.get_center().x or direction < 0.0 and player.global_position.x <= target.get_center().x:
			_release_inputs()
		if left_floor and player.is_on_floor():
			landed = _body_overlaps_platform(player, target)
			break
	_release_inputs()
	return _require(landed and source.position.y - (apex_y + _player_half_height + _player_shape_offset.y) >= rise - 3.0, "Production player did not complete authored jump from %s to %s (position=%s)." % [source, target, player.global_position])


func _probe_wall_jump(room: WorldRoom, definition: Dictionary, probe: Dictionary) -> bool:
	var left_wall := _platform_rect(definition, int(probe.get("left_wall", -1)))
	var right_wall := _platform_rect(definition, int(probe.get("right_wall", -1)))
	var inner_gap := right_wall.position.x - left_wall.end.x
	var route_height := minf(left_wall.size.y, right_wall.size.y)
	if not _require(left_wall.size.x <= 24.0 and right_wall.size.x <= 24.0 and route_height >= float(probe.get("minimum_route_height", 0.0)), "Wall-jump probe does not reference a production chimney."):
		return false
	var center_crossing := inner_gap - _player_radius * 2.0
	var crossing_time := center_crossing / _wall_jump_velocity.x
	var vertical_gain := -(_wall_jump_velocity.y * crossing_time + 0.5 * _gravity * crossing_time * crossing_time)
	if not _require(center_crossing > 0.0 and vertical_gain >= 25.0 and ceili(route_height / vertical_gain) <= 9, "Wall-jump chimney exceeds production crossing or ascent parameters."):
		return false
	var player := await _spawn_player(room, Vector2(left_wall.end.x + _player_radius + 0.5, left_wall.end.y - 95.0))
	player.velocity = Vector2(-80.0, 90.0)
	Input.action_press(&"ui_left")
	var touched_left := false
	for _frame: int in range(12):
		await physics_frame
		if player.is_on_wall():
			touched_left = true
			break
	if not _require(touched_left, "Production player could not contact the authored wall-jump surface (position=%s floor=%s collisions=%d state=%s)." % [player.global_position, player.is_on_floor(), player.get_slide_collision_count(), player.call(&"get_state_name")]):
		_release_inputs()
		return false
	var start_y := player.global_position.y
	player.call(&"request_jump")
	Input.action_release(&"ui_left")
	Input.action_press(&"ui_right")
	var touched_right := false
	var apex_y := start_y
	for _frame: int in range(50):
		await physics_frame
		apex_y = minf(apex_y, player.global_position.y)
		if player.is_on_wall() and player.global_position.x > (left_wall.end.x + right_wall.position.x) * 0.5:
			touched_right = true
			break
	_release_inputs()
	return _require(touched_right and start_y - apex_y >= 25.0, "Production wall jump did not cross the authored chimney with useful vertical gain.")


func _probe_dash_gap(room: WorldRoom, definition: Dictionary, probe: Dictionary) -> bool:
	var source := _platform_rect(definition, int(probe.get("source_platform", -1)))
	var target := _platform_rect(definition, int(probe.get("target_platform", -1)))
	var gap := target.position.x - source.end.x
	var maximum_seconds := float(probe.get("maximum_cross_seconds", 0.55))
	var dash_only := _dash_speed * _dash_duration
	var bounded_followthrough := maxf(maximum_seconds - _dash_duration, 0.0) * _player_speed
	if not _require(gap > dash_only and gap + _player_radius * 2.0 <= dash_only + bounded_followthrough + _player_radius * 2.0, "Dash probe is not a meaningful bounded follow-through gap."):
		return false
	var player := await _spawn_player(room, Vector2(source.end.x - _player_radius - 1.0, _standing_y(source.position.y)))
	player.set("is_invincible", true)
	player.set("facing_direction", 1.0)
	var started_at := Time.get_ticks_msec()
	if not _require(bool(player.call(&"_start_dash")), "Production dash could not start for the authored gap."):
		return false
	var landed := false
	for _frame: int in range(50):
		await physics_frame
		if player.is_on_floor() and _body_overlaps_platform(player, target):
			landed = true
			break
	var elapsed := float(Time.get_ticks_msec() - started_at) / 1000.0
	return _require(landed and elapsed <= maximum_seconds + 0.12, "Production dash did not recover onto the authored target within its timing bound (elapsed=%.3f)." % elapsed)


func _probe_teleport(room: WorldRoom, definition: Dictionary, probe: Dictionary) -> bool:
	var source := _platform_rect(definition, int(probe.get("source_platform", -1)))
	var target := _platform_rect(definition, int(probe.get("target_platform", -1)))
	var beyond := _platform_rect(definition, int(probe.get("beyond_range_platform", -1)))
	var player := await _spawn_player(room, Vector2(source.end.x - _player_radius - 4.0, _standing_y(source.position.y)))
	var teleport: TeleportController = player.get_node("TeleportController") as TeleportController
	var anchor := Vector2(target.get_center().x, target.position.y)
	var launch := player.global_position + Vector2(0.0, -12.0)
	var result := teleport.resolver.resolve(anchor, Vector2.UP)
	if not _require(launch.distance_to(anchor) <= teleport.maximum_range and bool(result.get("valid", false)), "Authored teleport target is out of range or lacks full-body clearance: %s" % result):
		return false
	var beyond_anchor := Vector2(beyond.position.x, beyond.position.y)
	if not _require(launch.distance_to(beyond_anchor) > teleport.maximum_range, "Teleport range checkpoint does not distinguish an unreachable surface."):
		return false
	var destination := Vector2(result.get("position", Vector2.ZERO))
	if not _require(bool(player.call(&"teleport_to_destination", destination)), "Production player rejected the validated authored teleport destination."):
		return false
	var arrived_exactly := player.global_position.distance_to(destination) < 0.1
	await physics_frame
	return _require(arrived_exactly and player.global_position.distance_to(destination) < 4.0, "Production teleport did not end at the clearance-validated checkpoint.")


func _probe_low_gravity(room: WorldRoom, definition: Dictionary, probe: Dictionary) -> bool:
	var source := _platform_rect(definition, int(probe.get("source_platform", -1)))
	var target := _platform_rect(definition, int(probe.get("target_platform", -1)))
	var rise := source.position.y - target.position.y
	var multiplier := float(probe.get("gravity_multiplier", 1.0))
	if not _require(rise > _maximum_rise(1.0) and rise <= _maximum_rise(multiplier), "Low-gravity probe does not require the authored gravity field."):
		return false
	var passed := await _probe_jump(room, definition, probe, multiplier, false)
	if not passed:
		return false
	for child: Node in room.get_children():
		if child is GravityZone and is_equal_approx((child as GravityZone).gravity_multiplier, multiplier):
			return true
	return _require(false, "Low-gravity room did not instantiate its authored GravityZone.")


func _probe_moving_platform(room: WorldRoom, definition: Dictionary, probe: Dictionary) -> bool:
	var moving_platforms: Array[MovingPlatform] = []
	for child: Node in room.get_children():
		if child is MovingPlatform:
			moving_platforms.append(child as MovingPlatform)
	var index := int(probe.get("moving_platform", -1))
	var records: Array = definition.get("moving_platforms", [])
	if not _require(index >= 0 and index < moving_platforms.size() and index < records.size(), "Moving-platform probe index is invalid."):
		return false
	var platform := moving_platforms[index]
	var record := records[index] as Dictionary
	var route := platform.get_route_points()
	var expected_size := _vector(record.get("size", [0, 0]))
	var collision := platform.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not _require(route.size() >= 2 and collision != null and collision.shape is RectangleShape2D and (collision.shape as RectangleShape2D).size.is_equal_approx(expected_size), "Moving platform did not build its authored collision and route."):
		return false
	var endpoint := _vector(record.get("position", [0, 0])) + route[1]
	var theoretical_seconds := route[0].distance_to(route[1]) / platform.speed
	var maximum_seconds := float(probe.get("maximum_leg_seconds", 0.0))
	if not _require(theoretical_seconds <= maximum_seconds, "Moving-platform route exceeds its authored timing bound."):
		return false
	var started_at := Time.get_ticks_msec()
	while platform.position.distance_to(endpoint) > 1.5 and float(Time.get_ticks_msec() - started_at) / 1000.0 <= maximum_seconds:
		await physics_frame
	var elapsed := float(Time.get_ticks_msec() - started_at) / 1000.0
	return _require(platform.position.distance_to(endpoint) <= 1.5 and elapsed <= maximum_seconds, "Moving platform missed its runtime endpoint timing bound (elapsed=%.3f)." % elapsed)


func _probe_fall_recovery(room: WorldRoom, definition: Dictionary, probe: Dictionary) -> bool:
	var start := _vector(probe.get("fall_start", [0, 0]))
	var connection_id := String(probe.get("recovery_connection", ""))
	var connection: Dictionary = {}
	for value: Variant in definition.get("connections", []):
		if String((value as Dictionary).get("id", "")) == connection_id:
			connection = value as Dictionary
			break
	if not _require(not connection.is_empty() and not WorldDatabase.room(String(connection.get("target_room", ""))).is_empty(), "Fall-recovery probe has no valid authored recovery connection."):
		return false
	var target_definition := WorldDatabase.room(StringName(connection.get("target_room", "")))
	if not _require((target_definition.get("spawns", {}) as Dictionary).has(String(connection.get("target_connection", ""))), "Fall-recovery connection has no stable target spawn."):
		return false
	var player := await _spawn_player(room, start, false)
	var started_at := Time.get_ticks_msec()
	var recovered := false
	var maximum_seconds := float(probe.get("maximum_recovery_seconds", 2.0))
	while float(Time.get_ticks_msec() - started_at) / 1000.0 <= maximum_seconds:
		await physics_frame
		if player.is_on_floor():
			recovered = true
			break
	return _require(recovered and not bool(player.get("is_dead")) and player.global_position.y > start.y + 200.0, "Required-route fall did not recover on production collision geometry.")


func _spawn_player(room: WorldRoom, position: Vector2, settle := true) -> CharacterBody2D:
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	room.add_child(player)
	await process_frame
	# The production manager restores its active checkpoint during Player._ready().
	# Place the probe body only after that registration path has completed.
	player.global_position = position
	player.velocity = Vector2.ZERO
	if settle:
		for _frame: int in range(12):
			await physics_frame
			if player.is_on_floor():
				break
	return player


func _validate_runtime_platform_geometry(room: WorldRoom, definition: Dictionary) -> bool:
	var runtime_rects: Array[Rect2] = []
	for child: Node in room.get_children():
		if child is not StaticBody2D or child is AnimatableBody2D:
			continue
		var collision: CollisionShape2D
		for body_child: Node in child.get_children():
			if body_child is CollisionShape2D:
				collision = body_child as CollisionShape2D
				break
		if collision == null or collision.shape is not RectangleShape2D:
			continue
		var size := (collision.shape as RectangleShape2D).size
		runtime_rects.append(Rect2((child as Node2D).position + collision.position - size * 0.5, size))
	var authored: Array = definition.get("platforms", [])
	if not _require(runtime_rects.size() == authored.size(), "Room %s did not instantiate every authored static collision platform (runtime=%d authored=%d)." % [definition.get("id", ""), runtime_rects.size(), authored.size()]):
		return false
	for value: Variant in authored:
		var expected := _rect(value)
		var found := false
		for actual: Rect2 in runtime_rects:
			if actual.position.distance_to(expected.position) < 0.1 and actual.size.distance_to(expected.size) < 0.1:
				found = true
				break
		if not _require(found, "Room %s is missing runtime collision %s." % [definition.get("id", ""), expected]):
			return false
	return true


func _platform_rect(definition: Dictionary, index: int) -> Rect2:
	var platforms: Array = definition.get("platforms", [])
	return _rect(platforms[index]) if index >= 0 and index < platforms.size() else Rect2()


func _rect(value: Variant) -> Rect2:
	if value is not Array or (value as Array).size() != 4:
		return Rect2()
	var values := value as Array
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))


func _vector(value: Variant) -> Vector2:
	if value is Vector2:
		return value as Vector2
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float((value as Array)[0]), float((value as Array)[1]))
	return Vector2.ZERO


func _standing_y(surface_y: float) -> float:
	return surface_y - _player_half_height - _player_shape_offset.y


func _maximum_rise(gravity_multiplier: float) -> float:
	return _jump_velocity * _jump_velocity / (2.0 * _gravity * gravity_multiplier)


func _body_overlaps_platform(player: CharacterBody2D, platform: Rect2) -> bool:
	return player.global_position.x + _player_radius >= platform.position.x - 1.0 and player.global_position.x - _player_radius <= platform.end.x + 1.0 and absf(player.global_position.y - _standing_y(platform.position.y)) <= 8.0


func _press_direction(direction: float) -> void:
	_release_inputs()
	Input.action_press(&"ui_right" if direction > 0.0 else &"ui_left")


func _release_inputs() -> void:
	Input.action_release(&"ui_left")
	Input.action_release(&"ui_right")
	Input.action_release(&"ui_accept")
	Input.action_release(&"slide_dash")


func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_release_inputs()
	push_error(message)
	quit(1)
	return false
