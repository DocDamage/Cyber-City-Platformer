class_name StageController
extends Node

const COLLECTIBLE_SCENE := preload("res://scenes/Collectible.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/PauseMenu.tscn")

signal initialized(stage_id: String)
signal objectives_completed(stage_id: String)

var stage: StageBase
var metadata: Dictionary = {}
var blueprint: Dictionary = {}
var stage_exit: StageExit
var player: Node2D
var objectives_are_complete := false
var installed_mechanics: Array[Node] = []
var authored_traversal: Array[AuthoredTraversal] = []
var authored_encounters: Array[EncounterController] = []
var environmental_presentation: EnvironmentalPresentation
var _encounters_remaining := 0
var _pause_menu: Node


func setup(stage_node: StageBase, stage_metadata: Dictionary) -> void:
	stage = stage_node
	metadata = stage_metadata.duplicate(true)
	name = "StageController"


func _ready() -> void:
	if stage == null or metadata.is_empty():
		push_error("StageController requires a stage and validated metadata.")
		return
	blueprint = StageContentCatalog.get_blueprint(get_stage_id())
	var completion := metadata.get("completion_target", {}) as Dictionary
	var is_boss_stage := String(completion.get("type", "encounters")) == "boss"
	var blueprint_errors := StageContentCatalog.validate(blueprint, is_boss_stage)
	if not blueprint_errors.is_empty():
		push_error("Stage %s blueprint invalid: %s" % [get_stage_id(), "; ".join(blueprint_errors)])
		return
	player = stage.get_player() as Node2D
	stage_exit = stage.get_stage_exit()
	if stage_exit != null:
		stage_exit.set_locked_message("DEFEAT BOSS" if is_boss_stage else "CLEAR ENCOUNTERS")
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.call(&"enter_stage", get_stage_id(), stage.scene_file_path)
	_configure_camera()
	_connect_exit()
	_register_checkpoints()
	_ensure_pause_menu()
	_start_music()
	_build_collectibles()
	installed_mechanics = StageMechanicFactory.install(stage, blueprint)
	_install_environmental_presentation()
	_collect_traversal_sections()
	if is_boss_stage:
		_register_boss()
	else:
		_build_authored_encounters()
	_bind_hud()
	_present_stage_briefing()
	if player != null and player.has_signal(&"died") and not player.is_connected(&"died", _on_player_died):
		player.connect(&"died", _on_player_died)
	initialized.emit(get_stage_id())


func get_stage_id() -> String:
	return String(metadata.get("id", "%d-%d" % [stage.stage_act, stage.stage_sub]))


func get_debug_summary() -> Dictionary:
	var authored_enemy_count := 0
	var wave_count := 0
	for encounter: EncounterController in authored_encounters:
		authored_enemy_count += encounter.get_total_authored_enemy_count()
		wave_count += encounter.get_wave_count()
	return {
		"stage_id": get_stage_id(),
		"camera_bounds": metadata.get("camera_bounds", []),
		"mechanics": installed_mechanics.size(),
		"traversal_sections": authored_traversal.size(),
		"encounter_count": authored_encounters.size(),
		"wave_count": wave_count,
		"authored_enemy_count": authored_enemy_count,
		"encounters_remaining": _encounters_remaining,
		"objectives_complete": objectives_are_complete,
	}


func register_encounter(encounter: EncounterController) -> void:
	if encounter == null:
		return
	_encounters_remaining += 1
	if not encounter.completed.is_connected(_on_encounter_completed):
		encounter.completed.connect(_on_encounter_completed)
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
	_reset_stage_systems()


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
		push_error("Stage %s has no StageExit at its exported path." % get_stage_id())
		return
	if not stage_exit.entered.is_connected(_on_exit_entered):
		stage_exit.entered.connect(_on_exit_entered)


func _register_checkpoints() -> void:
	var container := stage.get_checkpoints_container()
	if container == null:
		push_error("Stage %s has no checkpoint container at its exported path." % get_stage_id())
		return
	var count := 0
	for child: Node in container.get_children():
		if child is CheckpointTerminal:
			count += 1
			var checkpoint := child as CheckpointTerminal
			if not checkpoint.activated.is_connected(_on_checkpoint_activated):
				checkpoint.activated.connect(_on_checkpoint_activated)
	if count < int(metadata.get("expected_checkpoints", 1)):
		push_error("Stage %s has %d checkpoints; expected %d." % [get_stage_id(), count, metadata.get("expected_checkpoints", 1)])


func _start_music() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		return
	var act_number := int(metadata.get("act", stage.stage_act))
	var completion := metadata.get("completion_target", {}) as Dictionary
	if String(completion.get("type", "encounters")) == "boss":
		audio_manager.call(&"play_boss_bgm", act_number)
	else:
		audio_manager.call(&"play_bgm", act_number)


func _ensure_pause_menu() -> void:
	_pause_menu = PAUSE_MENU_SCENE.instantiate()
	stage.get_runtime_ui_container().add_child(_pause_menu)


func _build_collectibles() -> void:
	var container := stage.get_collectibles_container()
	_clear_container(container)
	var positions := blueprint.get("collectibles", []) as Array
	var expected := int(metadata.get("collectible_count", 0))
	if positions.size() != expected:
		push_error("Stage %s has %d authored collectible positions; expected %d." % [get_stage_id(), positions.size(), expected])
	var manager := get_node_or_null("/root/GameManager")
	for index in range(positions.size()):
		var collectible := COLLECTIBLE_SCENE.instantiate() as Collectible
		collectible.pickup_id = StringName("%s_collectible_%02d" % [get_stage_id(), index + 1])
		container.add_child(collectible)
		collectible.global_position = positions[index]
		if manager != null and manager.call(&"is_pickup_collected", stage.scene_file_path, collectible.pickup_id):
			collectible.queue_free()
		elif not collectible.collected.is_connected(_on_collectible_collected):
			collectible.collected.connect(_on_collectible_collected)


