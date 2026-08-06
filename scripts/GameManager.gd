extends Node

signal player_health_changed(current: int, maximum: int)
signal player_energy_changed(current: float, maximum: float)
signal score_changed(total: int)
signal checkpoint_changed(checkpoint_id: StringName, position: Vector2)
signal level_transition_started(scene_path: String)
signal level_transition_finished(scene_path: String)
signal stage_completed(stage_id: String)
signal upgrade_acquired(upgrade_id: StringName, level: int)
signal campaign_completed
signal character_profile_changed(profile: CharacterProfile)
signal inventory_changed(item_id: StringName, amount: int)
signal equipment_changed(slot_id: StringName, item_id: String)
signal ability_unlocked(ability_id: StringName, level: int)
signal locked_barrier_discovered(barrier_id: String, room_id: String, required_ability: StringName)
signal world_progress_changed(room_id: String)
signal story_flag_changed(flag_id: StringName, value: Variant)
signal quest_changed(quest_id: StringName, state: Dictionary)

const FIRST_STAGE_SCENE := "res://Stages/Act1_CyberCity/1-1_RooftopAlley/Stage.tscn"
const TITLE_SCENE := "res://scenes/ui/TitleScreen.tscn"
const ENDING_SCENE := "res://scenes/ui/EndingScreen.tscn"
const SAVE_SLOT_SCENE := "res://scenes/ui/SaveSlotScreen.tscn"
const CHARACTER_CREATOR_SCENE := "res://scenes/ui/CharacterCreator.tscn"
const WORLD_SCENE := "res://scenes/world/WorldRoot.tscn"

var run_state := RunState.new()
var campaign_progress := CampaignProgress.new()
var character_profile := CharacterProfile.new()
var inventory := InventoryState.new()
var equipment := EquipmentState.new()
var abilities := AbilityState.new()
var world_progress := WorldProgress.new()
var story_flags: Dictionary = {}
var quest_states: Dictionary = {}
var seen_cutscenes: Dictionary = {}
var pending_save_slot_mode: StringName = &"new_game"
var _respawning := false
var _transitioning := false

var player_health: int:
	get: return run_state.player_health
	set(value): run_state.player_health = value
var player_max_health: int:
	get: return run_state.player_max_health
	set(value): run_state.player_max_health = value
var player_energy: float:
	get: return run_state.player_energy
	set(value): run_state.player_energy = value
var player_max_energy: float:
	get: return run_state.player_max_energy
	set(value): run_state.player_max_energy = value
var current_score: int:
	get: return run_state.score
	set(value): run_state.score = value
var active_checkpoint_position: Vector2:
	get: return run_state.checkpoint_position
	set(value): run_state.checkpoint_position = value
var current_checkpoint: Vector2:
	get: return run_state.checkpoint_position
	set(value): run_state.checkpoint_position = value
var current_checkpoint_id: StringName:
	get: return run_state.checkpoint_id
	set(value): run_state.checkpoint_id = value
var current_checkpoint_scene: String:
	get: return run_state.checkpoint_scene
	set(value): run_state.checkpoint_scene = value
var checkpoint_locations: Dictionary:
	get: return run_state.checkpoint_locations
var collected_pickups: Dictionary:
	get: return run_state.collected_pickups
var stage_flags: Dictionary:
	get: return run_state.stage_flags


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not get_tree().paused:
		run_state.elapsed_seconds += delta
		campaign_progress.total_play_time += delta


func register_player(player: Node, maximum_health: int, maximum_energy: float, level_scene_path: String, default_spawn: Vector2) -> void:
	var health_bonus := int(run_state.upgrades.get("max_health", 0))
	var energy_bonus := float(run_state.upgrades.get("max_energy", 0)) * 10.0
	player_max_health = maximum_health + health_bonus
	player_max_energy = maximum_energy + energy_bonus
	if player_health < 0:
		player_health = player_max_health
	else:
		player_health = clampi(player_health, 1, player_max_health)
	if player_energy < 0.0:
		player_energy = player_max_energy
	else:
		player_energy = clampf(player_energy, 0.0, player_max_energy)

	if current_checkpoint_scene != level_scene_path:
		current_checkpoint_scene = level_scene_path
		current_checkpoint_id = &"level_start"
		current_checkpoint = default_spawn
	run_state.stage_scene = level_scene_path

	if player is Node2D and current_checkpoint_scene == level_scene_path:
		(player as Node2D).global_position = active_checkpoint_position
	player_health_changed.emit(player_health, player_max_health)
	player_energy_changed.emit(player_energy, player_max_energy)
	score_changed.emit(current_score)


