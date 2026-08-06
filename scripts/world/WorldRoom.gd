class_name WorldRoom
extends Node2D

const ENEMY_SCENE := preload("res://scenes/EnemyBase.tscn")
const PERSISTENT_CACHE_SCRIPT := preload("res://scripts/world/PersistentCache.gd")
const STAGE_COMPOSITION_SCRIPT := preload("res://scripts/world/AuthoredStageComposition.gd")
const BACKDROP_OVERSCAN_X := 384.0
const BACKDROP_OVERSCAN_Y := 96.0
const REGION_BACKGROUNDS := {
	"cyber_city": [
		{"path":"res://assets/runtime/environments/Act1_CyberCity/Cyber City/Cyber City/Backgroud/BACKGROUND (6)/Backgroud (6) 1.png", "scale":2.0},
		{"path":"res://assets/runtime/environments/Act1_CyberCity/Cyber City/Cyber City/Backgroud/BACKGROUND (5)/Backgroud (5) 1.png", "scale":2.0},
		{"path":"res://assets/runtime/environments/Act1_CyberCity/Cyber City/Cyber City/Backgroud/BACKGROUND (3)/Backgroud (3) 1.png", "scale":2.0},
		{"path":"res://assets/runtime/environments/Act1_CyberCity/Cyber City/Cyber City/Backgroud/BACKGROUND (2)/Backgroud (2) 1.png", "scale":2.0},
		{"path":"res://assets/runtime/environments/Act1_CyberCity/Cyber City/Cyber City/Backgroud/BACKGROUND (1)/Backgroud (1) 1.png", "scale":2.0},
	],
	"robot_factory": [
		{"path":"res://assets/runtime/environments/Act2_RobotFactory/Mega Robot Factory/CENA (!)/BACKGROUD/BACKGROUND (1).png", "scale":2.0},
	],
	"neon_moon": [
		{"path":"res://assets/runtime/environments/Act3_NeonMoon/Neon Moon Protocol/Backgroud/backgroud (1).png", "scale":1.5},
		{"path":"res://assets/runtime/environments/Act3_NeonMoon/Neon Moon Protocol/Backgroud/backgroud (2).png", "scale":1.5},
		{"path":"res://assets/runtime/environments/Act3_NeonMoon/Neon Moon Protocol/Backgroud/backgroud (3).png", "scale":1.5},
		{"path":"res://assets/runtime/environments/Act3_NeonMoon/Neon Moon Protocol/Backgroud/backgroud (4).png", "scale":1.5},
	],
	"abyssal_night": [
		{"path":"res://assets/runtime/environments/Act4_AbyssalNight/Abyssal Night/Abyssal Night – Color (2)/Backgroud/backgroud (1).png", "scale":1.5},
		{"path":"res://assets/runtime/environments/Act4_AbyssalNight/Abyssal Night/Abyssal Night – Color (2)/Backgroud/backgroud (2).png", "scale":1.5},
		{"path":"res://assets/runtime/environments/Act4_AbyssalNight/Abyssal Night/Abyssal Night – Color (2)/Backgroud/backgroud (4).png", "scale":1.5},
	],
}
const ROOFTOP_PROP_COMPOSITIONS := {
	"cyber_rooftop_entry": [
		{"platform":1, "prop":0, "x":0.50, "scale":1.0},
		{"platform":3, "prop":1, "x":0.58, "scale":1.0},
	],
	"cyber_rooftop_lane": [
		{"platform":1, "prop":1, "x":0.24, "scale":0.82},
		{"platform":4, "prop":0, "x":0.72, "scale":0.88, "flip":true},
	],
	"cyber_rooftop_interior": [
		{"platform":1, "prop":1, "x":0.28, "scale":0.9},
		{"platform":4, "prop":0, "x":0.64, "scale":0.9},
	],
	"cyber_rooftop_phase_tutorial": [
		{"platform":0, "prop":1, "x":0.66, "scale":0.82},
		{"platform":1, "prop":1, "x":0.34, "scale":0.82, "flip":true},
	],
	"cyber_rooftop_cache": [
		{"platform":1, "prop":0, "x":0.35, "scale":0.82},
		{"platform":2, "prop":0, "x":0.65, "scale":0.82, "flip":true},
	],
	"cyber_rooftop_signworks": [
		{"platform":3, "prop":0, "x":0.45, "scale":0.95},
		{"platform":5, "prop":1, "x":0.62, "scale":0.9},
	],
	"cyber_rooftop_shaft": [
		{"platform":1, "prop":1, "x":0.24, "scale":0.85},
		{"platform":4, "prop":1, "x":0.70, "scale":0.85, "flip":true},
	],
	"cyber_rooftop_market": [
		{"platform":1, "prop":0, "x":0.44, "scale":1.0},
		{"platform":2, "prop":1, "x":0.60, "scale":0.9},
	],
	"cyber_rooftop_shortcut": [
		{"platform":1, "prop":1, "x":0.30, "scale":0.82},
		{"platform":4, "prop":0, "x":0.66, "scale":0.86, "flip":true},
	],
	"cyber_rooftop_overlook": [
		{"platform":1, "prop":0, "x":0.52, "scale":1.0},
		{"platform":2, "prop":1, "x":0.48, "scale":0.9},
	],
	"cyber_rooftop_guardian": [
		{"platform":1, "prop":1, "x":0.34, "scale":0.85},
		{"platform":3, "prop":1, "x":0.66, "scale":0.85, "flip":true},
	],
}
signal room_built(room_id: String)

