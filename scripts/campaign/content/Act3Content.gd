extends RefCounted


static func get_blueprint(stage_id: String) -> Dictionary:
	match stage_id:
		"3-1": return _lunar_surface()
		"3-2": return _cleanrooms()
		"3-3": return _security_shaft()
		"3-4": return _biotech_labs()
		"3-5": return _orbital_command()
		_: return {}


static func _lunar_surface() -> Dictionary:
	return {
		"stage_id": "3-1",
		"traversal": [
			{"id": "low_g_school", "kind": "low_gravity_gap", "position": Vector2(850, 410), "optional": false},
			{"id": "crater_crossing", "kind": "long_gap", "position": Vector2(2850, 410), "optional": false},
		],
		"mechanics": [
			{"id": "lunar_low_g", "kind": "gravity_zone", "position": Vector2(1600, 230), "size": Vector2(2700, 500), "gravity": 0.38},
			{"id": "zero_g_cave", "kind": "gravity_zone", "position": Vector2(3450, 220), "size": Vector2(620, 430), "gravity": 0.0},
		],
		"encounters": [
			_encounter("crater_fliers", Rect2(500, 0, 1400, 540), [[_enemy("harpy", 1050, 260), _enemy("poison_skull", 1500, 190)]]),
			_encounter("zero_g_predators", Rect2(2800, -20, 1350, 560), [[_enemy("gargoyle", 3250, 220), _enemy("poison_skull", 3770, 150)]]),
		],
		"collectibles": [Vector2(1120, 170), Vector2(2540, 190), Vector2(3650, 80)],
	}


static func _cleanrooms() -> Dictionary:
	return {
		"stage_id": "3-2",
		"traversal": [
			{"id": "airlock_cycle", "kind": "hazard_steps", "position": Vector2(900, 410), "optional": false},
			{"id": "observation_route", "kind": "high_route", "position": Vector2(2850, 390), "optional": true},
		],
		"mechanics": [
			{"id": "cleanroom_gate", "kind": "security_gate", "position": Vector2(2050, 330), "persistence": "checkpoint"},
			{"id": "cleanroom_terminal", "kind": "terminal", "position": Vector2(1450, 370), "targets": ["cleanroom_gate"], "persistence": "checkpoint"},
			{"id": "clean_laser_a", "kind": "laser_grid", "position": Vector2(2700, 300), "size": Vector2(42, 260), "active": 1.0, "inactive": 1.5},
			{"id": "clean_laser_b", "kind": "laser_grid", "position": Vector2(3250, 300), "size": Vector2(42, 260), "phase": 0.75},
			{"id": "lore_terminal", "kind": "lore_terminal", "position": Vector2(3700, 370), "text": "ORACLE LOG: GRAVITY ARRAY UNSTABLE", "optional": true},
		],
		"encounters": [
			_encounter("airlock_ranged", Rect2(500, 0, 1450, 540), [[_enemy("satyr_archer", 1050, 414), _enemy("witch", 1600, 414)]]),
			_encounter("observation_defense", Rect2(2700, 0, 1400, 540), [[_enemy("flying_eye", 3150, 260), _enemy("witch", 3750, 414)]]),
		],
		"collectibles": [Vector2(1200, 300), Vector2(2880, 180), Vector2(3880, 290)],
	}