func set_player_health(value: int, maximum := player_max_health) -> void:
	player_max_health = maxi(maximum, 1)
	player_health = clampi(value, 0, player_max_health)
	player_health_changed.emit(player_health, player_max_health)


func set_player_energy(value: float, maximum := player_max_energy) -> void:
	player_max_energy = maxf(maximum, 1.0)
	player_energy = clampf(value, 0.0, player_max_energy)
	player_energy_changed.emit(player_energy, player_max_energy)


func add_score(amount: int) -> void:
	if amount <= 0:
		return
	current_score += amount
	score_changed.emit(current_score)


func collect_pickup(level_scene_path: String, pickup_id: StringName, value: int) -> bool:
	var key := "%s::%s" % [level_scene_path, pickup_id]
	if collected_pickups.has(key):
		return false
	collected_pickups[key] = true
	add_score(value)
	return true


func is_pickup_collected(level_scene_path: String, pickup_id: StringName) -> bool:
	return collected_pickups.has("%s::%s" % [level_scene_path, pickup_id])


func set_stage_flag(level_scene_path: String, flag_id: StringName, value := true, autosave := false) -> void:
	if level_scene_path.is_empty() or flag_id.is_empty():
		return
	stage_flags["%s::%s" % [level_scene_path, flag_id]] = value
	if autosave:
		_request_autosave()


func get_stage_flag(level_scene_path: String, flag_id: StringName, default_value: Variant = false) -> Variant:
	return stage_flags.get("%s::%s" % [level_scene_path, flag_id], default_value)


func activate_checkpoint(checkpoint_id: StringName, position: Vector2, level_scene_path: String) -> void:
	current_checkpoint_id = checkpoint_id
	active_checkpoint_position = position
	current_checkpoint_scene = level_scene_path
	checkpoint_locations["%s::%s" % [level_scene_path, checkpoint_id]] = position
	checkpoint_changed.emit(checkpoint_id, position)
	_request_autosave()


func request_respawn(player: Node) -> void:
	if _respawning or not is_instance_valid(player):
		return
	_respawning = true
	_respawn_after_delay(player)


func _respawn_after_delay(player: Node) -> void:
	await get_tree().create_timer(0.65, true, false, true).timeout
	if is_instance_valid(player) and player.has_method(&"respawn_at"):
		player.call(&"respawn_at", active_checkpoint_position)
	_respawning = false


func change_level(scene_path: String) -> void:
	if _transitioning or scene_path.is_empty() or not ResourceLoader.exists(scene_path, "PackedScene"):
		return
	_transitioning = true
	level_transition_started.emit(scene_path)
	_change_level_deferred(scene_path)


func complete_stage(stage_id: String) -> void:
	if stage_id.is_empty() or campaign_progress.completed_stages.has(stage_id):
		return
	campaign_progress.complete_stage(stage_id, current_score, run_state.elapsed_seconds)
	stage_completed.emit(stage_id)
	_request_autosave()


func enter_stage(stage_id: String, scene_path: String) -> void:
	run_state.stage_id = stage_id
	run_state.stage_scene = scene_path


func mark_boss_defeated(boss_id: StringName) -> void:
	if boss_id.is_empty():
		return
	run_state.defeated_bosses[String(boss_id)] = true
	campaign_progress.defeated_bosses[String(boss_id)] = true
	world_progress.defeated_bosses[String(boss_id)] = true
	world_progress_changed.emit(world_progress.current_room_id)
	_request_autosave()