func _collect_traversal_sections() -> void:
	authored_traversal.clear()
	for child: Node in stage.get_mechanics_container().get_children():
		if child is AuthoredTraversal:
			authored_traversal.append(child as AuthoredTraversal)


func _install_environmental_presentation() -> void:
	var container := stage.get_presentation_container()
	for child: Node in container.get_children():
		if child is EnvironmentalPresentation or child is StageArchitectureDressing:
			child.queue_free()
	var values: Array = metadata.get("camera_bounds", [0, 0, 1408, 540])
	var bounds := Rect2(float(values[0]), float(values[1]), float(values[2]) - float(values[0]), float(values[3]) - float(values[1]))
	environmental_presentation = EnvironmentalPresentation.new()
	environmental_presentation.configure(int(metadata.get("act", stage.stage_act)), stage.stage_sub, bounds)
	container.add_child(environmental_presentation)
	var dressing := StageArchitectureDressing.new()
	container.add_child(dressing)
	dressing.configure(stage, StringName(get_stage_id()))


func _build_authored_encounters() -> void:
	var enemy_parent := stage.get_enemies_container()
	var encounter_parent := stage.get_encounters_container()
	_clear_container(enemy_parent)
	_clear_container(encounter_parent)
	var registry := get_node_or_null("/root/AssetRegistry")
	for entry_value: Variant in blueprint.get("encounters", []):
		var entry := entry_value as Dictionary
		var encounter := EncounterController.new()
		encounter.configure_blueprint(
			StringName(entry.get("id", "encounter")),
			entry.get("activation", Rect2()),
			entry.get("waves", []),
			enemy_parent,
			registry,
			bool(entry.get("lock_arena", true)),
			int(metadata.get("act", stage.stage_act)),
		)
		encounter_parent.add_child(encounter)
		authored_encounters.append(encounter)
		register_encounter(encounter)
	if authored_encounters.is_empty():
		_complete_objectives()


func _register_boss() -> void:
	if stage_exit != null:
		stage_exit.set_locked(true)
	var boss := stage.get_boss()
	if boss == null:
		push_error("Boss stage %s has no boss at its exported path." % get_stage_id())
		return
	var arena_data := blueprint.get("boss_arena", {}) as Dictionary
	var arena_bounds := arena_data.get("bounds", Rect2()) as Rect2
	boss.configure_stage(stage_exit, player, arena_bounds)
	if not boss.boss_defeated.is_connected(_on_boss_defeated.bind(boss)):
		boss.boss_defeated.connect(_on_boss_defeated.bind(boss))
	var arena := BossArenaController.new()
	var camera := player.get_node_or_null("Camera2D") as DynamicCamera if player != null else null
	arena.configure(arena_bounds, boss, camera, int(metadata.get("act", stage.stage_act)))
	stage.get_encounters_container().add_child(arena)


func _bind_hud() -> void:
	var hud := stage.get_hud()
	if hud == null:
		push_error("Stage %s has no HUD at its exported path." % get_stage_id())
		return
	if hud.has_method(&"bind_stage"):
		hud.call(&"bind_stage", self)
	var boss := stage.get_boss()
	if boss != null and hud.has_method(&"bind_boss"):
		hud.call(&"bind_boss", boss)


func _present_stage_briefing() -> void:
	var hud := stage.get_hud()
	if hud != null and hud.has_method(&"show_stage_intro"):
		hud.call(&"show_stage_intro", get_stage_id(), metadata)


func _reset_stage_systems() -> void:
	for mechanic: Node in installed_mechanics:
		for method: StringName in [&"reset_hazard", &"reset_zone", &"reset_platform", &"reset_conveyor", &"reset_security", &"reset_gate", &"reset_interaction", &"reset_switch"]:
			if mechanic.has_method(method):
				mechanic.call(method)
				break


func _on_player_died() -> void:
	_reset_stage_systems()


func _on_checkpoint_activated(_checkpoint_id: StringName) -> void:
	for mechanic: Node in installed_mechanics:
		if mechanic.has_method(&"reset_hazard"):
			mechanic.call(&"reset_hazard")


func _on_collectible_collected(pickup_id: StringName, value: int) -> void:
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.call(&"collect_pickup", stage.scene_file_path, pickup_id, value)


func _on_encounter_completed() -> void:
	_encounters_remaining = maxi(_encounters_remaining - 1, 0)
	if _encounters_remaining == 0:
		_complete_objectives()


func _on_boss_defeated(boss: BossBase) -> void:
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.call(&"mark_boss_defeated", StringName(metadata.get("expected_boss", boss.name)))
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.call(&"play_bgm", int(metadata.get("act", stage.stage_act)), -11.0)
	_complete_objectives()


func _complete_objectives() -> void:
	if objectives_are_complete:
		return
	objectives_are_complete = true
	if stage_exit != null:
		stage_exit.set_locked(false)
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.call(&"play_sfx", &"stage_clear", player.global_position if player != null else Vector2.ZERO, -3.0)
	objectives_completed.emit(get_stage_id())


func _on_exit_entered() -> void:
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.call(&"complete_stage", get_stage_id())


func _clear_container(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