var definition: Dictionary = {}
var bounds := Rect2(0, 0, 960, 540)
var _tutorial_label: Label
var _art_profile: Dictionary = {}
var _platform_index := 0


func _ready() -> void:
	add_to_group(&"world_rooms")
	_build()


func spawn_position(connection_id: String) -> Vector2:
	var spawns: Dictionary = definition.get("spawns", {})
	var value: Array = spawns.get(connection_id, spawns.get("west", spawns.values()[0] if not spawns.is_empty() else [80, 446]))
	return Vector2(float(value[0]), float(value[1]))


func _build() -> void:
	name = String(definition.get("id", "WorldRoom"))
	var bounds_values: Array = definition.get("bounds", [0, 0, 960, 540])
	bounds = Rect2(float(bounds_values[0]), float(bounds_values[1]), float(bounds_values[2]), float(bounds_values[3]))
	_art_profile = DistrictArtCatalog.profile(String(definition.get("district_id", "")))
	_build_background()
	_build_stage_composition()
	_build_environment_details()
	for platform_value: Variant in definition.get("platforms", []):
		_build_platform(platform_value as Array)
	_build_special_platforms()
	_build_security_mechanics()
	for hazard_value: Variant in definition.get("hazards", []):
		_build_hazard(hazard_value as Dictionary)
	for connection_value: Variant in definition.get("connections", []):
		var connection := RoomConnection.new()
		connection.configure(connection_value as Dictionary)
		add_child(connection)
	if definition.has("shortcut"):
		var shortcut := PersistentShortcut.new()
		shortcut.configure(definition.shortcut)
		add_child(shortcut)
	if definition.has("save_room"):
		var save_room := SaveRoom.new()
		save_room.configure(definition.save_room)
		add_child(save_room)
	if definition.has("warp_room"):
		var warp_room := WarpRoom.new()
		warp_room.configure(definition.warp_room)
		add_child(warp_room)
	if definition.has("reward"):
		var pickup := PersistentPickup.new()
		pickup.configure(definition.reward)
		add_child(pickup)
	if definition.has("cache"):
		var cache := PERSISTENT_CACHE_SCRIPT.new()
		cache.configure(definition.cache)
		add_child(cache)
	if definition.has("ability_reward"):
		var ability_pickup := PersistentAbilityPickup.new()
		ability_pickup.configure(definition.ability_reward)
		add_child(ability_pickup)
	_build_story_triggers()
	_build_enemies()
	_build_encounters()
	_build_boss()
	_build_services()
	_build_tutorial()
	room_built.emit(String(definition.get("id", "")))


func _build_stage_composition() -> void:
	var composition := STAGE_COMPOSITION_SCRIPT.new() as Node2D
	composition.name = "AuthoredStageMass"
	composition.z_index = -24
	composition.call(&"configure", bounds, definition, _art_profile)
	add_child(composition)