static func _security_shaft() -> Dictionary:
	return {
		"stage_id": "3-3",
		"traversal": [
			{"id": "security_shaft", "kind": "wall_jump_shaft", "position": Vector2(1100, 390), "height": 600.0, "optional": false},
			{"id": "orbital_lift", "kind": "vertical_route", "position": Vector2(3000, 380), "optional": false},
		],
		"mechanics": [
			{"id": "shaft_turret", "kind": "turret", "position": Vector2(1500, 150), "mode": "tracking", "destructible": true},
			{"id": "burst_turret", "kind": "turret", "position": Vector2(2650, 190), "mode": "burst", "destructible": false},
			{"id": "security_spinner", "kind": "rotating_laser", "position": Vector2(3300, 130), "radius": 210.0},
			{"id": "shaft_low_g", "kind": "gravity_zone", "position": Vector2(2250, 0), "size": Vector2(800, 880), "gravity": 0.42},
			{"id": "shaft_camera", "kind": "camera_zone", "position": Vector2(2600, 0), "size": Vector2(1100, 1100)},
		],
		"encounters": [
			_encounter("shaft_entry", Rect2(450, -500, 1450, 1040), [[_enemy("poison_skull", 1050, 110), _enemy("gryphon", 1520, 40)]]),
			_encounter("grid_crown", Rect2(2750, -500, 1400, 1040), [[_enemy("gryphon", 3200, 80), _enemy("skeleton_warrior", 3800, 414)]]),
		],
		"collectibles": [Vector2(1100, -90), Vector2(2450, -220), Vector2(3600, 40)],
	}


static func _biotech_labs() -> Dictionary:
	return {
		"stage_id": "3-4",
		"traversal": [
			{"id": "gravity_switchback", "kind": "low_gravity_gap", "position": Vector2(950, 410), "optional": false},
			{"id": "containment_bypass", "kind": "high_route", "position": Vector2(3000, 390), "optional": false},
		],
		"mechanics": [
			{"id": "heavy_g_lab", "kind": "gravity_zone", "position": Vector2(900, 250), "size": Vector2(650, 430), "gravity": 1.7},
			{"id": "inverse_lab", "kind": "gravity_zone", "position": Vector2(1850, 220), "size": Vector2(620, 430), "gravity": -0.45},
			{"id": "containment_pool", "kind": "toxic_pool", "position": Vector2(2700, 470), "size": Vector2(500, 90)},
			{"id": "bioshield_gate", "kind": "security_gate", "position": Vector2(3850, 330), "required_switches": 2, "persistence": "checkpoint"},
			{"id": "bio_switch_a", "kind": "switch", "position": Vector2(3100, 360), "targets": ["bioshield_gate"], "persistence": "checkpoint"},
			{"id": "bio_switch_b", "kind": "switch", "position": Vector2(3500, 230), "targets": ["bioshield_gate"], "persistence": "checkpoint"},
		],
		"encounters": [
			_encounter("specimen_ambush", Rect2(500, 0, 1450, 540), [[_enemy("mimic", 1000, 414), _enemy("medusa", 1600, 414)]]),
			_encounter("containment_breach", Rect2(2650, 0, 1500, 540), [[_enemy("mimic", 3100, 414), _enemy("demon_boss", 3750, 414)], [_enemy("medusa", 3450, 414), _enemy("mimic", 3970, 414)]]),
		],
		"collectibles": [Vector2(1300, 230), Vector2(2800, 210), Vector2(3560, 140)],
	}


static func _orbital_command() -> Dictionary:
	return {
		"stage_id": "3-5",
		"boss_arena": {"bounds": Rect2(3450, 20, 900, 520), "intro_id": "lunar_oracle", "checkpoint_save": true},
		"mechanics": [
			{"id": "oracle_gravity", "kind": "gravity_zone", "position": Vector2(3900, 230), "size": Vector2(760, 470), "gravity": 0.65},
			{"id": "oracle_laser", "kind": "rotating_laser", "position": Vector2(3900, 180), "radius": 285.0, "enabled": false},
		],
		"collectibles": [Vector2(1300, 300), Vector2(2400, 250), Vector2(3230, 320)],
	}


static func _enemy(enemy_id: String, x: float, y: float) -> Dictionary:
	return {"enemy": enemy_id, "position": Vector2(x, y)}


static func _encounter(id: String, activation: Rect2, waves: Array) -> Dictionary:
	return {"id": id, "activation": activation, "waves": waves, "lock_arena": true}
