class_name WorldDatabase
extends RefCounted

const MANIFEST_PATH := "res://data/world/world_manifest.json"

static var _manifest: Dictionary = {}
static var _rooms: Dictionary = {}
static var _room_sources: Dictionary = {}
static var _duplicate_room_sources: Dictionary = {}


static func manifest() -> Dictionary:
	_ensure_loaded()
	return _manifest


static func room(room_id: String) -> Dictionary:
	_ensure_loaded()
	return (_rooms.get(room_id, {}) as Dictionary).duplicate(true)


static func rooms() -> Dictionary:
	_ensure_loaded()
	return _rooms.duplicate(true)


static func room_count() -> int:
	_ensure_loaded()
	return _rooms.size()


static func start_room_id() -> String:
	return String(manifest().get("start_room_id", WorldProgress.START_ROOM))


static func fast_travel_node(node_id: String) -> Dictionary:
	for entry: Variant in manifest().get("fast_travel_nodes", []):
		if entry is Dictionary and String((entry as Dictionary).get("id", "")) == node_id:
			return (entry as Dictionary).duplicate(true)
	return {}


static func fast_travel_node_available(node_id: String, story_flags: Dictionary) -> bool:
	var node := fast_travel_node(node_id)
	if node.is_empty():
		return false
	for flag_value: Variant in node.get("required_story_flags", []):
		var flag_id := String(flag_value)
		if flag_id.is_empty() or not bool(story_flags.get(flag_id, false)):
			return false
	return true


static func region_display_name(region_id: String) -> String:
	for value: Variant in manifest().get("regions", []):
		if value is Dictionary and String((value as Dictionary).get("id", "")) == region_id:
			return String((value as Dictionary).get("display_name", region_id.capitalize()))
	return region_id.capitalize()


static func district_display_name(district_id: String) -> String:
	for value: Variant in manifest().get("districts", []):
		if value is Dictionary and String((value as Dictionary).get("id", "")) == district_id:
			return String((value as Dictionary).get("display_name", district_id.capitalize()))
	return district_id.capitalize()


static func rooms_in_region(region_id: String) -> Array[String]:
	_ensure_loaded()
	var result: Array[String] = []
	for room_id: String in _rooms:
		if String((_rooms[room_id] as Dictionary).get("region_id", "")) == region_id:
			result.append(room_id)
	return result


static func fast_travel_nodes() -> Array:
	return (manifest().get("fast_travel_nodes", []) as Array).duplicate(true)