func _build_background() -> void:
	var region := String(definition.get("region_id", "cyber_city"))
	var colors := {"cyber_city":Color("081b35"),"robot_factory":Color("27180f"),"neon_moon":Color("18132f"),"abyssal_night":Color("210d22")}
	var background := Polygon2D.new()
	background.name = "RoomTintBackdrop"
	background.polygon = PackedVector2Array([
		bounds.position - Vector2(BACKDROP_OVERSCAN_X, BACKDROP_OVERSCAN_Y),
		Vector2(bounds.end.x + BACKDROP_OVERSCAN_X, bounds.position.y - BACKDROP_OVERSCAN_Y),
		bounds.end + Vector2(BACKDROP_OVERSCAN_X, BACKDROP_OVERSCAN_Y),
		Vector2(bounds.position.x - BACKDROP_OVERSCAN_X, bounds.end.y + BACKDROP_OVERSCAN_Y),
	])
	background.color = DistrictArtCatalog.profile_color(_art_profile, "background_color", colors.get(region, Color("081b35")))
	background.z_index = -50
	add_child(background)
	var recipes: Array = REGION_BACKGROUNDS.get(region, [])
	for index: int in range(recipes.size()):
		var recipe := recipes[index] as Dictionary
		var path := String(recipe.get("path", ""))
		if not ResourceLoader.exists(path, "Texture2D"):
			continue
		_build_native_background_layer(index, path, float(recipe.get("scale", 1.0)))


func _build_environment_details() -> void:
	_build_surface_dressing()


func _build_native_background_layer(index: int, path: String, native_scale: float) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		return
	var tile_size := texture.get_size() * native_scale
	if tile_size.x <= 0.0 or tile_size.y <= 0.0:
		return
	var layer := Node2D.new()
	layer.name = "NativeBackdropLayer%02d" % index
	layer.z_index = -40 + index
	layer.set_meta(&"source_path", path)
	layer.set_meta(&"native_scale", native_scale)
	var coverage := Rect2(
		bounds.position - Vector2(BACKDROP_OVERSCAN_X, BACKDROP_OVERSCAN_Y),
		bounds.size + Vector2(BACKDROP_OVERSCAN_X * 2.0, BACKDROP_OVERSCAN_Y * 2.0)
	)
	layer.set_meta(&"coverage_rect", coverage)
	var first_column := floori(coverage.position.x / tile_size.x)
	var last_column := ceili(coverage.end.x / tile_size.x)
	var bottom := bounds.end.y
	for column: int in range(first_column, last_column + 1):
		var sprite := Sprite2D.new()
		sprite.name = "BackdropTile%02d" % (column - first_column)
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(native_scale, native_scale)
		sprite.position = Vector2((float(column) + 0.5) * tile_size.x, bottom - tile_size.y * 0.5)
		layer.add_child(sprite)
	add_child(layer)