func award_upgrade(upgrade_id: StringName, amount := 1) -> bool:
	var key := String(upgrade_id)
	if not run_state.upgrades.has(key) or amount <= 0:
		return false
	run_state.upgrades[key] = int(run_state.upgrades[key]) + amount
	upgrade_acquired.emit(upgrade_id, int(run_state.upgrades[key]))
	_request_autosave()
	return true


func get_upgrade_level(upgrade_id: StringName) -> int:
	return int(run_state.upgrades.get(String(upgrade_id), 0))


func advance_stage() -> void:
	if _transitioning:
		return
	var current_stage := get_tree().current_scene as StageBase
	if current_stage == null:
		push_error("GameManager cannot advance a scene that does not extend StageBase.")
		return
	complete_stage("%d-%d" % [current_stage.stage_act, current_stage.stage_sub])
	var registry := get_node_or_null("/root/AssetRegistry")
	if registry == null:
		push_error("GameManager requires AssetRegistry to advance the campaign.")
		return
	var next_act := current_stage.stage_act
	var next_sub := current_stage.stage_sub + 1
	var next_stage: Dictionary = registry.call(&"get_stage_info", next_act, next_sub)
	if next_stage.is_empty():
		next_act += 1
		next_sub = 1
		next_stage = registry.call(&"get_stage_info", next_act, next_sub)
	if next_stage.is_empty():
		_finish_campaign()
		return
	run_state.stage_id = "%d-%d" % [next_act, next_sub]
	change_level(String(next_stage.get("scene", "")))


func new_game() -> void:
	run_state.clear()
	campaign_progress.clear()
	character_profile = CharacterProfile.new()
	inventory.clear()
	equipment.clear(character_profile.starting_weapon_family)
	abilities.clear()
	world_progress.clear()
	story_flags.clear()
	quest_states = QuestDatabase.initial_states()
	seen_cutscenes.clear()
	_respawning = false
	_transitioning = false
	score_changed.emit(0)


func start_new_game() -> void:
	new_game()
	get_tree().paused = false
	change_level(FIRST_STAGE_SCENE)


func open_save_slots(mode: StringName) -> void:
	pending_save_slot_mode = mode if mode in [&"new_game", &"load"] else &"load"
	change_level(SAVE_SLOT_SCENE)


func start_character_creation(slot_id: int) -> bool:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.call(&"set_active_slot", slot_id):
		return false
	save_manager.call(&"reset_save", slot_id)
	new_game()
	change_level(CHARACTER_CREATOR_SCENE)
	return true


func start_created_game(profile: CharacterProfile) -> bool:
	if not commit_character_profile(profile):
		return false
	run_state.stage_id = "mv-world"
	run_state.stage_scene = WORLD_SCENE
	world_progress.clear()
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and not save_manager.call(&"save_game"):
		return false
	get_tree().paused = false
	change_level(WORLD_SCENE)
	return true


func complete_metroidvania() -> void:
	set_story_flag(&"game_complete", true, false)
	_finish_campaign()


func return_to_title() -> void:
	get_tree().paused = false
	_transitioning = false
	change_level(TITLE_SCENE)


func start_stage_select(stage_id: String) -> bool:
	if not campaign_progress.campaign_complete:
		return false
	var registry := get_node_or_null("/root/AssetRegistry")
	var act := stage_id.get_slice("-", 0).to_int()
	var substage := stage_id.get_slice("-", 1).to_int()
	var metadata: Dictionary = registry.call(&"get_stage_info", act, substage) if registry != null else {}
	var scene_path := String(metadata.get("scene", ""))
	if scene_path.is_empty():
		return false
	run_state.player_health = -1
	run_state.player_energy = -1.0
	run_state.score = 0
	run_state.checkpoint_id = &""
	run_state.checkpoint_scene = ""
	run_state.checkpoint_position = Vector2.ZERO
	run_state.stage_id = stage_id
	run_state.stage_scene = scene_path
	get_tree().paused = false
	change_level(scene_path)
	return true


