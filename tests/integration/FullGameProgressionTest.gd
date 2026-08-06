extends SceneTree

const FAMILIES: Array[StringName] = [&"sword", &"dagger", &"spear", &"heavy", &"bow", &"staff"]
const EXPECTED_DISTRICTS := 20
const EXPECTED_BOSSES := 4
const EXPECTED_CRITICAL_ROOMS := 162


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(15.0, true, false, true).timeout.connect(func() -> void:
		push_error("Full-game progression test timed out.")
		quit(1)
	)
	var validation := WorldDatabase.validate()
	if not _require(validation.is_empty(), "Full-game world graph is invalid: %s" % validation):
		return
	var rooms := WorldDatabase.rooms()
	var route := _critical_route(rooms)
	if not _require(route.front() == WorldProgress.START_ROOM and route.back() == "void_heart_exit" and route.size() == EXPECTED_CRITICAL_ROOMS, "Critical route does not span the complete game (%d rooms)." % route.size()):
		return
	var districts: Dictionary = {}
	var boss_ids: Dictionary = {}
	var story_beats := 0
	for room_id: String in route:
		var room := rooms[room_id] as Dictionary
		districts[String(room.get("district_id", ""))] = true
		if room.has("boss"):
			boss_ids[String((room.boss as Dictionary).get("id", ""))] = true
		if room.has("story_beat") or room.has("story_triggers"):
			story_beats += 1
	if not _require(districts.size() == EXPECTED_DISTRICTS and boss_ids.size() == EXPECTED_BOSSES and story_beats >= 20, "Critical route does not cover all districts, bosses, and story milestones."):
		return

	var game := root.get_node("GameManager")
	var registry := root.get_node("AssetRegistry")
	for family: StringName in FAMILIES:
		game.call(&"new_game")
		var profile := CharacterProfile.new()
		profile.character_name = "%s Runner" % String(family).capitalize()
		profile.pronoun_set_id = &"they_them"
		profile.starting_weapon_family = family
		profile.creation_complete = true
		if not _require(game.call(&"commit_character_profile", profile), "Starting family %s could not initialize a valid character." % family):
			return
		if not _require(game.equipment.weapon_family_id == family and not game.equipment.main_weapon_id.is_empty(), "Starting family %s did not equip its production weapon." % family):
			return
		if not _require(not WeaponCatalog.attack_profile(family, false, 0).is_empty() and not WeaponCatalog.attack_profile(family, true, 0).is_empty() and not WeaponCatalog.technique_profile(family).is_empty(), "Starting family %s lacks ground, air, or technique combat data." % family):
			return
		if not _require(_simulate_progression(route, rooms, game, registry), "Starting family %s cannot satisfy the complete critical-route progression contract." % family):
			return
		var ending_line := PronounResolver.resolve("{player_name} returned; the city remembers {object}.", profile)
		if not _require(profile.character_name in ending_line and "them" in ending_line, "Ending personalization failed for starting family %s." % family):
			return
		profile = null

	print("FULL_GAME_PROGRESSION_TEST_OK families=6 critical_rooms=", route.size(), " districts=", districts.size(), " bosses=", boss_ids.size())
	CreatorAnimationCatalog.clear_runtime_cache()
	quit()


func _critical_route(rooms: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var indexed: Dictionary = {}
	for room_id: String in rooms:
		var room := rooms[room_id] as Dictionary
		if bool((room.get("pacing", {}) as Dictionary).get("optional", false)):
			continue
		indexed[int(room.get("critical_path_index", -1))] = room_id
	for index: int in range(indexed.size()):
		if indexed.has(index):
			result.append(String(indexed[index]))
	return result


func _simulate_progression(route: Array[String], rooms: Dictionary, game: Node, registry: Node) -> bool:
	var abilities: Dictionary = {"basic_teleport":true}
	var defeated: Dictionary = {}
	for index: int in range(route.size()):
		var room := rooms[route[index]] as Dictionary
		if room.has("ability_reward"):
			abilities[String((room.ability_reward as Dictionary).get("ability", ""))] = true
		for encounter_value: Variant in room.get("encounters", []):
			for wave_value: Variant in (encounter_value as Dictionary).get("waves", []):
				for enemy_value: Variant in wave_value as Array:
					var enemy_id := String((enemy_value as Dictionary).get("enemy", ""))
					if registry.call(&"get_enemy_scene", StringName(enemy_id)) == null:
						return false
		if room.has("boss"):
			var boss := room.boss as Dictionary
			var boss_id := String(boss.get("id", ""))
			if not ResourceLoader.exists(String(boss.get("scene", "")), "PackedScene"):
				return false
			defeated[boss_id] = true
			var reward_ability := String(boss.get("reward_ability", ""))
			if not reward_ability.is_empty():
				abilities[reward_ability] = true
		if index >= route.size() - 1:
			continue
		var target_id := route[index + 1]
		var found_connection := false
		for connection_value: Variant in room.get("connections", []):
			var connection := connection_value as Dictionary
			if String(connection.get("target_room", "")) != target_id:
				continue
			found_connection = true
			var required := String(connection.get("required_ability", ""))
			if not required.is_empty() and not abilities.has(required):
				return false
			break
		if not found_connection:
			return false
	return defeated.size() == EXPECTED_BOSSES and abilities.has("magnetic_rail") and abilities.has("phase_barrier") and abilities.has("heavy_ground_break") and abilities.has("gravity_anchor") and abilities.has("chain_teleport") and abilities.has("corruption_resistance") and abilities.has("energy_field")


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
