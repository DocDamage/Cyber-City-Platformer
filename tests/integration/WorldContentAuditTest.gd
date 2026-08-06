extends SceneTree

const ROOM_SCENE := preload("res://scenes/world/WorldRoom.tscn")
const DISTRICT_SIGNATURES := {
	"rooftop_alley": ["tutorial", "hazard:electrical_floor", "shortcut", "save_room", "warp_room", "reward", "service:barber", "service:tailor"],
	"billboard_highway": ["moving_platforms", "hazard:electrical_floor", "reward", "story"],
	"communication_spire": ["moving_platforms", "hazard:laser_grid", "ability_reward", "story"],
	"skybridge_junction": ["moving_platforms", "breakaway_platforms", "warp_room", "reward"],
	"executive_helipad": ["save_room", "boss", "story"],
	"sub_level_intake": ["conveyors", "hazard:steam_vent", "shortcut", "tutorial"],
	"conveyor_assembly": ["conveyors", "terminals", "security_gates", "reward"],
	"smelting_core": ["hazard:steam_vent", "hazard:toxic_pool", "ability_reward", "reward"],
	"robotic_maintenance": ["hazard:crusher", "terminals", "security_gates", "shortcut", "story"],
	"assembly_engine": ["conveyors", "save_room", "warp_room", "boss"],
	"lunar_surface_arrival": ["hazard:gravity_zone", "hazard:void_pit", "warp_room", "tutorial"],
	"research_cleanrooms": ["hazard:laser_grid", "terminals", "security_gates", "shortcut", "reward", "service:npc"],
	"security_grid_shaft": ["hazard:gravity_zone", "hazard:rotating_laser", "save_room", "shortcut", "reward"],
	"bio_tech_labs": ["hazard:gravity_zone", "terminals", "security_gates", "ability_reward", "reward", "story"],
	"orbital_command": ["hazard:gravity_zone", "hazard:laser_grid", "save_room", "boss"],
	"corrupted_outpost": ["hazard:corruption_zone", "ability_reward", "tutorial"],
	"the_dark_chasm": ["moving_platforms", "hazard:void_pit", "save_room", "shortcut", "reward"],
	"bio_mechanical_nest": ["hazard:corruption_zone", "ability_reward", "reward", "story"],
	"abyssal_sanctuary": ["conveyors", "hazard:gravity_zone", "warp_room", "reward"],
	"heart_of_the_void": ["hazard:corruption_zone", "hazard:void_pit", "save_room", "boss"],
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(30.0, true, false, true).timeout.connect(func() -> void:
		push_error("World content audit timed out.")
		quit(1)
	)
	var validation := WorldDatabase.validate()
	if not _require(validation.is_empty(), "Production world validation failed: %s" % validation):
		return
	var district_regions := {}
	for district_value: Variant in WorldDatabase.manifest().get("districts", []):
		var district := district_value as Dictionary
		district_regions[String(district.get("id", ""))] = String(district.get("region_id", ""))
	var art_validation := DistrictArtCatalog.validate(district_regions)
	if not _require(art_validation.is_empty(), "District art catalog validation failed: %s" % art_validation):
		return
	if not _require(QuestDatabase.validate().is_empty() and DialogueDatabase.validate().is_empty(), "Narrative or quest database validation failed."):
		return

	var rooms := WorldDatabase.rooms()
	var cutscenes := _load_json("res://data/narrative/cutscenes.json").get("sequences", {}) as Dictionary
	var dialogue := _load_json("res://data/narrative/dialogue.json").get("entries", {}) as Dictionary
	var produced_flags: Dictionary = {"game_complete":true}
	for sequence_id: String in cutscenes:
		var sequence := cutscenes[sequence_id] as Dictionary
		if not _require(not (sequence.get("commands", []) as Array).is_empty() and not (sequence.get("skip_endpoint", []) as Array).is_empty(), "Sequence %s has no commands or skip endpoint." % sequence_id):
			return
		var skip_restores_control := false
		for command_value: Variant in sequence.get("commands", []):
			var command := command_value as Dictionary
			if String(command.get("type", "")) == "dialogue" and not dialogue.has(String(command.get("entry_id", ""))):
				if not _require(false, "Sequence %s references missing dialogue %s." % [sequence_id, command.get("entry_id", "")]):
					return
			if String(command.get("type", "")) == "set_flag":
				produced_flags[String(command.get("id", ""))] = true
		for command_value: Variant in sequence.get("skip_endpoint", []):
			var command := command_value as Dictionary
			var command_type := String(command.get("type", ""))
			skip_restores_control = skip_restores_control or command_type in ["unlock_player", "finish_game"]
			if command_type == "set_flag":
				produced_flags[String(command.get("id", ""))] = true
		if not _require(skip_restores_control, "Sequence %s can skip without restoring control or finishing safely." % sequence_id):
			return

	var persistent_ids: Dictionary = {}
	var barrier_ids: Dictionary = {}
	var obtainable_abilities: Dictionary = {"basic_teleport":true}
	var obtainable_items: Dictionary = {}
	var authored_warps: Dictionary = {}
	var reward_families: Dictionary = {}
	var service_ids: Dictionary = {}
	var boss_count := 0
	var story_count := 0
	var gate_count := 0
	var terminal_count := 0
	var cache_count := 0
	var critical_room_count := 0
	var optional_room_count := 0
	var authored_layout_ids: Dictionary = {}
	var authored_geometry: Dictionary = {}
	var art_profiles := DistrictArtCatalog.profiles()
	var art_prop_paths := {}
	for district_id: String in art_profiles:
		for prop_path_value: Variant in (art_profiles[district_id] as Dictionary).get("prop_paths", []):
			art_prop_paths[String(prop_path_value)] = district_id
	if not _require(art_profiles.size() == 20 and art_prop_paths.size() == 40, "District art bible does not provide twenty profiles and forty unique prop assignments."):
		return
	for room_id: String in rooms:
		var room := rooms[room_id] as Dictionary
		if bool((room.get("pacing", {}) as Dictionary).get("optional", false)):
			optional_room_count += 1
		else:
			critical_room_count += 1
		if bool(room.get("authored_expansion", false)):
			var layout_id := String(room.get("layout_id", ""))
			var geometry_signature := JSON.stringify(room.get("platforms", []))
			if not _require(not layout_id.is_empty() and not authored_layout_ids.has(layout_id), "Room %s has a missing or duplicate authored layout id %s." % [room_id, layout_id]):
				return
			if not _require(String(room.get("layout_source", "")) == "district_layout_blueprint_v1" and not String(room.get("spatial_rhythm", "")).is_empty() and not String(room.get("landmark", "")).is_empty(), "Room %s lacks authored layout provenance, rhythm, or landmark." % room_id):
				return
			if not _require((room.get("platforms", []) as Array).size() >= 5 and not authored_geometry.has(geometry_signature), "Room %s reuses generic expansion platform geometry from %s." % [room_id, authored_geometry.get(geometry_signature, "unknown")]):
				return
			authored_layout_ids[layout_id] = room_id
			authored_geometry[geometry_signature] = room_id
		var local_mechanics: Dictionary = {}
		for conveyor_value: Variant in room.get("conveyors", []):
			var conveyor := conveyor_value as Dictionary
			var conveyor_id := String(conveyor.get("id", ""))
			if not conveyor_id.is_empty():
				if not _require(not local_mechanics.has(conveyor_id), "Room %s duplicates mechanic id %s." % [room_id, conveyor_id]):
					return
				local_mechanics[conveyor_id] = true
		for gate_value: Variant in room.get("security_gates", []):
			var gate := gate_value as Dictionary
			var gate_id := String(gate.get("id", ""))
			if not _require(not gate_id.is_empty() and not local_mechanics.has(gate_id) and not persistent_ids.has(gate_id), "Security gate id %s is missing or duplicated." % gate_id):
				return
			if not _require(int(gate.get("required_switches", 1)) >= 1, "Security gate %s has no valid switch requirement." % gate_id):
				return
			local_mechanics[gate_id] = true
			persistent_ids[gate_id] = room_id
			gate_count += 1
		for terminal_value: Variant in room.get("terminals", []):
			var terminal := terminal_value as Dictionary
			var terminal_id := String(terminal.get("id", ""))
			if not _require(not terminal_id.is_empty() and not local_mechanics.has(terminal_id) and not persistent_ids.has(terminal_id), "Terminal id %s is missing or duplicated." % terminal_id):
				return
			local_mechanics[terminal_id] = true
			persistent_ids[terminal_id] = room_id
			terminal_count += 1
		for terminal_value: Variant in room.get("terminals", []):
			var terminal := terminal_value as Dictionary
			for target_value: Variant in terminal.get("targets", []):
				if not _require(local_mechanics.has(String(target_value)), "Room %s terminal %s targets missing local mechanic %s." % [room_id, terminal.get("id", ""), target_value]):
					return
		if room.has("story_beat"):
			story_count += 1
			if not _require(cutscenes.has(String(room.story_beat)), "Room %s references missing story sequence %s." % [room_id, room.story_beat]):
				return
		for trigger_value: Variant in room.get("story_triggers", []):
			var trigger := trigger_value as Dictionary
			story_count += 1
			if not _require(cutscenes.has(String(trigger.get("sequence_id", ""))), "Room %s references a missing explicit story sequence." % room_id):
				return
		for field: String in ["shortcut", "save_room", "warp_room", "reward", "ability_reward", "boss", "cache"]:
			if not room.has(field):
				continue
			var record := room[field] as Dictionary
			var object_id := String(record.get("id", record.get("ability", "")))
			if not _require(not object_id.is_empty() and not persistent_ids.has(object_id), "Persistent %s id %s is missing or duplicated globally." % [field, object_id]):
				return
			persistent_ids[object_id] = room_id
			if field == "cache":
				if not _require(int(record.get("amount", 0)) > 0, "Cache %s has no currency reward." % object_id):
					return
				cache_count += 1
		if room.has("reward"):
			var reward := room.reward as Dictionary
			var family := StringName(reward.get("family", ""))
			if not _require(WeaponCatalog.has_family(family), "Room %s rewards unsupported weapon family %s." % [room_id, family]):
				return
			reward_families[String(family)] = true
			obtainable_items[String(reward.get("id", ""))] = true
		if room.has("ability_reward"):
			obtainable_abilities[String((room.ability_reward as Dictionary).get("ability", ""))] = true
		if room.has("boss"):
			boss_count += 1
			var boss := room.boss as Dictionary
			var intro_sequence := String(boss.get("intro_sequence", ""))
			var defeat_sequence := String(boss.get("defeat_sequence", ""))
			if not _require(cutscenes.has(intro_sequence) and cutscenes.has(defeat_sequence), "Boss %s lacks data-authored intro or defeat sequences." % boss.get("id", "")):
				return
			if not _require(bool((cutscenes[intro_sequence] as Dictionary).get("once", false)) and bool((cutscenes[defeat_sequence] as Dictionary).get("once", false)), "Boss %s intro and defeat sequences must be first-view story events." % boss.get("id", "")):
				return
			produced_flags[String(boss.get("completion_flag", ""))] = true
			var boss_reward := String(boss.get("reward_ability", ""))
			if not boss_reward.is_empty():
				obtainable_abilities[boss_reward] = true
		for encounter_value: Variant in room.get("encounters", []):
			var encounter := encounter_value as Dictionary
			var encounter_id := String(encounter.get("id", ""))
			if not _require(not encounter_id.is_empty() and not persistent_ids.has(encounter_id), "Encounter id %s is missing or duplicated globally." % encounter_id):
				return
			persistent_ids[encounter_id] = room_id
		for service_value: Variant in room.get("services", []):
			var service := service_value as Dictionary
			if String(service.get("type", "")) != "npc":
				continue
			var service_id := String(service.get("id", ""))
			if not _require(not service_id.is_empty() and not service_ids.has(service_id), "NPC service id %s is missing or duplicated." % service_id):
				return
			service_ids[service_id] = room_id
			var entries: Array = service.get("dialogue_entries", [])
			if not _require(not entries.is_empty(), "NPC %s has no dialogue entries." % service_id):
				return
			for entry_value: Variant in entries:
				if not _require(dialogue.has(String(entry_value)), "NPC %s references missing dialogue %s." % [service_id, entry_value]):
					return
		for connection_value: Variant in room.get("connections", []):
			var connection := connection_value as Dictionary
			var required := String(connection.get("required_ability", ""))
			if not required.is_empty():
				var barrier_id := String(connection.get("barrier_id", ""))
				if not _require(not barrier_id.is_empty() and not barrier_ids.has(barrier_id), "Ability barrier %s is missing or duplicated." % barrier_id):
					return
				barrier_ids[barrier_id] = room_id
				if not _require(AbilityState.DEFAULTS.has(required), "Connection %s requires unknown ability %s." % [connection.get("id", ""), required]):
					return

	for ability_id: String in AbilityState.DEFAULTS:
		if int(AbilityState.DEFAULTS[ability_id]) == 0 and not _require(obtainable_abilities.has(ability_id), "Progression ability %s has no obtainable reward." % ability_id):
			return
	for family_id: StringName in CharacterProfile.WEAPON_FAMILIES:
		if not _require(reward_families.has(String(family_id)), "Weapon family %s has no optional world reward." % family_id):
			return
	for warp_value: Variant in WorldDatabase.manifest().get("fast_travel_nodes", []):
		authored_warps[String((warp_value as Dictionary).get("id", ""))] = true
	for quest_id: String in QuestDatabase.definitions():
		var quest := QuestDatabase.definition(StringName(quest_id))
		for step_value: Variant in quest.get("steps", []):
			var step := step_value as Dictionary
			var target_room_id := String(step.get("target_room_id", ""))
			if String(quest.get("category", "side")) == "main" and not _require(rooms.has(target_room_id), "Main quest %s step %s targets missing map room %s." % [quest_id, step.get("id", ""), target_room_id]):
				return
			var event_type := String(step.get("event_type", ""))
			var event_id := String(step.get("event_id", ""))
			var available := false
			match event_type:
				"story_flag": available = produced_flags.has(event_id)
				"item": available = obtainable_items.has(event_id)
				"ability": available = obtainable_abilities.has(event_id)
				"warp": available = authored_warps.has(event_id)
			if not _require(available, "Quest %s waits for unavailable %s event %s." % [quest_id, event_type, event_id]):
				return
	var district_errors := _validate_district_contracts(rooms)
	if not _require(district_errors.is_empty(), "District production contracts failed: %s" % district_errors):
		return
	if not _require(authored_layout_ids.size() == 103 and authored_geometry.size() == 103, "Expansion does not provide 103 unique authored layout and geometry contracts."):
		return

	var game := root.get_node("GameManager")
	game.call(&"new_game")
	var container := Node2D.new()
	container.name = "WorldAuditRooms"
	root.add_child(container)
	var room_ids := PackedStringArray(rooms.keys())
	room_ids.sort()
	for room_id: String in room_ids:
		var definition := rooms[room_id] as Dictionary
		var instance := ROOM_SCENE.instantiate() as WorldRoom
		instance.definition = definition
		container.add_child(instance)
		await process_frame
		if not _require(instance.name == room_id, "Room %s did not build with its stable runtime id." % room_id):
			return
		var duplicated_room_title := false
		var expected_room_title := String(definition.get("display_name", room_id)).to_upper()
		for direct_child: Node in instance.get_children():
			if direct_child is Label and (direct_child as Label).text == expected_room_title:
				duplicated_room_title = true
				break
		if not _require(not duplicated_room_title, "Room %s renders a duplicate world-space title beneath the HUD location label." % room_id):
			return
		if not String(definition.get("tutorial", "")).is_empty():
			var tutorial_prompt := instance.get_node_or_null("TutorialPrompt") as PanelContainer
			if not _require(tutorial_prompt != null and tutorial_prompt.position.y >= 136.0, "Room %s tutorial prompt overlaps the HUD objective band." % room_id):
				return
		if not _require(_count_direct(instance, "RoomConnection") == (definition.get("connections", []) as Array).size(), "Room %s did not build all connection triggers." % room_id):
			return
		var expected_stories := (definition.get("story_triggers", []) as Array).size() + (1 if definition.has("story_beat") else 0)
		if not _require(_count_direct(instance, "StoryTrigger") == expected_stories, "Room %s did not build all story triggers." % room_id):
			return
		if not _require(_count_direct(instance, "EncounterController") == (definition.get("encounters", []) as Array).size(), "Room %s did not build all encounters." % room_id):
			return
		if not _require(_count_direct(instance, "SecurityGate") == (definition.get("security_gates", []) as Array).size() and _count_direct(instance, "InteractiveTerminal") == (definition.get("terminals", []) as Array).size(), "Room %s did not build all security gates and terminals." % room_id):
			return
		if not _require(_count_direct(instance, "PersistentCache") == (1 if definition.has("cache") else 0), "Room %s did not build its persistent cache." % room_id):
			return
		var expected_platforms := definition.get("platforms", []) as Array
		var terrain_platforms: Array[TerrainPlatform] = []
		for direct_child: Node in instance.get_children():
			if direct_child is TerrainPlatform:
				terrain_platforms.append(direct_child as TerrainPlatform)
		if not _require(terrain_platforms.size() == expected_platforms.size(), "Room %s did not build one terrain-art platform per collision rectangle." % room_id):
			return
		for platform_index: int in range(terrain_platforms.size()):
			var values := expected_platforms[platform_index] as Array
			var expected_rect := Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))
			var platform := terrain_platforms[platform_index]
			var collision := platform.get_node_or_null("Collision") as CollisionShape2D
			var shape := collision.shape as RectangleShape2D if collision != null else null
			var art := platform.get_node_or_null("TerrainArt") as TerrainSurfaceArt
			if not _require(platform.world_rect == expected_rect and platform.position == expected_rect.get_center() and shape != null and shape.size == expected_rect.size and art != null and art.source_texture != null and String(art.get_meta(&"source_texture", "")).begins_with("res://assets/runtime/environments/") and is_equal_approx(float(art.get_meta(&"visual_surface_y", INF)), float(art.get_meta(&"collision_surface_y", -INF))), "Room %s platform %d does not share an exact top edge between collision geometry and native terrain art." % [room_id, platform_index]):
				return
		var tint_backdrop := instance.get_node_or_null("RoomTintBackdrop") as Polygon2D
		var native_backdrop := instance.get_node_or_null("NativeBackdropLayer00") as Node2D
		var coverage := native_backdrop.get_meta(&"coverage_rect", Rect2()) as Rect2 if native_backdrop != null else Rect2()
		if not _require(tint_backdrop != null and native_backdrop != null and coverage.position.x <= instance.bounds.position.x - 160.0 and coverage.position.y <= instance.bounds.position.y - 48.0 and coverage.end.x >= instance.bounds.end.x + 160.0 and coverage.end.y >= instance.bounds.end.y + 48.0 and float(native_backdrop.get_meta(&"native_scale", 0.0)) > 0.0 and instance.find_child("BackdropLayer00", true, false) == null, "Room %s does not use fixed-scale, overscanned native background layers." % room_id):
			return
		if not _require(instance.find_child("DistrictArchitecture", true, false) == null and instance.find_child("DistrictAtmosphere", true, false) == null and instance.find_child("ForegroundDressing", true, false) == null and instance.find_child("PlatformTrim", true, false) == null, "Room %s still renders legacy procedural skyline, atmosphere, frame, or neon-bar platform dressing." % room_id):
			return
		var dressing := instance.get_node_or_null("AuthoredDressing") as Node2D
		if definition.has("landmark"):
			var art_profile := DistrictArtCatalog.profile(String(definition.get("district_id", "")))
			if not _require(dressing != null and String(dressing.get_meta(&"landmark_name", "")) == String(definition.landmark) and String(dressing.get_meta(&"composition_source", "")) == "room_surface_composition_v1" and dressing.get_child_count() == 2, "Room %s did not turn its landmark into a supported district prop composition." % room_id):
				return
			var expected_prop_paths := art_profile.get("prop_paths", []) as Array
			for prop_index: int in range(dressing.get_child_count()):
				var prop := dressing.get_child(prop_index) as Sprite2D
				var support := prop.get_meta(&"support_rect", Rect2()) as Rect2 if prop != null else Rect2()
				var prop_bottom := prop.position.y + prop.texture.get_size().y * absf(prop.scale.y) * 0.5 if prop != null and prop.texture != null else -INF
				if not _require(prop != null and String(prop.get_meta(&"source_path", "")) in expected_prop_paths and prop.texture != null and is_equal_approx(prop_bottom, support.position.y), "Room %s landmark prop %d is not loaded from its district set and bottom-aligned to its support platform." % [room_id, prop_index]):
					return
		if definition.has("boss") and not _require(_count_direct(instance, "BossBase") == 1 and _count_direct(instance, "BossArenaController") == 1, "Room %s did not build its boss and arena." % room_id):
			return
		instance.queue_free()
		await process_frame

	container.queue_free()
	await process_frame
	print("WORLD_CONTENT_AUDIT_TEST_OK rooms=", rooms.size(), " critical=", critical_room_count, " optional=", optional_room_count, " layouts=", authored_layout_ids.size(), " art_profiles=", art_profiles.size(), " props=", art_prop_paths.size(), " stories=", story_count, " bosses=", boss_count, " npcs=", service_ids.size(), " gates=", gate_count, " terminals=", terminal_count, " caches=", cache_count, " persistent_ids=", persistent_ids.size())
	quit()


