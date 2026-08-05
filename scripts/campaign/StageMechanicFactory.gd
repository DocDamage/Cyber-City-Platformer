class_name StageMechanicFactory
extends RefCounted


static func install(stage: StageBase, metadata: Dictionary) -> Array[Node]:
	var installed: Array[Node] = []
	var container := Node2D.new()
	container.name = "RuntimeMechanics"
	stage.add_child(container)
	var mechanics: Array = metadata.get("mechanics", [])
	var bounds: Array = metadata.get("camera_bounds", [0, 0, 1408, 540])
	var left := float(bounds[0])
	var right := float(bounds[2])
	var floor_y := _floor_y(stage)
	var gate: SecurityGate
	if mechanics.has("security_gate"):
		gate = SecurityGate.new()
		gate.position = Vector2(lerpf(left, right, 0.78), floor_y - 90.0)
		container.add_child(gate)
		installed.append(gate)
	for index in range(mechanics.size()):
		var mechanic := String(mechanics[index])
		var x := lerpf(left + 180.0, right - 180.0, float(index + 1) / float(mechanics.size() + 1))
		var node := _create_mechanic(mechanic, Vector2(x, floor_y), gate)
		if node != null:
			container.add_child(node)
			installed.append(node)
	if mechanics.has("elite_enemy"):
		_apply_elite_variant(stage)
	return installed


static func _create_mechanic(mechanic: String, position: Vector2, gate: SecurityGate) -> Node:
	var node: Node2D
	match mechanic:
		"moving_platform":
			var platform := MovingPlatform.new()
			platform.motion_offset = Vector2(0.0, -150.0)
			node = platform
		"breakaway_platform": node = BreakawayPlatform.new()
		"conveyor", "reversible_conveyor":
			var conveyor := Conveyor.new()
			conveyor.reversible = mechanic == "reversible_conveyor"
			node = conveyor
		"low_gravity", "gravity_zone":
			var gravity_zone := GravityZone.new()
			gravity_zone.gravity_multiplier = -0.45 if mechanic == "gravity_zone" else 0.38
			gravity_zone.position = position - Vector2(0.0, 160.0)
			return gravity_zone
		"turret":
			node = SecurityTurret.new()
			position.y -= 110.0
		"terminal", "multi_switch", "corruption_node":
			var terminal := InteractiveTerminal.new()
			terminal.linked_gate = gate
			node = terminal
			position.y -= 46.0
		"electric_sign", "signal_hazard", "steam_vent", "heat_zone", "laser_grid", "rotating_laser", "crusher", "drop_hazard", "void_pit", "corruption_zone", "laser_sweep":
			var hazard := Hazard.new()
			hazard.hazard_id = StringName(mechanic)
			hazard.hazard_size = Vector2(96.0, 76.0)
			hazard.instant_kill = mechanic in ["void_pit", "crusher"]
			hazard.active_duration = 1.1
			hazard.inactive_duration = 1.25
			node = hazard
			position.y -= 38.0
		"tutorial":
			var label := Label.new()
			label.text = "MOVE  •  JUMP  •  Z MELEE  •  X SHOOT  •  C DASH"
			label.position = position - Vector2(180.0, 120.0)
			return label
		_:
			return null
	node.position = position
	return node


static func _floor_y(stage: StageBase) -> float:
	var player := stage.get_player() as Node2D
	return player.global_position.y + 24.0 if player != null else 432.0


static func _apply_elite_variant(stage: StageBase) -> void:
	for node: Node in stage.get_tree().get_nodes_in_group(&"enemies"):
		if stage.is_ancestor_of(node) and node is EnemyBase:
			var enemy := node as EnemyBase
			enemy.max_health *= 2
			enemy.health = enemy.max_health
			enemy.sprite.modulate = Color(1.0, 0.35, 0.85)
			return