static func validate() -> PackedStringArray:
	_ensure_loaded()
	var errors := PackedStringArray()
	for room_id: String in _duplicate_room_sources:
		errors.append("Room id %s is defined more than once: %s." % [room_id, ", ".join(_duplicate_room_sources[room_id] as Array)])
	if _rooms.is_empty():
		errors.append("World has no rooms.")
		return errors
	var region_ids: Dictionary = {}
	for region_value: Variant in _manifest.get("regions", []):
		if region_value is not Dictionary:
			errors.append("World manifest contains an invalid region record.")
			continue
		var region := region_value as Dictionary
		var region_id := String(region.get("id", ""))
		if region_id.is_empty() or region_ids.has(region_id):
			errors.append("World manifest contains a missing or duplicate region id: %s." % region_id)
		region_ids[region_id] = true
	var district_ids: Dictionary = {}
	var district_regions: Dictionary = {}
	for district_value: Variant in _manifest.get("districts", []):
		if district_value is not Dictionary:
			errors.append("World manifest contains an invalid district record.")
			continue
		var district := district_value as Dictionary
		var district_id := String(district.get("id", ""))
		var region_id := String(district.get("region_id", ""))
		if district_id.is_empty() or district_ids.has(district_id):
			errors.append("World manifest contains a missing or duplicate district id: %s." % district_id)
		if not region_ids.has(region_id):
			errors.append("District %s references unknown region %s." % [district_id, region_id])
		district_ids[district_id] = true
		district_regions[district_id] = region_id
	errors.append_array(DistrictArtCatalog.validate(district_regions))

	var map_cells: Dictionary = {}
	var district_room_counts: Dictionary = {}
	var district_critical_counts: Dictionary = {}
	var district_optional_counts: Dictionary = {}
	var district_first_pass: Dictionary = {}
	var district_story_counts: Dictionary = {}
	var critical_path_rooms: Dictionary = {}
	var critical_room_total := 0
	var persistent_cache_ids: Dictionary = {}
	var authored_layout_ids: Dictionary = {}
	var authored_platform_signatures: Dictionary = {}
	var authored_layout_count := 0
	for room_id: String in _rooms:
		var definition: Dictionary = _rooms[room_id]
		var region_id := String(definition.get("region_id", ""))
		var district_id := String(definition.get("district_id", ""))
		if room_id.is_empty() or region_id.is_empty() or district_id.is_empty() or String(definition.get("display_name", "")).is_empty():
			errors.append("Room %s is missing identity fields." % room_id)
		if not region_ids.has(region_id):
			errors.append("Room %s references unknown region %s." % [room_id, region_id])
		if not district_ids.has(district_id):
			errors.append("Room %s references unknown district %s." % [room_id, district_id])
		district_room_counts[district_id] = int(district_room_counts.get(district_id, 0)) + 1
		var pacing: Dictionary = definition.get("pacing", {})
		if int(pacing.get("first_pass_seconds", 0)) <= 0 or int(pacing.get("expert_seconds", 0)) <= 0:
			errors.append("Room %s is missing positive pacing values." % room_id)
		if bool(pacing.get("optional", false)):
			district_optional_counts[district_id] = int(district_optional_counts.get(district_id, 0)) + 1
		else:
			district_critical_counts[district_id] = int(district_critical_counts.get(district_id, 0)) + 1
			district_first_pass[district_id] = int(district_first_pass.get(district_id, 0)) + int(pacing.get("first_pass_seconds", 0))
			critical_room_total += 1
			var critical_index := int(definition.get("critical_path_index", -1))
			if critical_index < 0:
				errors.append("Critical room %s has no canonical path index." % room_id)
			elif critical_path_rooms.has(critical_index):
				errors.append("Critical path index %d is shared by %s and %s." % [critical_index, critical_path_rooms[critical_index], room_id])
			else:
				critical_path_rooms[critical_index] = room_id
		if definition.has("story_beat") or not (definition.get("story_triggers", []) as Array).is_empty():
			district_story_counts[district_id] = int(district_story_counts.get(district_id, 0)) + 1
		var bounds_values: Array = definition.get("bounds", [])
		if not _valid_rect_values(bounds_values):
			errors.append("Room %s has invalid bounds." % room_id)
			continue
		var bounds := _rect_from_values(bounds_values)
		var map_cell: Array = definition.get("map_cell", [])
		if map_cell.size() != 2:
			errors.append("Room %s has an invalid map cell." % room_id)
		else:
			var cell_key := "%s,%s" % [map_cell[0], map_cell[1]]
			if map_cells.has(cell_key):
				errors.append("Map cell %s is shared by %s and %s." % [cell_key, map_cells[cell_key], room_id])
			map_cells[cell_key] = room_id
		var spawns: Dictionary = definition.get("spawns", {})
		if spawns.is_empty():
			errors.append("Room %s has no stable spawns." % room_id)
		for spawn_id: Variant in spawns:
			var spawn_value: Variant = spawns[spawn_id]
			if spawn_value is not Array or not _point_inside(bounds, spawn_value as Array, 1.0):
				errors.append("Room %s spawn %s is outside its bounds." % [room_id, spawn_id])
		for platform_value: Variant in definition.get("platforms", []):
			if platform_value is not Array or not _rect_inside(bounds, platform_value as Array):
				errors.append("Room %s contains invalid or out-of-bounds platform geometry." % room_id)
		if bool(definition.get("authored_expansion", false)):
			authored_layout_count += 1
			var layout_id := String(definition.get("layout_id", ""))
			if layout_id.is_empty() or authored_layout_ids.has(layout_id):
				errors.append("Room %s has a missing or duplicate authored layout id %s." % [room_id, layout_id])
			authored_layout_ids[layout_id] = room_id
			if String(definition.get("layout_source", "")) != "district_layout_blueprint_v1":
				errors.append("Room %s does not identify its authored district layout source." % room_id)
			if String(definition.get("spatial_rhythm", "")).is_empty() or String(definition.get("landmark", "")).is_empty():
				errors.append("Room %s lacks a district spatial rhythm or landmark." % room_id)
			var authored_platforms := definition.get("platforms", []) as Array
			if authored_platforms.size() < 5:
				errors.append("Room %s has insufficient authored platform geometry." % room_id)
			var geometry_signature := JSON.stringify(authored_platforms)
			if authored_platform_signatures.has(geometry_signature):
				errors.append("Room %s duplicates authored platform geometry from %s." % [room_id, authored_platform_signatures[geometry_signature]])
			authored_platform_signatures[geometry_signature] = room_id
		if definition.has("cache"):
			var cache := definition.cache as Dictionary
			var cache_id := String(cache.get("id", ""))
			if cache_id.is_empty() or persistent_cache_ids.has(cache_id):
				errors.append("Room %s has a missing or duplicate persistent cache id %s." % [room_id, cache_id])
			persistent_cache_ids[cache_id] = room_id
			if int(cache.get("amount", 0)) <= 0 or not _point_inside(bounds, cache.get("position", []) as Array, 1.0):
				errors.append("Room %s cache %s has invalid currency or placement." % [room_id, cache_id])
		var connection_ids: Dictionary = {}
		for connection_value: Variant in definition.get("connections", []):
			if connection_value is not Dictionary:
				errors.append("Room %s contains an invalid connection." % room_id)
				continue
			var connection := connection_value as Dictionary
			var connection_id := String(connection.get("id", ""))
			if connection_id.is_empty() or connection_ids.has(connection_id):
				errors.append("Room %s contains a missing or duplicate connection id %s." % [room_id, connection_id])
			connection_ids[connection_id] = true
			if connection.get("rect", []) is not Array or not _rect_inside(bounds, connection.get("rect", []) as Array):
				errors.append("Room %s connection %s has invalid trigger geometry." % [room_id, connection_id])
			var target_id := String(connection.get("target_room", ""))
			var target_connection := String(connection.get("target_connection", ""))
			if not _rooms.has(target_id):
				errors.append("Room %s connection %s targets missing room %s." % [room_id, connection.get("id", ""), target_id])
				continue
			var target_spawns: Dictionary = (_rooms[target_id] as Dictionary).get("spawns", {})
			if not target_spawns.has(target_connection):
				errors.append("Room %s targets missing spawn %s in %s." % [room_id, target_connection, target_id])
			if not bool(connection.get("one_way", false)) and not _has_connection_back(target_id, room_id):
				errors.append("Room %s connection %s is asymmetric but is not explicitly one-way." % [room_id, connection_id])
	if authored_layout_count != 103 or authored_layout_ids.size() != authored_layout_count or authored_platform_signatures.size() != authored_layout_count:
		errors.append("Authored expansion layout coverage is rooms=%d ids=%d geometry=%d, expected 103 unique layouts." % [authored_layout_count, authored_layout_ids.size(), authored_platform_signatures.size()])
	_validate_map_connections(errors, map_cells)
	if critical_path_rooms.size() != critical_room_total:
		errors.append("Canonical critical path covers %d of %d critical rooms." % [critical_path_rooms.size(), critical_room_total])
	else:
		for critical_index: int in range(critical_room_total):
			if not critical_path_rooms.has(critical_index):
				errors.append("Canonical critical path is missing index %d." % critical_index)
				continue
			if critical_index >= critical_room_total - 1:
				continue
			var room_id := String(critical_path_rooms[critical_index])
			var next_room_id := String(critical_path_rooms.get(critical_index + 1, ""))
			if next_room_id.is_empty() or not _has_connection_to(room_id, next_room_id):
				errors.append("Canonical critical path is disconnected at %s -> %s." % [room_id, next_room_id])
	for district_id: String in district_ids:
		var count := int(district_room_counts.get(district_id, 0))
		var critical_count := int(district_critical_counts.get(district_id, 0))
		var optional_count := int(district_optional_counts.get(district_id, 0))
		var first_pass := int(district_first_pass.get(district_id, 0))
		if critical_count < 8 or critical_count > 14:
			errors.append("District %s has %d critical rooms, outside the authored 8–14 room budget." % [district_id, critical_count])
		if optional_count < 2 or optional_count > 5:
			errors.append("District %s has %d optional rooms, outside the authored 2–5 room budget." % [district_id, optional_count])
		if count != critical_count + optional_count:
			errors.append("District %s room accounting is inconsistent." % district_id)
		if first_pass < 900 or first_pass > 1200:
			errors.append("District %s first-pass pacing is %d seconds, outside 15–20 minutes." % [district_id, first_pass])
		if int(district_story_counts.get(district_id, 0)) < 1:
			errors.append("District %s has no district-level story beat." % district_id)
	var warp_ids: Dictionary = {}
	for warp_value: Variant in manifest().get("fast_travel_nodes", []):
		if warp_value is not Dictionary:
			errors.append("World manifest contains an invalid fast-travel record.")
			continue
		var warp := warp_value as Dictionary
		var warp_id := String(warp.get("id", ""))
		var warp_room_id := String(warp.get("room_id", ""))
		if warp_id.is_empty() or warp_ids.has(warp_id):
			errors.append("World manifest contains a missing or duplicate warp id: %s." % warp_id)
		warp_ids[warp_id] = true
		var required_flags: Variant = warp.get("required_story_flags", [])
		if required_flags is not Array:
			errors.append("Warp %s has invalid story-gate metadata." % warp_id)
		else:
			for flag_value: Variant in required_flags as Array:
				if String(flag_value).is_empty():
					errors.append("Warp %s contains an empty required story flag." % warp_id)
		if not _rooms.has(warp_room_id):
			errors.append("Warp %s targets a missing room." % warp.get("id", ""))
		elif String(((_rooms[warp_room_id] as Dictionary).get("warp_room", {}) as Dictionary).get("id", "")) != warp_id:
			errors.append("Warp %s is not authored in manifest room %s." % [warp_id, warp_room_id])
	return errors


