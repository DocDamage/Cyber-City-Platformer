extends RefCounted


static func get_blueprint(stage_id: String) -> Dictionary:
	match stage_id:
		"4-1": return _corrupted_outpost()
		"4-2": return _dark_chasm()
		"4-3": return _biomechanical_nest()
		"4-4": return _abyssal_sanctuary()
		"4-5": return _heart_of_void()
		_: return {}


static func _corrupted_outpost() -> Dictionary:
	return {
		"stage_id": "4-1",
		"traversal": [
			{"id": "ruined_entry", "kind": "hazard_steps", "position": Vector2(900, 410), "optional": false},
			{"id": "corrupt_rooftops", "kind": "moving_platform_route", "position": Vector2(2900, 390), "optional": false},
		],
		"mechanics": [
			{"id": "corruption_a", "kind": "toxic_pool", "position": Vector2(1100, 470), "size": Vector2(420, 90), "damage": 2},
			{"id": "corruption_b", "kind": "corruption_zone", "position": Vector2(2650, 300), "size": Vector2(480, 260), "damage": 1},
			{"id": "outpost_lift", "kind": "moving_platform", "position": Vector2(3300, 390), "points": [Vector2.ZERO, Vector2(220, -160), Vector2(480, 0)], "loop": true},
		],
		"encounters": [
			_encounter("elite_outpost", Rect2(500, 0, 1450, 540), [[_enemy("death_knight", 1100, 414, true), _enemy("werewolf", 1600, 414, false)]]),
			_encounter("corrupted_guard", Rect2(2750, 0, 1450, 540), [[_enemy("demon_boss", 3300, 414, true), _enemy("death_knight", 3850, 414, false)]]),
		],
		"collectibles": [Vector2(1250, 260), Vector2(2700, 170), Vector2(3600, 170)],
	}


static func _dark_chasm() -> Dictionary:
	return {
		"stage_id": "4-2",
		"traversal": [
			{"id": "void_floats", "kind": "moving_platform_route", "position": Vector2(900, 390), "optional": false},
			{"id": "blind_dash", "kind": "dash_gap", "position": Vector2(3100, 410), "optional": false},
		],
		"mechanics": [
			{"id": "chasm_pit_a", "kind": "void_pit", "position": Vector2(1200, 490), "size": Vector2(560, 120)},
			{"id": "chasm_float_a", "kind": "moving_platform", "position": Vector2(1050, 360), "points": [Vector2.ZERO, Vector2(320, -190), Vector2(640, -20)], "loop": true, "wait": 0.2},
			{"id": "chasm_pit_b", "kind": "void_pit", "position": Vector2(3000, 490), "size": Vector2(720, 120)},
			{"id": "chasm_float_b", "kind": "moving_platform", "position": Vector2(2850, 350), "points": [Vector2.ZERO, Vector2(280, -230), Vector2(650, -40)], "loop": true, "wait": 0.15},
			{"id": "visibility_field", "kind": "visibility_zone", "position": Vector2(2350, 240), "size": Vector2(1200, 560)},
			{"id": "mastery_prompt", "kind": "tutorial", "position": Vector2(3100, 250), "text": "DASH, THEN WALL-JUMP"},
		],
		"encounters": [
			_encounter("chasm_fliers", Rect2(500, 0, 1450, 540), [[_enemy("gargoyle", 1050, 220), _enemy("harpy", 1650, 270)]]),
			_encounter("blind_hunt", Rect2(2750, 0, 1450, 540), [[_enemy("headless_horseman", 3300, 414), _enemy("harpy", 3820, 230)]]),
		],
		"collectibles": [Vector2(1320, 130), Vector2(2500, 230), Vector2(3600, 120)],
	}