func reset_run() -> void:
	run_state.clear()
	_respawning = false
	_transitioning = false
	score_changed.emit(0)


func get_save_data() -> Dictionary:
	return {
		"character_profile": character_profile.to_dict(),
		"player_stats": run_state.to_dict(),
		"inventory": inventory.to_dict(),
		"equipment": equipment.to_dict(),
		"abilities": abilities.to_dict(),
		"world_progress": world_progress.to_dict(),
		"story_flags": story_flags.duplicate(true),
		"quest_states": quest_states.duplicate(true),
		"seen_cutscenes": seen_cutscenes.duplicate(true),
		"play_time": campaign_progress.total_play_time,
		# Compatibility mirrors keep the preserved linear debug campaign and its
		# established test/build tooling usable during the metroidvania conversion.
		"run_state": run_state.to_dict(),
		"campaign_progress": campaign_progress.to_dict(),
	}


func get_save_summary() -> Dictionary:
	return {
		"character_name": character_profile.character_name,
		"portrait_id": character_profile.portrait_id,
		"pronoun_set_id": String(character_profile.pronoun_set_id),
		"voice_profile_id": character_profile.voice_profile_id,
		"appearance": character_profile.appearance.to_dict(),
		"play_time": campaign_progress.total_play_time,
		"region_id": world_progress.current_region_id,
		"district_id": world_progress.current_district_id,
		"room_id": world_progress.current_room_id,
		"map_completion": world_progress.map_completion(WorldDatabase.room_count()),
		"equipped_weapon_id": equipment.main_weapon_id,
		"weapon_family_id": String(equipment.weapon_family_id),
	}


func restore_save_data(data: Dictionary) -> bool:
	var run_data: Variant = data.get("player_stats", data.get("run_state", {}))
	if not run_state.load_dict(run_data):
		return false
	if not campaign_progress.load_dict(data.get("campaign_progress", {})):
		return false
	character_profile = CharacterProfile.new()
	character_profile.load_dict(data.get("character_profile", {}))
	inventory = InventoryState.new()
	inventory.load_dict(data.get("inventory", {}))
	equipment = EquipmentState.new()
	equipment.load_dict(data.get("equipment", {}))
	abilities = AbilityState.new()
	abilities.load_dict(data.get("abilities", {}))
	world_progress = WorldProgress.new()
	world_progress.load_dict(data.get("world_progress", {}))
	story_flags = _dictionary_copy(data.get("story_flags", {}))
	quest_states = QuestDatabase.reconcile(data.get("quest_states", {}), _quest_snapshot())
	seen_cutscenes = _dictionary_copy(data.get("seen_cutscenes", {}))
	return true


func commit_character_profile(profile: CharacterProfile) -> bool:
	if profile == null:
		return false
	var candidate := profile.duplicate_profile()
	candidate.sanitize()
	if not candidate.is_valid(true):
		return false
	character_profile = candidate
	equipment.clear(character_profile.starting_weapon_family)
	inventory.add_item(StringName(equipment.main_weapon_id), 1, true)
	character_profile_changed.emit(character_profile.duplicate_profile())
	return true


func commit_cosmetic_profile(profile: CharacterProfile) -> bool:
	if profile == null:
		return false
	var candidate := profile.duplicate_profile()
	candidate.starting_weapon_family = equipment.weapon_family_id
	candidate.creation_complete = character_profile.creation_complete
	candidate.sanitize()
	if not candidate.is_valid(character_profile.creation_complete):
		return false
	character_profile = candidate
	character_profile_changed.emit(character_profile.duplicate_profile())
	_request_autosave()
	return true


func add_inventory_item(item_id: StringName, amount := 1, unique := false) -> bool:
	if not inventory.add_item(item_id, amount, unique):
		return false
	inventory_changed.emit(item_id, inventory.count(item_id))
	_refresh_quests()
	_request_autosave()
	return true


func equip_main_weapon(item_id: String, family_id: StringName) -> bool:
	if not equipment.equip_weapon(item_id, family_id, inventory):
		return false
	character_profile.starting_weapon_family = family_id
	equipment_changed.emit(&"main_weapon", item_id)
	character_profile_changed.emit(character_profile.duplicate_profile())
	_request_autosave()
	return true


