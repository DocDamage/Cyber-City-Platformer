extends RefCounted


static func get_blueprint(stage_id: String) -> Dictionary:
	match stage_id:
		"2-1": return _sublevel_intake()
		"2-2": return _conveyor_assembly()
		"2-3": return _smelting_core()
		"2-4": return _robotic_maintenance()
		"2-5": return _assembly_engine()
		_: return {}


static func _sublevel_intake() -> Dictionary:
	return {
		"stage_id": "2-1",
		"traversal": [
			{"id": "safe_belt", "kind": "conveyor_route", "architecture": "intake_conveyors", "position": Vector2(290, 385), "optional": false},
			{"id": "steam_timing", "kind": "hazard_steps", "architecture": "forge_laser_walk", "position": Vector2(790, 270), "optional": false},
		],
		"mechanics": [
			{"id": "intake_belt", "kind": "conveyor", "position": Vector2(390, 424), "size": Vector2(290, 24), "speed": 90.0},
			{"id": "steam_a", "kind": "steam_vent", "position": Vector2(760, 405), "active": 0.8, "inactive": 1.6},
			{"id": "steam_b", "kind": "steam_vent", "position": Vector2(1030, 405), "active": 1.0, "inactive": 1.35, "phase": 0.7},
		],
		"encounters": [
			_encounter("armored_intake", Rect2(270, 100, 410, 430), [[_enemy("stone_golem", 520, 414), _enemy("goblin", 630, 414)]]),
			_encounter("steam_crossfire", Rect2(780, 100, 430, 430), [[_enemy("stone_golem", 950, 414), _enemy("pyromancer", 1120, 414)]]),
		],
		"collectibles": [Vector2(340, 345), Vector2(540, 315), Vector2(760, 300), Vector2(1010, 300), Vector2(1190, 330)],
	}


static func _conveyor_assembly() -> Dictionary:
	return {
		"stage_id": "2-2",
		"traversal": [
			{"id": "reversal_lane", "kind": "conveyor_route", "architecture": "reversal_conveyors", "position": Vector2(850, 420), "optional": false},
			{"id": "cargo_lift", "kind": "moving_platform_route", "architecture": "cargo_transfer", "position": Vector2(2800, 390), "optional": false},
		],
		"mechanics": [
			{"id": "reverse_belt_a", "kind": "conveyor", "position": Vector2(900, 424), "size": Vector2(500, 24), "speed": 145.0, "reversible": true, "interval": 2.5},
			{"id": "hazard_belt", "kind": "conveyor", "position": Vector2(2050, 424), "size": Vector2(560, 24), "speed": -170.0, "hazard": true},
			{"id": "cargo_platform", "kind": "moving_platform", "position": Vector2(2860, 390), "points": [Vector2.ZERO, Vector2(260, -180), Vector2(560, -40)], "loop": true, "wait": 0.25, "presentation": "factory_cargo_lift"},
			{"id": "falling_part_a", "kind": "falling_object", "position": Vector2(3420, 140), "drop": 310.0, "phase": 0.0},
			{"id": "falling_part_b", "kind": "falling_object", "position": Vector2(3710, 80), "drop": 370.0, "phase": 0.8},
		],
		"encounters": [
			_encounter("belt_arena", Rect2(650, 0, 1300, 540), [[_enemy("cyclops", 1050, 414), _enemy("satyr_archer", 1550, 414)], [_enemy("imp", 1320, 300), _enemy("cyclops", 1740, 414)]]),
			_encounter("cargo_waves", Rect2(2750, 0, 1400, 540), [[_enemy("imp", 3150, 290), _enemy("satyr_archer", 3570, 414)], [_enemy("cyclops", 3820, 414), _enemy("imp", 3980, 280)]]),
		],
		"collectibles": [Vector2(1250, 310), Vector2(3040, 170), Vector2(3890, 220)],
	}