func _build_surface_dressing() -> void:
	var room_id := String(definition.get("id", ""))
	var records: Array = (ROOFTOP_PROP_COMPOSITIONS.get(room_id, []) as Array).duplicate(true)
	if records.is_empty() and definition.has("landmark"):
		records = _landmark_surface_records()
	if records.is_empty():
		return
	var prop_paths := _art_profile.get("prop_paths", []) as Array
	var prop_scales := _art_profile.get("prop_scale", []) as Array
	var platforms := definition.get("platforms", []) as Array
	var dressing := Node2D.new()
	dressing.name = "AuthoredDressing"
	dressing.z_index = -5
	dressing.set_meta(&"district_id", String(definition.get("district_id", "")))
	dressing.set_meta(&"landmark_name", String(definition.get("landmark", "")))
	dressing.set_meta(&"composition_source", "room_surface_composition_v1")
	for record_index: int in range(records.size()):
		var record := records[record_index] as Dictionary
		var platform_index := int(record.get("platform", -1))
		var prop_index := int(record.get("prop", -1))
		if platform_index < 0 or platform_index >= platforms.size() or prop_index < 0 or prop_index >= prop_paths.size():
			continue
		var platform_values := platforms[platform_index] as Array
		if platform_values.size() != 4:
			continue
		var path := String(prop_paths[prop_index])
		if not ResourceLoader.exists(path, "Texture2D"):
			continue
		var texture := load(path) as Texture2D
		var support := Rect2(float(platform_values[0]), float(platform_values[1]), float(platform_values[2]), float(platform_values[3]))
		var requested_scale := float(record.get("scale", prop_scales[prop_index] if prop_index < prop_scales.size() else 1.0))
		var scale_value := _fit_prop_scale(texture.get_size(), requested_scale, support.size.x)
		var visual_size := texture.get_size() * scale_value
		var target_x := support.position.x + support.size.x * clampf(float(record.get("x", 0.5)), 0.0, 1.0)
		if support.size.x >= visual_size.x:
			target_x = clampf(target_x, support.position.x + visual_size.x * 0.5, support.end.x - visual_size.x * 0.5)
		else:
			target_x = support.get_center().x
		var prop := Sprite2D.new()
		prop.name = "SurfaceProp%02d" % (record_index + 1)
		prop.texture = texture
		prop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		prop.scale = Vector2(scale_value, scale_value)
		prop.position = Vector2(target_x, support.position.y - visual_size.y * 0.5)
		prop.flip_h = bool(record.get("flip", false))
		prop.set_meta(&"source_path", path)
		prop.set_meta(&"support_rect", support)
		prop.set_meta(&"surface_bottom", support.position.y)
		prop.set_meta(&"composition_index", record_index)
		dressing.add_child(prop)
	add_child(dressing)


func _landmark_surface_records() -> Array:
	var platforms := definition.get("platforms", []) as Array
	var candidates: Array[int] = []
	for index: int in range(1, platforms.size()):
		var values := platforms[index] as Array
		if values.size() == 4 and float(values[2]) >= 64.0:
			candidates.append(index)
	if candidates.is_empty() and not platforms.is_empty():
		candidates.append(0)
	if candidates.is_empty():
		return []
	var first := candidates[0]
	var last := candidates[candidates.size() - 1]
	return [
		{"platform":first, "prop":0, "x":0.5},
		{"platform":last, "prop":1, "x":0.5, "flip":true},
	]


func _fit_prop_scale(texture_size: Vector2, requested_scale: float, support_width: float) -> float:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return 1.0
	var width_limit := support_width * 0.78 / texture_size.x
	var height_limit := 104.0 / texture_size.y
	return clampf(minf(requested_scale, minf(width_limit, height_limit)), 0.75, 2.5)


func _build_platform(values: Array) -> void:
	if values.size() != 4:
		return
	var rect := Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))
	var platform := TerrainPlatform.new()
	_platform_index += 1
	platform.configure(rect, String(definition.get("region_id", "cyber_city")), String(definition.get("district_id", "")))
	platform.name = "TerrainPlatform%02d" % _platform_index
	add_child(platform)


func _build_hazard(data: Dictionary) -> void:
	var position_values: Array = data.get("position", [0, 0])
	var size_values: Array = data.get("size", [80, 24])
	var hazard_type := String(data.get("type", "electrical_floor"))
	var hazard: Node2D
	match hazard_type:
		"laser_grid": hazard = LaserGrid.new()
		"steam_vent": hazard = SteamVent.new()
		"toxic_pool": hazard = ToxicPool.new()
		"void_pit": hazard = VoidPit.new()
		"crusher": hazard = CrusherHazard.new()
		"falling": hazard = FallingHazard.new()
		"rotating_laser": hazard = RotatingLaser.new()
		"gravity_zone": hazard = GravityZone.new()
		"corruption_zone": hazard = CorruptionZone.new()
		_: hazard = ElectricalFloor.new()
	hazard.position = Vector2(float(position_values[0]), float(position_values[1]))
	if hazard is Hazard:
		var timed_hazard := hazard as Hazard
		timed_hazard.hazard_size = Vector2(float(size_values[0]), float(size_values[1]))
		timed_hazard.active_duration = float(data.get("active", timed_hazard.active_duration))
		timed_hazard.inactive_duration = float(data.get("inactive", timed_hazard.inactive_duration))
		timed_hazard.phase_offset = float(data.get("phase", 0.0))
		timed_hazard.damage = int(data.get("damage", timed_hazard.damage))
		if hazard is CorruptionZone:
			(hazard as CorruptionZone).exposure_per_tick = float(data.get("exposure", (hazard as CorruptionZone).exposure_per_tick))
	elif hazard is GravityZone:
		(hazard as GravityZone).zone_size = Vector2(float(size_values[0]), float(size_values[1]))
		(hazard as GravityZone).gravity_multiplier = float(data.get("gravity", 0.38))
	elif hazard is RotatingLaser:
		(hazard as RotatingLaser).radius = float(data.get("radius", 180.0))
		(hazard as RotatingLaser).rotation_speed = float(data.get("speed", 0.8))
		(hazard as RotatingLaser).clockwise = bool(data.get("clockwise", true))
	elif hazard is CrusherHazard:
		(hazard as CrusherHazard).travel_distance = float(data.get("distance", 260.0))
		(hazard as CrusherHazard).phase_offset = float(data.get("phase", 0.0))
	elif hazard is FallingHazard:
		(hazard as FallingHazard).drop_distance = float(data.get("distance", 320.0))
		(hazard as FallingHazard).phase_offset = float(data.get("phase", 0.0))
	add_child(hazard)