static func _validate_map_connections(errors: PackedStringArray, map_cells: Dictionary) -> void:
	for room_id: String in _rooms:
		var source: Dictionary = _rooms[room_id]
		var source_cell: Array = source.get("map_cell", [])
		if source_cell.size() != 2:
			continue
		for connection_value: Variant in source.get("connections", []):
			if connection_value is not Dictionary:
				continue
			var connection := connection_value as Dictionary
			var target_id := String(connection.get("target_room", ""))
			if not _rooms.has(target_id):
				continue
			var target_cell: Array = (_rooms[target_id] as Dictionary).get("map_cell", [])
			if target_cell.size() != 2:
				errors.append("Room %s connection %s targets a room without a valid map cell." % [room_id, connection.get("id", "")])
				continue
			if source_cell == target_cell:
				errors.append("Room %s connection %s has a zero-length map link." % [room_id, connection.get("id", "")])
				continue
			if bool(connection.get("map_hidden", false)):
				if not _reciprocal_map_hidden(target_id, room_id):
					errors.append("Hidden map link %s -> %s is not hidden in both directions." % [room_id, target_id])
				continue
			var source_x := int(source_cell[0])
			var source_y := int(source_cell[1])
			var delta_x := int(target_cell[0]) - source_x
			var delta_y := int(target_cell[1]) - source_y
			var steps := _greatest_common_divisor(absi(delta_x), absi(delta_y))
			if steps <= 1:
				continue
			var step_x := int(delta_x / steps)
			var step_y := int(delta_y / steps)
			for index: int in range(1, steps):
				var crossed_key := "%d,%d" % [source_x + step_x * index, source_y + step_y * index]
				if map_cells.has(crossed_key):
					errors.append("Map link %s -> %s crosses unrelated room %s at %s; author a clear route or mark the shortcut map_hidden." % [room_id, target_id, map_cells[crossed_key], crossed_key])