static func _smelting_core() -> Dictionary:
	return {
		"stage_id": "2-3",
		"traversal": [
			{"id": "furnace_climb", "kind": "vertical_route", "architecture": "furnace_gantry", "position": Vector2(1100, 390), "optional": false},
			{"id": "laser_forge", "kind": "hazard_steps", "architecture": "forge_laser_walk", "position": Vector2(3050, 390), "optional": false},
		],
		"mechanics": [
			{"id": "smelter_pool", "kind": "toxic_pool", "position": Vector2(1050, 470), "size": Vector2(520, 90)},
			{"id": "heat_chamber", "kind": "heat_zone", "position": Vector2(1800, 300), "size": Vector2(520, 300)},
			{"id": "forge_steam", "kind": "steam_vent", "position": Vector2(2500, 405), "active": 1.2, "inactive": 1.0},
			{"id": "laser_gate_a", "kind": "laser_grid", "position": Vector2(3160, 300), "size": Vector2(42, 260), "active": 1.25, "inactive": 1.1},
			{"id": "laser_gate_b", "kind": "laser_grid", "position": Vector2(3610, 280), "size": Vector2(42, 300), "phase": 0.75},
		],
		"encounters": [
			_encounter("furnace_guard", Rect2(500, -350, 1450, 890), [[_enemy("stone_golem", 1150, 410), _enemy("pyromancer", 1650, 410)]]),
			_encounter("smelting_airspace", Rect2(2750, -450, 1400, 990), [[_enemy("pyromancer", 3200, 410), _enemy("flying_eye", 3650, 180)]]),
		],
		"collectibles": [Vector2(1150, 40), Vector2(2300, 250), Vector2(3720, 90)],
	}


static func _robotic_maintenance() -> Dictionary:
	return {
		"stage_id": "2-4",
		"traversal": [
			{"id": "crusher_hall", "kind": "hazard_steps", "architecture": "crusher_bay", "position": Vector2(1200, 410), "optional": false},
			{"id": "repair_bypass", "kind": "high_route", "architecture": "maintenance_bypass", "position": Vector2(2720, 370), "optional": true},
		],
		"mechanics": [
			{"id": "crusher_a", "kind": "crusher", "position": Vector2(1000, 160), "travel": 245.0, "phase": 0.0},
			{"id": "crusher_b", "kind": "crusher", "position": Vector2(1450, 120), "travel": 285.0, "phase": 0.9},
			{"id": "repair_gate", "kind": "security_gate", "position": Vector2(3200, 330), "persistence": "checkpoint"},
			{"id": "repair_terminal", "kind": "terminal", "position": Vector2(2520, 370), "targets": ["repair_gate"], "persistence": "checkpoint", "optional": true},
		],
		"encounters": [
			_encounter("maintenance_floor", Rect2(500, 0, 1300, 540), [[_enemy("minotaur", 1050, 414), _enemy("satyr_archer", 1580, 414)]]),
			_encounter("repair_crossfire", Rect2(2650, 0, 1450, 540), [[_enemy("minotaur", 3200, 414), _enemy("witch", 3700, 414)]]),
		],
		"collectibles": [Vector2(1350, 280), Vector2(2660, 190), Vector2(3780, 300)],
	}


static func _assembly_engine() -> Dictionary:
	return {
		"stage_id": "2-5",
		"boss_arena": {"bounds": Rect2(3450, 80, 900, 470), "intro_id": "assembly_colossus", "checkpoint_save": true},
		"mechanics": [
			{"id": "arena_belt", "kind": "conveyor", "position": Vector2(3900, 430), "size": Vector2(760, 24), "speed": 110.0, "reversible": true, "interval": 4.0},
			{"id": "machinery_terminal", "kind": "terminal", "position": Vector2(3600, 370), "persistence": "encounter"},
		],
		"collectibles": [Vector2(1250, 320), Vector2(2350, 260), Vector2(3200, 330)],
	}


static func _enemy(enemy_id: String, x: float, y: float) -> Dictionary:
	return {"enemy": enemy_id, "position": Vector2(x, y)}


static func _encounter(id: String, activation: Rect2, waves: Array) -> Dictionary:
	return {"id": id, "activation": activation, "waves": waves, "lock_arena": true}