func _build_special_platforms() -> void:
	for value: Variant in definition.get("moving_platforms", []):
		var data := value as Dictionary
		var platform := MovingPlatform.new()
		platform.position = _data_vector(data.get("position", [480, 350]))
		platform.platform_size = _data_vector(data.get("size", [112, 18]))
		platform.speed = float(data.get("speed", 110.0))
		platform.wait_time = float(data.get("wait", 0.25))
		var route := PackedVector2Array()
		for point_value: Variant in data.get("path", [[0, 0], [220, 0]]):
			route.append(_data_vector(point_value))
		platform.path_points = route
		add_child(platform)
	for value: Variant in definition.get("breakaway_platforms", []):
		var data := value as Dictionary
		var platform := BreakawayPlatform.new()
		platform.position = _data_vector(data.get("position", [480, 350]))
		platform.platform_size = _data_vector(data.get("size", [96, 18]))
		platform.collapse_delay = float(data.get("collapse_delay", 0.6))
		platform.reset_delay = float(data.get("reset_delay", 2.5))
		add_child(platform)
	for value: Variant in definition.get("conveyors", []):
		var data := value as Dictionary
		var conveyor := Conveyor.new()
		var conveyor_id := String(data.get("id", ""))
		if not conveyor_id.is_empty():
			conveyor.name = conveyor_id.to_pascal_case()
			conveyor.set_meta(&"mechanic_id", conveyor_id)
		conveyor.position = _data_vector(data.get("position", [480, 480]))
		conveyor.conveyor_size = _data_vector(data.get("size", [180, 22]))
		conveyor.speed = float(data.get("speed", 115.0))
		conveyor.reversible = bool(data.get("reversible", false))
		conveyor.reverse_interval = float(data.get("reverse_interval", 3.0))
		conveyor.hazardous = bool(data.get("hazardous", false))
		add_child(conveyor)


func _build_security_mechanics() -> void:
	var indexed: Dictionary = {}
	for child: Node in get_children():
		if child is Conveyor and child.has_meta(&"mechanic_id"):
			indexed[String(child.get_meta(&"mechanic_id"))] = child
	for value: Variant in definition.get("security_gates", []):
		if value is not Dictionary:
			continue
		var data := value as Dictionary
		var gate_id := String(data.get("id", ""))
		if gate_id.is_empty():
			continue
		var gate := SecurityGate.new()
		gate.name = gate_id.to_pascal_case()
		gate.gate_id = StringName(gate_id)
		gate.position = _data_vector(data.get("position", [480, 350]))
		gate.gate_size = _data_vector(data.get("size", [34, 180]))
		gate.required_switches = maxi(int(data.get("required_switches", 1)), 1)
		gate.timed_open_duration = maxf(float(data.get("timed_open_duration", 0.0)), 0.0)
		gate.persistence = String(data.get("persistence", "save"))
		add_child(gate)
		indexed[gate_id] = gate
	for value: Variant in definition.get("terminals", []):
		if value is not Dictionary:
			continue
		var data := value as Dictionary
		var terminal_id := String(data.get("id", ""))
		if terminal_id.is_empty():
			continue
		var terminal := InteractiveTerminal.new()
		terminal.name = terminal_id.to_pascal_case()
		terminal.terminal_id = StringName(terminal_id)
		terminal.position = _data_vector(data.get("position", [480, 420]))
		terminal.interaction_kind = String(data.get("kind", "switch"))
		terminal.persistence = String(data.get("persistence", "save"))
		terminal.lore_text = String(data.get("text", ""))
		add_child(terminal)
		indexed[terminal_id] = terminal
		for target_value: Variant in data.get("targets", []):
			var target_id := String(target_value)
			var target := indexed.get(target_id) as Node
			if target == null:
				push_error("Room %s terminal %s references missing target %s." % [definition.get("id", "?"), terminal_id, target_id])
				continue
			terminal.link_target(target)