func grant_ability(ability_id: StringName, amount := 1) -> bool:
	if not abilities.grant(ability_id, amount):
		return false
	ability_unlocked.emit(ability_id, int(abilities.levels[String(ability_id)]))
	_refresh_quests()
	_request_autosave()
	return true


func activate_warp_node(warp_node_id: String) -> bool:
	if not world_progress.activate_warp(warp_node_id):
		return false
	_refresh_quests()
	world_progress_changed.emit(world_progress.current_room_id)
	_request_autosave()
	return true


func discover_locked_barrier(barrier_id: String, room_id: String, required_ability: StringName) -> bool:
	if not world_progress.discover_locked_barrier(barrier_id, room_id, required_ability):
		return false
	locked_barrier_discovered.emit(barrier_id, room_id, required_ability)
	world_progress_changed.emit(world_progress.current_room_id)
	_request_autosave()
	return true


func enter_world_room(region_id: String, district_id: String, room_id: String, spawn_connection: String) -> bool:
	if region_id.is_empty() or district_id.is_empty() or room_id.is_empty():
		return false
	world_progress.current_region_id = region_id
	world_progress.current_district_id = district_id
	world_progress.current_room_id = room_id
	world_progress.spawn_connection_id = spawn_connection
	world_progress.discover_room(room_id)
	world_progress_changed.emit(room_id)
	return true


func set_story_flag(flag_id: StringName, value: Variant = true, autosave := true) -> void:
	if flag_id.is_empty():
		return
	story_flags[String(flag_id)] = value
	story_flag_changed.emit(flag_id, value)
	_refresh_quests()
	if autosave:
		_request_autosave()


func has_story_flag(flag_id: StringName) -> bool:
	return bool(story_flags.get(String(flag_id), false))


func current_quest_objective() -> Dictionary:
	return QuestDatabase.current_objective(quest_states)


func quest_journal_entries() -> Array[Dictionary]:
	return QuestDatabase.journal_entries(quest_states)


func _refresh_quests() -> void:
	var previous := QuestDatabase.normalize_states(quest_states)
	var reconciled := QuestDatabase.reconcile(previous, _quest_snapshot())
	quest_states = reconciled
	for quest_id: String in reconciled:
		var previous_state: Dictionary = previous.get(quest_id, {})
		var current_state: Dictionary = reconciled[quest_id]
		if previous_state != current_state:
			quest_changed.emit(StringName(quest_id), current_state.duplicate(true))


func _quest_snapshot() -> Dictionary:
	var item_flags := inventory.unique_items.duplicate(true)
	for item_id: String in inventory.stacks:
		if int(inventory.stacks[item_id]) > 0:
			item_flags[item_id] = true
	var ability_flags: Dictionary = {}
	for ability_id: String in abilities.levels:
		if int(abilities.levels[ability_id]) > 0:
			ability_flags[ability_id] = true
	return {
		"story_flag": story_flags.duplicate(true),
		"item": item_flags,
		"ability": ability_flags,
		"warp": world_progress.activated_warp_nodes.duplicate(true),
	}


func _dictionary_copy(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _change_level_deferred(scene_path: String) -> void:
	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method(&"fade_out"):
		await transition.call(&"fade_out")
	else:
		await get_tree().process_frame
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("GameManager could not change scene to %s (error %s)." % [scene_path, error])
		_transitioning = false
		return
	run_state.stage_scene = scene_path
	await get_tree().process_frame
	if transition != null and transition.has_method(&"fade_in"):
		await transition.call(&"fade_in")
	_transitioning = false
	level_transition_finished.emit(scene_path)


func _finish_campaign() -> void:
	if campaign_progress.campaign_complete:
		return
	campaign_progress.campaign_complete = true
	campaign_completed.emit()
	_request_autosave()
	change_level(ENDING_SCENE)


func _request_autosave() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method(&"save_game"):
		save_manager.call_deferred(&"save_game")