static func _biomechanical_nest() -> Dictionary:
	return {
		"stage_id": "4-3",
		"traversal": [
			{"id": "organic_spines", "kind": "hazard_steps", "position": Vector2(950, 410), "optional": false},
			{"id": "nest_bypass", "kind": "high_route", "position": Vector2(3000, 380), "optional": false},
		],
		"mechanics": [
			{"id": "organic_crusher_a", "kind": "crusher", "position": Vector2(1050, 140), "travel": 270.0, "phase": 0.2},
			{"id": "organic_crusher_b", "kind": "crusher", "position": Vector2(1650, 100), "travel": 310.0, "phase": 1.0},
			{"id": "nest_gate", "kind": "security_gate", "position": Vector2(3650, 330), "required_switches": 2, "persistence": "checkpoint"},
			{"id": "corruption_node_a", "kind": "destructible_switch", "position": Vector2(2750, 360), "targets": ["nest_gate"], "health": 3},
			{"id": "corruption_node_b", "kind": "destructible_switch", "position": Vector2(3250, 240), "targets": ["nest_gate"], "health": 3},
		],
		"encounters": [
			_encounter("nest_ambush", Rect2(500, 0, 1450, 540), [[_enemy("mimic", 950, 414), _enemy("cerberus", 1550, 414)], [_enemy("mimic", 1300, 414), _enemy("witch", 1800, 414)]]),
			_encounter("node_guardians", Rect2(2650, 0, 1500, 540), [[_enemy("cerberus", 3150, 414), _enemy("witch", 3800, 414)]]),
		],
		"collectibles": [Vector2(1250, 230), Vector2(2850, 180), Vector2(3420, 120)],
	}


static func _abyssal_sanctuary() -> Dictionary:
	return {
		"stage_id": "4-4",
		"traversal": [
			{"id": "mastery_floor", "kind": "conveyor_route", "position": Vector2(900, 410), "optional": false},
			{"id": "mastery_air", "kind": "moving_platform_route", "position": Vector2(3000, 380), "optional": false},
		],
		"mechanics": [
			{"id": "sanctuary_belt", "kind": "conveyor", "position": Vector2(900, 424), "size": Vector2(600, 24), "speed": -175.0, "hazard": true},
			{"id": "sanctuary_laser", "kind": "laser_grid", "position": Vector2(1850, 290), "size": Vector2(42, 280), "active": 1.2, "inactive": 0.8},
			{"id": "sanctuary_gravity", "kind": "gravity_zone", "position": Vector2(2550, 220), "size": Vector2(700, 440), "gravity": -0.38},
			{"id": "sanctuary_platform", "kind": "moving_platform", "position": Vector2(3200, 370), "points": [Vector2.ZERO, Vector2(260, -220), Vector2(600, 0)], "loop": true},
			{"id": "sanctuary_spinner", "kind": "rotating_laser", "position": Vector2(3900, 170), "radius": 190.0, "clockwise": false},
		],
		"encounters": [
			_encounter("mastery_elites_a", Rect2(500, 0, 1500, 540), [[_enemy("stone_golem", 1100, 414, true), _enemy("poison_skull", 1600, 210, false)]]),
			_encounter("mastery_elites_b", Rect2(2700, 0, 1450, 540), [[_enemy("death_knight", 3200, 414, true), _enemy("poison_skull", 3750, 190, false)], [_enemy("stone_golem", 3950, 414, true), _enemy("death_knight", 4100, 414, false)]]),
		],
		"collectibles": [Vector2(1300, 250), Vector2(2750, 130), Vector2(3650, 100)],
	}


static func _heart_of_void() -> Dictionary:
	return {
		"stage_id": "4-5",
		"boss_arena": {"bounds": Rect2(3420, 30, 950, 510), "intro_id": "void_cerberus", "checkpoint_save": true, "completion_cinematic": true},
		"mechanics": [
			{"id": "arena_corruption_left", "kind": "corruption_zone", "position": Vector2(3570, 430), "size": Vector2(230, 100), "active": 1.0, "inactive": 1.5},
			{"id": "arena_corruption_right", "kind": "corruption_zone", "position": Vector2(4220, 430), "size": Vector2(230, 100), "active": 1.0, "inactive": 1.5, "phase": 0.8},
			{"id": "void_breath_axis", "kind": "rotating_laser", "position": Vector2(3900, 180), "radius": 310.0, "enabled": false},
		],
		"collectibles": [Vector2(1300, 300), Vector2(2400, 250), Vector2(3200, 310)],
	}


static func _enemy(enemy_id: String, x: float, y: float, elite := false) -> Dictionary:
	return {"enemy": enemy_id, "position": Vector2(x, y), "elite": elite}


static func _encounter(id: String, activation: Rect2, waves: Array) -> Dictionary:
	return {"id": id, "activation": activation, "waves": waves, "lock_arena": true}
