class_name StageMechanicFactory
extends RefCounted


static func install(stage: StageBase, blueprint: Dictionary) -> Array[Node]:
	var installed: Array[Node] = []
	var container := stage.get_mechanics_container()
	_clear_container(container)
	var environment_id := _environment_id_for_stage(stage)
	for traversal_value: Variant in blueprint.get("traversal", []):
		var section := AuthoredTraversal.new()
		section.configure(traversal_value as Dictionary, environment_id)
		container.add_child(section)
	var indexed_nodes := {}
	for entry_value: Variant in blueprint.get("mechanics", []):
		var entry := entry_value as Dictionary
		var node := _create_mechanic(stage, entry)
		if node == null:
			push_error("Stage %s has unsupported mechanic '%s'." % [blueprint.get("stage_id", "?"), entry.get("kind", "")])
			continue
		var stable_id := String(entry.get("id", entry.get("kind", "mechanic")))
		node.name = stable_id.to_pascal_case()
		if node is Node2D:
			(node as Node2D).position = entry.get("position", Vector2.ZERO)
		container.add_child(node)
		indexed_nodes[stable_id] = node
		installed.append(node)
	_link_targets(blueprint.get("mechanics", []), indexed_nodes)
	return installed


static func _create_mechanic(stage: StageBase, entry: Dictionary) -> Node:
	var kind := String(entry.get("kind", ""))
	match kind:
		"moving_platform":
			var platform := MovingPlatform.new()
			platform.path_points = PackedVector2Array(entry.get("points", [Vector2.ZERO, Vector2(220, 0)]))
			platform.path_mode = MovingPlatform.PathMode.LOOP if bool(entry.get("loop", false)) else MovingPlatform.PathMode.PING_PONG
			platform.speed = float(entry.get("speed", 110.0))
			platform.wait_time = float(entry.get("wait", 0.25))
			platform.phase_offset = float(entry.get("phase", 0.0))
			platform.presentation_id = StringName(entry.get("presentation", ""))
			return platform
		"breakaway_platform":
			var platform := BreakawayPlatform.new()
			platform.collapse_delay = float(entry.get("collapse", 0.6))
			return platform
		"conveyor":
			var conveyor := Conveyor.new()
			conveyor.conveyor_size = entry.get("size", Vector2(260, 24))
			conveyor.speed = float(entry.get("speed", 115.0))
			conveyor.reversible = bool(entry.get("reversible", false))
			conveyor.reverse_interval = float(entry.get("interval", 3.0))
			conveyor.hazardous = bool(entry.get("hazard", false))
			return conveyor
		"gravity_zone":
			var zone := GravityZone.new()
			zone.zone_size = entry.get("size", Vector2(520, 400))
			zone.gravity_multiplier = float(entry.get("gravity", 0.38))
			return zone
		"camera_zone":
			var zone := CameraZone.new()
			zone.zone_size = entry.get("size", Vector2(900, 900))
			zone.vertical_offset = float(entry.get("offset_y", -170.0))
			return zone
		"visibility_zone":
			var zone := VisibilityZone.new()
			zone.zone_size = entry.get("size", Vector2(900, 500))
			return zone
		"turret":
			var turret := SecurityTurret.new()
			turret.security_id = StringName(entry.get("id", "turret"))
			turret.fire_mode = _turret_mode(String(entry.get("mode", "tracking")))
			turret.destructible = bool(entry.get("destructible", true))
			turret.starts_enabled = bool(entry.get("enabled", true))
			turret.set_target(stage.get_player() as Node2D)
			return turret
		"security_gate":
			var gate := SecurityGate.new()
			gate.gate_id = StringName(entry.get("id", "security_gate"))
			gate.required_switches = int(entry.get("required_switches", 1))
			gate.timed_open_duration = float(entry.get("timed", 0.0))
			gate.persistence = String(entry.get("persistence", "encounter"))
			return gate
		"terminal", "switch", "lore_terminal":
			var terminal := InteractiveTerminal.new()
			terminal.terminal_id = StringName(entry.get("id", "terminal"))
			terminal.interaction_kind = "lore" if kind == "lore_terminal" else ("switch" if kind == "switch" else "terminal")
			terminal.persistence = String(entry.get("persistence", "encounter"))
			terminal.lore_text = String(entry.get("text", ""))
			return terminal
		"destructible_switch":
			var node := DestructibleSwitch.new()
			node.switch_id = StringName(entry.get("id", "destructible_switch"))
			node.max_health = int(entry.get("health", 3))
			return node
		"laser_grid": return _configure_hazard(LaserGrid.new(), entry)
		"steam_vent": return _configure_hazard(SteamVent.new(), entry)
		"electrical_floor": return _configure_hazard(ElectricalFloor.new(), entry)
		"toxic_pool": return _configure_hazard(ToxicPool.new(), entry)
		"void_pit": return _configure_hazard(VoidPit.new(), entry)
		"heat_zone", "corruption_zone":
			var hazard := Hazard.new()
			hazard.hazard_id = StringName(kind)
			hazard.affects_enemies = false
			return _configure_hazard(hazard, entry)
		"falling_object":
			var hazard := FallingHazard.new()
			hazard.drop_distance = float(entry.get("drop", 320.0))
			hazard.phase_offset = float(entry.get("phase", 0.0))
			return hazard
		"crusher":
			var hazard := CrusherHazard.new()
			hazard.travel_distance = float(entry.get("travel", 260.0))
			hazard.phase_offset = float(entry.get("phase", 0.0))
			return hazard
		"rotating_laser":
			var laser := RotatingLaser.new()
			laser.radius = float(entry.get("radius", 180.0))
			laser.clockwise = bool(entry.get("clockwise", true))
			laser.starts_enabled = bool(entry.get("enabled", true))
			return laser
		"tutorial":
			var label := Label.new()
			label.text = String(entry.get("text", "MOVE • JUMP • MELEE • SHOOT • DASH"))
			label.add_theme_color_override("font_color", Color("9df6ff"))
			label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
			label.add_theme_constant_override("shadow_offset_x", 2)
			label.add_theme_constant_override("shadow_offset_y", 2)
			return label
		_:
			return null


