class_name StageController
extends Node

signal initialized(stage_id: String)
signal objectives_completed(stage_id: String)

var stage: StageBase
var metadata: Dictionary = {}
var stage_exit: StageExit
var player: Node2D
var objectives_are_complete := false
var _encounters_remaining := 0
var installed_mechanics: Array[Node] = []


func setup(stage_node: StageBase, stage_metadata: Dictionary) -> void:
	stage = stage_node
	metadata = stage_metadata.duplicate(true)
	name = "StageController"


func _ready() -> void:
	if stage == null or metadata.is_empty():
		push_error("StageController requires a stage and validated metadata.")
		return
	player = stage.get_player() as Node2D
	stage_exit = stage.get_stage_exit()
	_configure_camera()
	_connect_exit()
	installed_mechanics = StageMechanicFactory.install(stage, metadata)
	_build_standard_encounters()
	_register_boss_or_encounters()
	initialized.emit(get_stage_id())


func get_stage_id() -> String:
	return String(metadata.get("id", "%d-%d" % [stage.stage_act, stage.stage_sub]))


func get_debug_summary() -> Dictionary:
	return {
		"stage_id": get_stage_id(),
		"camera_bounds": metadata.get("camera_bounds", []),
		"mechanics": metadata.get("mechanics", []),
		"encounters_remaining": _encounters_remaining,
		"objectives_complete": objectives_are_complete,
	}


func register_encounter(encounter: Node) -> void:
	if encounter == null or not encounter.has_signal(&"completed"):
		return
	_encounters_remaining += 1
	if not encounter.is_connected(&"completed", _on_encounter_completed):
		encounter.connect(&"completed", _on_encounter_completed)
	if stage_exit != null:
		stage_exit.set_locked(true)


func complete_objectives_for_test() -> void:
	_encounters_remaining = 0
	_complete_objectives()


func restart_stage() -> void:
	get_tree().reload_current_scene()


func restart_checkpoint() -> void:
	if player != null and player.has_method(&"respawn_at"):
		var manager := get_node_or_null("/root/GameManager")
		if manager != null:
			player.call(&"respawn_at", manager.get("active_checkpoint_position"))


func _configure_camera() -> void:
	if player == null:
		push_error("Stage %s has no player for camera setup." % get_stage_id())
		return
	var camera := player.get_node_or_null("Camera2D") as DynamicCamera
	var values: Array = metadata.get("camera_bounds", [])
	if camera == null or values.size() != 4:
		push_error("Stage %s has no valid dynamic camera configuration." % get_stage_id())
		return
	var bounds := Rect2(float(values[0]), float(values[1]), float(values[2]) - float(values[0]), float(values[3]) - float(values[1]))
	camera.configure_bounds(bounds)


func _connect_exit() -> void:
	if stage_exit == null:
		push_error("Stage %s has no StageExit." % get_stage_id())
		return
	if not stage_exit.entered.is_connected(_on_exit_entered):
		stage_exit.entered.connect(_on_exit_entered)


func _register_boss_or_encounters() -> void:
	var completion: Dictionary = metadata.get("completion_target", {})
	if String(completion.get("type", "encounters")) == "boss":
		stage_exit.set_locked(true)
		for node: Node in get_tree().get_nodes_in_group(&"bosses"):
			if stage.is_ancestor_of(node) and node.has_signal(&"boss_defeated"):
				if not node.is_connected(&"boss_defeated", _on_boss_defeated.bind(node)):
					node.connect(&"boss_defeated", _on_boss_defeated.bind(node))
				return
		push_error("Boss stage %s has no production boss." % get_stage_id())
		return
	for node: Node in get_tree().get_nodes_in_group(&"encounters"):
		if stage.is_ancestor_of(node):
			register_encounter(node)
	if _encounters_remaining == 0:
		_complete_objectives()


func _build_standard_encounters() -> void:
	var completion: Dictionary = metadata.get("completion_target", {})
	if String(completion.get("type", "encounters")) != "encounters":
		return
	var encounter_count := maxi(int(metadata.get("encounter_count", 2)), 1)
	var bounds_values: Array = metadata.get("camera_bounds", [0, 0, 1408, 540])
	var left := float(bounds_values[0])
	var right := float(bounds_values[2])
	var segment_width := (right - left) / encounter_count
	var all_enemies: Array[EnemyBase] = []
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if stage.is_ancestor_of(node) and node is EnemyBase:
			all_enemies.append(node as EnemyBase)
	var roster: Array = metadata.get("enemy_roster", [])
	var enemy_parent := stage.find_child("Enemies", true, false)
	if enemy_parent == null:
		enemy_parent = stage
	for index in range(encounter_count):
		var segment_left := left + segment_width * index
		var segment_right := segment_left + segment_width
		var encounter_enemies: Array[EnemyBase] = []
		for enemy: EnemyBase in all_enemies:
			if enemy.global_position.x >= segment_left and enemy.global_position.x < segment_right:
				encounter_enemies.append(enemy)
		while encounter_enemies.size() < 2 and not roster.is_empty():
			var enemy_id := StringName(roster[(index + encounter_enemies.size()) % roster.size()])
			var registry := get_node_or_null("/root/AssetRegistry")
			var packed := registry.call(&"get_enemy_scene", enemy_id) as PackedScene
			if packed == null:
				break
			var enemy := packed.instantiate() as EnemyBase
			enemy_parent.add_child(enemy)
			var spawn_fraction := 0.48 + 0.16 * encounter_enemies.size()
			enemy.global_position = Vector2(lerpf(segment_left, segment_right, spawn_fraction), _encounter_floor_y())
			encounter_enemies.append(enemy)
			all_enemies.append(enemy)
		var encounter := EncounterController.new()
		var activation_rect := Rect2(segment_left, -360.0, segment_width, 1080.0)
		encounter.configure(StringName("%s_%02d" % [get_stage_id(), index + 1]), activation_rect, encounter_enemies)
		stage.add_child(encounter)


func _encounter_floor_y() -> float:
	if player != null:
		return player.global_position.y + 10.0
	return 432.0


func _on_encounter_completed() -> void:
	_encounters_remaining = maxi(_encounters_remaining - 1, 0)
	if _encounters_remaining == 0:
		_complete_objectives()


func _on_boss_defeated(boss: Node) -> void:
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.call(&"mark_boss_defeated", StringName(metadata.get("expected_boss", boss.name)))
	_complete_objectives()


func _complete_objectives() -> void:
	if objectives_are_complete:
		return
	objectives_are_complete = true
	if stage_exit != null:
		stage_exit.set_locked(false)
	objectives_completed.emit(get_stage_id())


func _on_exit_entered() -> void:
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.call(&"complete_stage", get_stage_id())