static func _reciprocal_map_hidden(from_room_id: String, target_room_id: String) -> bool:
	for value: Variant in (_rooms[from_room_id] as Dictionary).get("connections", []):
		if value is Dictionary:
			var connection := value as Dictionary
			if String(connection.get("target_room", "")) == target_room_id:
				return bool(connection.get("map_hidden", false))
	return false


static func _greatest_common_divisor(left: int, right: int) -> int:
	while right != 0:
		var remainder := left % right
		left = right
		right = remainder
	return left


static func _valid_rect_values(values: Array) -> bool:
	return values.size() == 4 and float(values[2]) > 0.0 and float(values[3]) > 0.0


static func _rect_from_values(values: Array) -> Rect2:
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))


static func _rect_inside(bounds: Rect2, values: Array) -> bool:
	return _valid_rect_values(values) and bounds.encloses(_rect_from_values(values))


static func _point_inside(bounds: Rect2, values: Array, margin: float) -> bool:
	return values.size() == 2 and bounds.grow(-margin).has_point(Vector2(float(values[0]), float(values[1])))


static func _has_connection_back(from_room_id: String, target_room_id: String) -> bool:
	for value: Variant in (_rooms[from_room_id] as Dictionary).get("connections", []):
		if value is Dictionary and String((value as Dictionary).get("target_room", "")) == target_room_id:
			return true
	return false


