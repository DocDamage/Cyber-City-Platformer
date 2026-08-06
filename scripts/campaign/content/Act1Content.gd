extends RefCounted


static func get_blueprint(stage_id: String) -> Dictionary:
	match stage_id:
		"1-1": return _rooftop_alley()
		"1-2": return _billboard_highway()
		"1-3": return _communication_spire()
		"1-4": return _skybridge_junction()
		"1-5": return _executive_helipad()
		_: return {}


static func _rooftop_alley() -> Dictionary:
	return {
		"stage_id": "1-1",
		"traversal": [
			{"id": "jump_school", "kind": "jump_steps", "architecture": "rooftop_steps", "position": Vector2(300, 418), "optional": false},
			{"id": "wall_school", "kind": "wall_jump_shaft", "architecture": "service_shaft", "position": Vector2(700, 410), "optional": false},
			{"id": "pickup_roof", "kind": "high_route", "architecture": "billboard_bypass", "position": Vector2(1010, 390), "optional": true},
		],
		"mechanics": [
			{"id": "move_prompt", "kind": "tutorial", "position": Vector2(160, 325), "text": "MOVE  A/D or LEFT STICK"},
			{"id": "jump_prompt", "kind": "tutorial", "position": Vector2(330, 300), "text": "JUMP  SPACE / A"},
			{"id": "wall_prompt", "kind": "tutorial", "position": Vector2(665, 260), "text": "HOLD TOWARD WALL + JUMP"},
			{"id": "combat_prompt", "kind": "tutorial", "position": Vector2(875, 310), "text": "MELEE Z/X  •  SHOOT X/B"},
		],
		"encounters": [
			_encounter("melee_intro", Rect2(360, 120, 300, 410), [[_enemy("goblin", 465, 412), _enemy("goblin", 565, 412)]]),
			_encounter("ranged_intro", Rect2(850, 100, 350, 430), [[_enemy("satyr_archer", 1010, 412), _enemy("flying_eye", 1120, 320)]]),
		],
		"collectibles": [Vector2(330, 350), Vector2(620, 250), Vector2(850, 330), Vector2(1020, 225), Vector2(1160, 330)],
	}


static func _billboard_highway() -> Dictionary:
	return {
		"stage_id": "1-2",
		"traversal": [
			{"id": "billboard_run", "kind": "moving_platform_route", "architecture": "billboard_lifts", "position": Vector2(760, 420), "optional": false},
			{"id": "highway_gap", "kind": "dash_gap", "architecture": "broken_skybridge", "position": Vector2(2850, 418), "optional": false},
			{"id": "high_billboards", "kind": "high_route", "architecture": "billboard_bypass", "position": Vector2(1900, 360), "optional": true},
		],
		"mechanics": [
			{"id": "billboard_lift_a", "kind": "moving_platform", "position": Vector2(850, 370), "points": [Vector2.ZERO, Vector2(260, -125), Vector2(520, 0)], "loop": true, "wait": 0.35, "presentation": "city_elevator"},
			{"id": "billboard_lift_b", "kind": "moving_platform", "position": Vector2(2200, 350), "points": [Vector2.ZERO, Vector2(0, -180)], "wait": 0.55, "presentation": "city_elevator"},
			{"id": "electric_sign_a", "kind": "electrical_floor", "position": Vector2(1500, 402), "size": Vector2(170, 50), "active": 1.0, "inactive": 1.35},
			{"id": "electric_sign_b", "kind": "electrical_floor", "position": Vector2(3500, 402), "size": Vector2(210, 50), "phase": 0.8},
		],
		"encounters": [
			_encounter("billboard_ambush", Rect2(980, 40, 900, 500), [[_enemy("centaur", 1260, 420), _enemy("satyr_archer", 1670, 420)]]),
			_encounter("highway_crossfire", Rect2(3000, 20, 1050, 520), [[_enemy("harpy", 3300, 300), _enemy("satyr_archer", 3750, 420)]]),
		],
		"collectibles": [Vector2(1080, 280), Vector2(2010, 190), Vector2(3650, 300)],
	}


