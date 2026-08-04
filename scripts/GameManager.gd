extends Node

signal player_health_changed(current: int, maximum: int)
signal player_energy_changed(current: float, maximum: float)
signal score_changed(total: int)
signal checkpoint_changed(checkpoint_id: StringName, position: Vector2)
signal level_transition_started(scene_path: String)

var player_health := -1
var player_max_health := 0
var player_energy := -1.0
var player_max_energy := 0.0
var current_score := 0
var current_checkpoint := Vector2.ZERO
var current_checkpoint_id := &""
var current_checkpoint_scene := ""

var checkpoint_locations: Dictionary = {}
var collected_pickups: Dictionary = {}
var _respawning := false
var _transitioning := false


func register_player(
		player: Node,
		maximum_health: int,
		maximum_energy: float,
		level_scene_path: String,
		default_spawn: Vector2
) -> void:
	player_max_health = maximum_health
	player_max_energy = maximum_energy
	if player_health < 0:
		player_health = maximum_health
	else:
		player_health = clampi(player_health, 1, maximum_health)
	if player_energy < 0.0:
		player_energy = maximum_energy
	else:
		player_energy = clampf(player_energy, 0.0, maximum_energy)

	if current_checkpoint_scene != level_scene_path:
		current_checkpoint_scene = level_scene_path
		current_checkpoint_id = &"level_start"
		current_checkpoint = default_spawn

	if player is Node2D and current_checkpoint_scene == level_scene_path:
		(player as Node2D).global_position = current_checkpoint

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


func activate_checkpoint(
		checkpoint_id: StringName,
		position: Vector2,
		level_scene_path: String
) -> void:
	current_checkpoint_id = checkpoint_id
	current_checkpoint = position
	current_checkpoint_scene = level_scene_path
	checkpoint_locations["%s::%s" % [level_scene_path, checkpoint_id]] = position
	checkpoint_changed.emit(checkpoint_id, position)


func request_respawn(player: Node) -> void:
	if _respawning or not is_instance_valid(player):
		return
	_respawning = true
	_respawn_after_delay(player)


func _respawn_after_delay(player: Node) -> void:
	await get_tree().create_timer(0.65, true, false, true).timeout
	if is_instance_valid(player) and player.has_method(&"respawn_at"):
		player.call(&"respawn_at", current_checkpoint)
	_respawning = false


func change_level(scene_path: String) -> void:
	if _transitioning or scene_path.is_empty():
		return
	_transitioning = true
	level_transition_started.emit(scene_path)
	_change_level_deferred(scene_path)


func _change_level_deferred(scene_path: String) -> void:
	await get_tree().process_frame
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("GameManager could not change scene to %s (error %s)." % [scene_path, error])
	_transitioning = false


func reset_run() -> void:
	player_health = -1
	player_energy = -1.0
	current_score = 0
	current_checkpoint = Vector2.ZERO
	current_checkpoint_id = &""
	current_checkpoint_scene = ""
	checkpoint_locations.clear()
	collected_pickups.clear()
	score_changed.emit(current_score)