func _count_direct(node: Node, class_label: String) -> int:
	var count := 0
	for child: Node in node.get_children():
		var matches := false
		match class_label:
			"RoomConnection": matches = child is RoomConnection
			"StoryTrigger": matches = child is StoryTrigger
			"EncounterController": matches = child is EncounterController
			"SecurityGate": matches = child is SecurityGate
			"InteractiveTerminal": matches = child is InteractiveTerminal
			"PersistentCache": matches = child.is_in_group(&"persistent_caches")
			"BossBase": matches = child is BossBase
			"BossArenaController": matches = child is BossArenaController
		if matches:
			count += 1
	return count


func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _validate_district_contracts(rooms: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for district_id: String in DISTRICT_SIGNATURES:
		var district_rooms: Array[Dictionary] = []
		for room_value: Variant in rooms.values():
			var room := room_value as Dictionary
			if String(room.get("district_id", "")) == district_id:
				district_rooms.append(room)
		if district_rooms.is_empty():
			errors.append("%s has no rooms" % district_id)
			continue
		var first_pass_seconds := 0
		var encounter_count := 0
		var has_boss := false
		var has_meaningful_reward := false
		var critical_count := 0
		var optional_count := 0
		var expansion_roles: Dictionary = {}
		var optional_cache_count := 0
		for room: Dictionary in district_rooms:
			var pacing := room.get("pacing", {}) as Dictionary
			if bool(pacing.get("optional", false)):
				optional_count += 1
				if room.has("cache"):
					optional_cache_count += 1
			else:
				critical_count += 1
				first_pass_seconds += int(pacing.get("first_pass_seconds", 0))
				if bool(room.get("authored_expansion", false)):
					expansion_roles[String(room.get("room_role", ""))] = true
			encounter_count += (room.get("encounters", []) as Array).size()
			has_boss = has_boss or room.has("boss")
			has_meaningful_reward = has_meaningful_reward or room.has("reward") or room.has("ability_reward") or room.has("boss") or room.has("shortcut") or room.has("warp_room")
		if first_pass_seconds < 900 or first_pass_seconds > 1200:
			errors.append("%s authored first-pass budget is %ds" % [district_id, first_pass_seconds])
		if critical_count < 8 or critical_count > 14:
			errors.append("%s has %d critical rooms" % [district_id, critical_count])
		if optional_count < 2 or optional_count > 5:
			errors.append("%s has %d optional rooms" % [district_id, optional_count])
		if district_id != "rooftop_alley":
			for required_role: String in ["teach", "test", "twist", "recovery"]:
				if not expansion_roles.has(required_role):
					errors.append("%s lacks authored %s room" % [district_id, required_role])
		if optional_cache_count < 1:
			errors.append("%s has no meaningful optional currency cache" % district_id)
		if encounter_count < (1 if has_boss else 2):
			errors.append("%s has insufficient encounter cadence" % district_id)
		if not has_meaningful_reward:
			errors.append("%s has no meaningful reward/progression event" % district_id)
		for feature_signal: String in DISTRICT_SIGNATURES[district_id]:
			if not _district_has_signal(district_rooms, feature_signal):
				errors.append("%s lacks %s" % [district_id, feature_signal])
	return errors


func _district_has_signal(rooms: Array[Dictionary], feature_signal: String) -> bool:
	if feature_signal == "story":
		return rooms.any(func(room: Dictionary) -> bool: return room.has("story_beat") or not (room.get("story_triggers", []) as Array).is_empty())
	if feature_signal.begins_with("hazard:"):
		var hazard_type := feature_signal.trim_prefix("hazard:")
		for room: Dictionary in rooms:
			for hazard_value: Variant in room.get("hazards", []):
				if String((hazard_value as Dictionary).get("type", "")) == hazard_type:
					return true
		return false
	if feature_signal.begins_with("service:"):
		var service_type := feature_signal.trim_prefix("service:")
		for room: Dictionary in rooms:
			for service_value: Variant in room.get("services", []):
				if String((service_value as Dictionary).get("type", "")) == service_type:
					return true
		return false
	return rooms.any(func(room: Dictionary) -> bool:
		var value: Variant = room.get(feature_signal, null)
		return not (value as Array).is_empty() if value is Array else room.has(feature_signal)
	)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