static func _communication_spire() -> Dictionary:
	return {
		"stage_id": "1-3",
		"traversal": [
			{"id": "antenna_shaft", "kind": "wall_jump_shaft", "architecture": "antenna_shaft", "position": Vector2(980, 400), "height": 520.0, "optional": false},
			{"id": "dish_ascent", "kind": "vertical_route", "architecture": "spire_ascent", "position": Vector2(2740, 380), "optional": false},
		],
		"mechanics": [
			{"id": "signal_spinner_a", "kind": "rotating_laser", "position": Vector2(1550, 210), "radius": 150.0},
			{"id": "signal_spinner_b", "kind": "rotating_laser", "position": Vector2(3320, 120), "radius": 190.0, "clockwise": false},
			{"id": "spire_lift", "kind": "moving_platform", "position": Vector2(2450, 370), "points": [Vector2.ZERO, Vector2(0, -350)], "wait": 0.45, "presentation": "spire_carriage"},
			{"id": "vertical_camera", "kind": "camera_zone", "position": Vector2(2450, 40), "size": Vector2(900, 1040)},
		],
		"encounters": [
			_encounter("lower_airspace", Rect2(450, -320, 1100, 860), [[_enemy("flying_eye", 900, 220), _enemy("gargoyle", 1280, 100)]]),
			_encounter("spire_crown", Rect2(2700, -500, 1300, 1040), [[_enemy("gargoyle", 3060, 40), _enemy("satyr_archer", 3600, 405)]]),
		],
		"collectibles": [Vector2(1030, 10), Vector2(2600, -210), Vector2(3550, 120)],
	}


static func _skybridge_junction() -> Dictionary:
	return {
		"stage_id": "1-4",
		"traversal": [
			{"id": "moving_bridge", "kind": "moving_platform_route", "architecture": "skybridge_carriage", "position": Vector2(900, 420), "optional": false},
			{"id": "dash_bridge", "kind": "dash_gap", "architecture": "broken_skybridge", "position": Vector2(3000, 420), "optional": false},
		],
		"mechanics": [
			{"id": "bridge_carriage", "kind": "moving_platform", "position": Vector2(1050, 390), "points": [Vector2.ZERO, Vector2(380, 0)], "wait": 0.25, "presentation": "skybridge_carriage"},
			{"id": "bridge_segment_a", "kind": "breakaway_platform", "position": Vector2(2100, 390), "collapse": 0.7},
			{"id": "bridge_segment_b", "kind": "breakaway_platform", "position": Vector2(2250, 390), "collapse": 0.45},
			{"id": "dash_prompt", "kind": "tutorial", "position": Vector2(2920, 310), "text": "DASH  SHIFT / RIGHT TRIGGER"},
		],
		"encounters": [
			_encounter("junction_mix", Rect2(800, 0, 1200, 540), [[_enemy("werewolf", 1250, 420), _enemy("harpy", 1660, 280)]]),
			_encounter("preboss_gauntlet", Rect2(3000, 0, 1250, 540), [[_enemy("skeleton_warrior", 3350, 420), _enemy("harpy", 3720, 270)], [_enemy("werewolf", 3900, 420), _enemy("skeleton_warrior", 4080, 420)]]),
		],
		"collectibles": [Vector2(1450, 260), Vector2(2340, 280), Vector2(3670, 190)],
	}


static func _executive_helipad() -> Dictionary:
	return {
		"stage_id": "1-5",
		"boss_arena": {"bounds": Rect2(3500, 80, 850, 470), "intro_id": "helix_warden", "checkpoint_save": true},
		"mechanics": [
			{"id": "helipad_airflow", "kind": "gravity_zone", "position": Vector2(3860, 255), "size": Vector2(700, 370), "gravity": 0.72},
			{"id": "helipad_edge_left", "kind": "void_pit", "position": Vector2(3440, 485), "size": Vector2(100, 80)},
			{"id": "helipad_edge_right", "kind": "void_pit", "position": Vector2(4400, 485), "size": Vector2(100, 80)},
		],
		"collectibles": [Vector2(1250, 320), Vector2(2380, 270), Vector2(3240, 330)],
	}


static func _enemy(enemy_id: String, x: float, y: float) -> Dictionary:
	return {"enemy": enemy_id, "position": Vector2(x, y)}


static func _encounter(id: String, activation: Rect2, waves: Array) -> Dictionary:
	return {"id": id, "activation": activation, "waves": waves, "lock_arena": true}