func _data_vector(value: Variant) -> Vector2:
	if value is Vector2:
		return value as Vector2
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float((value as Array)[0]), float((value as Array)[1]))
	return Vector2.ZERO


func _build_services() -> void:
	for service_value: Variant in definition.get("services", []):
		var data := service_value as Dictionary
		if String(data.get("type", "")) == "npc":
			var npc := DialogueNPC.new()
			npc.configure(data)
			add_child(npc)
		else:
			var station := ServiceStation.new()
			station.configure(data)
			add_child(station)


func _build_story_triggers() -> void:
	var triggers: Array = definition.get("story_triggers", [])
	if definition.has("story_beat"):
		triggers = triggers.duplicate(true)
		triggers.append({"sequence_id": String(definition.story_beat)})
	for trigger_value: Variant in triggers:
		if trigger_value is Dictionary:
			var trigger := StoryTrigger.new()
			trigger.configure(trigger_value as Dictionary, bounds)
			add_child(trigger)


func _build_enemies() -> void:
	for enemy_value: Variant in definition.get("enemies", []):
		if enemy_value is not Dictionary:
			continue
		var data := enemy_value as Dictionary
		var enemy := ENEMY_SCENE.instantiate() as EnemyBase
		var values: Array = data.get("position", [480, 450])
		enemy.position = Vector2(float(values[0]), float(values[1]))
		enemy.enemy_id = StringName(data.get("enemy_id", "goblin"))
		enemy.archetype = StringName(data.get("archetype", "ground_chaser"))
		enemy.max_health = int(data.get("health", 2))
		enemy.patrol_distance = float(data.get("patrol_distance", 120))
		enemy.detection_radius = float(data.get("detection_radius", 190))
		enemy.initial_state = EnemyBase.State.PATROL
		add_child(enemy)


func _build_encounters() -> void:
	var registry := get_node_or_null("/root/AssetRegistry")
	var act_by_region := {"cyber_city":1, "robot_factory":2, "neon_moon":3, "abyssal_night":4}
	var act_number := int(act_by_region.get(String(definition.get("region_id", "cyber_city")), 1))
	for encounter_value: Variant in definition.get("encounters", []):
		if encounter_value is not Dictionary:
			continue
		var data := encounter_value as Dictionary
		var activation_values: Array = data.get("activation", [0, 0, 960, 540])
		if activation_values.size() != 4:
			continue
		var activation := Rect2(float(activation_values[0]), float(activation_values[1]), float(activation_values[2]), float(activation_values[3]))
		var waves: Array = []
		for wave_value: Variant in data.get("waves", []):
			if wave_value is not Array:
				continue
			var wave: Array[Dictionary] = []
			for record_value: Variant in wave_value as Array:
				if record_value is not Dictionary:
					continue
				var record := (record_value as Dictionary).duplicate(true)
				var position_values: Array = record.get("position", [activation.get_center().x, activation.get_center().y])
				if position_values.size() == 2:
					record["position"] = Vector2(float(position_values[0]), float(position_values[1]))
				wave.append(record)
			waves.append(wave)
		var encounter := EncounterController.new()
		encounter.configure_blueprint(
			StringName(data.get("id", "%s_encounter" % name)),
			activation,
			waves,
			self,
			registry,
			bool(data.get("lock_arena", true)),
			act_number,
			bool(data.get("persistent", true)),
		)
		add_child(encounter)


