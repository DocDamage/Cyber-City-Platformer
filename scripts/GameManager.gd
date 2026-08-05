extends Node

signal player_health_changed(current: int, maximum: int)
signal player_energy_changed(current: float, maximum: float)
signal score_changed(total: int)
signal checkpoint_changed(checkpoint_id: StringName, position: Vector2)
signal level_transition_started(scene_path: String)
signal level_transition_finished(scene_path: String)
signal stage_completed(stage_id: String)
signal campaign_completed

var run_state := RunState.new()
var campaign_progress := CampaignProgress.new()
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


func mark_boss_defeated(boss_id: StringName) -> void:
	if boss_id.is_empty():
		return
	run_state.defeated_bosses[String(boss_id)] = true
	campaign_progress.defeated_bosses[String(boss_id)] = true
	_request_autosave()


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
	change_level(String(next_stage.get("scene", "")))


func new_game() -> void:
	run_state.clear()
	campaign_progress.clear()
	_respawning = false
	_transitioning = false
	score_changed.emit(0)


func reset_run() -> void:
	run_state.clear()
	_respawning = false
	_transitioning = false
	score_changed.emit(0)


func get_save_data() -> Dictionary:
	return {"run_state": run_state.to_dict(), "campaign_progress": campaign_progress.to_dict()}


func restore_save_data(data: Dictionary) -> bool:
	if not run_state.load_dict(data.get("run_state", {})):
		return false
	if not campaign_progress.load_dict(data.get("campaign_progress", {})):
		return false
	return true


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


func _request_autosave() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method(&"save_game"):
		save_manager.call_deferred(&"save_game")