static func _configure_hazard(hazard: Hazard, entry: Dictionary) -> Hazard:
	hazard.hazard_size = entry.get("size", Vector2(96, 76))
	hazard.damage = int(entry.get("damage", hazard.damage))
	hazard.active_duration = float(entry.get("active", hazard.active_duration))
	hazard.inactive_duration = float(entry.get("inactive", hazard.inactive_duration))
	hazard.phase_offset = float(entry.get("phase", 0.0))
	return hazard


static func _turret_mode(mode: String) -> SecurityTurret.FireMode:
	match mode:
		"burst": return SecurityTurret.FireMode.BURST
		"rotating_laser": return SecurityTurret.FireMode.ROTATING_LASER
		_: return SecurityTurret.FireMode.TRACKING


static func _link_targets(entries: Array, indexed_nodes: Dictionary) -> void:
	for entry_value: Variant in entries:
		var entry := entry_value as Dictionary
		var source := indexed_nodes.get(String(entry.get("id", ""))) as Node
		if source == null or not source.has_method(&"link_target"):
			continue
		for target_id: Variant in entry.get("targets", []):
			var target := indexed_nodes.get(String(target_id)) as Node
			if target == null:
				push_error("Mechanic '%s' references missing target '%s'." % [entry.get("id", ""), target_id])
				continue
			source.call(&"link_target", target)


static func _clear_container(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


static func _environment_id_for_stage(stage: StageBase) -> StringName:
	match stage.stage_act:
		2: return &"robot_factory"
		3: return &"neon_moon"
		4: return &"abyssal_night"
		_: return &"cyber_city"