func _build_boss() -> void:
	if not definition.has("boss"):
		return
	var data := definition.boss as Dictionary
	var boss_id := StringName(data.get("id", ""))
	var manager := get_node_or_null("/root/GameManager")
	if manager != null and manager.world_progress.defeated_bosses.has(String(boss_id)):
		return
	var scene_path := String(data.get("scene", ""))
	var packed := load(scene_path) as PackedScene if ResourceLoader.exists(scene_path, "PackedScene") else null
	if packed == null:
		push_error("World room %s could not load boss scene %s." % [name, scene_path])
		return
	var boss := packed.instantiate() as BossBase
	if boss == null:
		return
	boss.position = _data_vector(data.get("position", [620, 430]))
	add_child(boss)
	var arena_values: Array = data.get("arena", [180, 80, 660, 420])
	if arena_values.size() == 4:
		var arena_bounds := Rect2(float(arena_values[0]), float(arena_values[1]), float(arena_values[2]), float(arena_values[3]))
		var player := get_tree().get_first_node_in_group(&"player") as CharacterBody2D
		var camera := player.get_node_or_null("Camera2D") as DynamicCamera if player != null else null
		var arena := BossArenaController.new()
		arena.configure(arena_bounds, boss, camera)
		add_child(arena)
	var completion_flag := StringName(data.get("completion_flag", ""))
	var reward_ability := StringName(data.get("reward_ability", ""))
	boss.boss_defeated.connect(func() -> void:
		if manager != null:
			manager.world_progress.defeated_bosses[String(boss_id)] = true
			if not completion_flag.is_empty():
				manager.call(&"set_story_flag", completion_flag, true, false)
			if not reward_ability.is_empty():
				manager.call(&"grant_ability", reward_ability)
	)


func _build_tutorial() -> void:
	var tutorial_id := String(definition.get("tutorial", ""))
	if tutorial_id.is_empty():
		return
	var panel := PanelContainer.new()
	panel.name = "TutorialPrompt"
	# The HUD objective occupies the design-space band through y=132. Keep
	# tutorial guidance below it so both remain legible at the 960x540 base
	# viewport and every stretched window mode.
	panel.position = Vector2(170, 142)
	panel.custom_minimum_size = Vector2(620, 46)
	add_child(panel)
	_tutorial_label = Label.new()
	_tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_label.add_theme_color_override("font_color", Color("8ff5ff"))
	panel.add_child(_tutorial_label)
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null:
		for signal_name: StringName in [&"input_device_changed", &"action_binding_changed"]:
			var callback := Callable(self, &"_refresh_tutorial")
			if settings.has_signal(signal_name) and not settings.is_connected(signal_name, callback):
				settings.connect(signal_name, callback)
	_refresh_tutorial()


func _refresh_tutorial(_unused: Variant = null) -> void:
	if _tutorial_label == null:
		return
	var tutorial_id := String(definition.get("tutorial", ""))
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		_tutorial_label.text = tutorial_id.to_upper()
		return
	var family := StringName(settings.call(&"get_active_input_family"))
	var move := "LEFT STICK" if family == &"controller" else "%s / %s" % [_action_prompt(&"ui_left"), _action_prompt(&"ui_right")]
	var messages := {
		"movement": "MOVE  %s  •  JUMP  %s  •  DASH  %s" % [move, _action_prompt(&"ui_accept"), _action_prompt(&"slide_dash")],
		"teleport": "HOLD %s TO AIM  •  RELEASE TO THROW  •  PRESS AGAIN TO PHASE  •  %s RECALLS" % [_action_prompt(&"teleport"), _action_prompt(&"teleport_cancel")],
		"combat": "ATTACK  %s  •  TECHNIQUE  %s" % [_action_prompt(&"attack_melee"), _action_prompt(&"attack_shoot")],
	}
	_tutorial_label.text = String(messages.get(tutorial_id, tutorial_id.to_upper()))


func _action_prompt(action: StringName) -> String:
	var settings := get_node_or_null("/root/SettingsManager")
	return String(settings.call(&"get_action_prompt", action)) if settings != null else "UNBOUND"