static func _has_connection_to(from_room_id: String, target_room_id: String) -> bool:
	for value: Variant in (_rooms[from_room_id] as Dictionary).get("connections", []):
		if value is Dictionary and String((value as Dictionary).get("target_room", "")) == target_room_id:
			return true
	return false


static func reachable_rooms(start_id := "") -> Dictionary:
	_ensure_loaded()
	var start := start_id if not start_id.is_empty() else start_room_id()
	var visited: Dictionary = {}
	var pending: Array[String] = [start]
	while not pending.is_empty():
		var room_id: String = pending.pop_front()
		if visited.has(room_id) or not _rooms.has(room_id):
			continue
		visited[room_id] = true
		for connection_value: Variant in (_rooms[room_id] as Dictionary).get("connections", []):
			var target := String((connection_value as Dictionary).get("target_room", ""))
			if not visited.has(target):
				pending.append(target)
	return visited


static func _ensure_loaded() -> void:
	if not _manifest.is_empty():
		return
	_manifest = _load_json(MANIFEST_PATH)
	for file_value: Variant in _manifest.get("room_files", []):
		var source_path := String(file_value)
		var payload := _load_json(source_path)
		for room_value: Variant in payload.get("rooms", []):
			if room_value is Dictionary:
				var definition := room_value as Dictionary
				var room_id := String(definition.get("id", ""))
				if not room_id.is_empty():
					if _rooms.has(room_id):
						if not _duplicate_room_sources.has(room_id):
							_duplicate_room_sources[room_id] = [String(_room_sources.get(room_id, "unknown"))]
						(_duplicate_room_sources[room_id] as Array).append(source_path)
					if not definition.has("bounds"):
						definition["bounds"] = [0, 0, 960, 540]
					if not definition.has("map_cell"):
						definition["map_cell"] = [100 + _rooms.size(), 100]
					_room_sources[room_id] = source_path
					_rooms[room_id] = definition


static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("World data is missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is not Dictionary:
		push_error("World data is invalid: %s" % path)
		return {}
	return parsed as Dictionary
