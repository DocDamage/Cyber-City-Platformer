@tool
class_name StageBase
extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")

@export var stage_act: int = 1
@export var stage_sub: int = 1
@export var environment_tint: Color = Color.WHITE
@export var runtime_enabled := true
@export_node_path("CharacterBody2D") var player_path: NodePath = ^"Player"
@export_node_path("Marker2D") var player_spawn_path: NodePath = ^"Markers/PlayerSpawn"
@export_node_path("Area2D") var stage_exit_path: NodePath = ^"Markers/StageExit"
@export_node_path("Node2D") var enemies_container_path: NodePath = ^"Enemies"
@export_node_path("Node2D") var collectibles_container_path: NodePath = ^"Collectibles"
@export_node_path("Node2D") var mechanics_container_path: NodePath = ^"AuthoredMechanics"
@export_node_path("Node2D") var encounters_container_path: NodePath = ^"AuthoredEncounters"
@export_node_path("Node2D") var checkpoints_container_path: NodePath = ^"Markers/Checkpoints"
@export_node_path("CanvasLayer") var runtime_ui_container_path: NodePath = ^"RuntimeUI"
@export_node_path("CharacterBody2D") var boss_path: NodePath
@export_node_path("CanvasLayer") var hud_path: NodePath = ^"HUD"
@export_node_path("Area2D") var death_zone_path: NodePath = ^"DeathZone"
@export_node_path("TileMapLayer") var terrain_path: NodePath = ^"Terrain"
@export_node_path("Node2D") var ambient_root_path: NodePath = ^"Background"
@export_node_path("Node2D") var presentation_container_path: NodePath = ^"VFX"

var runtime_controller: StageController


func _ready() -> void:
	var canvas_modulate := get_node_or_null(^"CanvasModulate") as CanvasModulate
	if canvas_modulate != null:
		canvas_modulate.color = environment_tint
	if Engine.is_editor_hint():
		return
	_ensure_player()
	if runtime_enabled:
		_attach_runtime_controller.call_deferred()


func get_player() -> Node:
	return get_node_or_null(player_path)


func get_player_spawn() -> Marker2D:
	if player_spawn_path.is_empty():
		return null
	return get_node_or_null(player_spawn_path) as Marker2D


func get_stage_exit() -> StageExit:
	return get_node_or_null(stage_exit_path) as StageExit


func get_enemies_container() -> Node2D:
	return _get_or_create_node2d(enemies_container_path, "Enemies")


func get_collectibles_container() -> Node2D:
	return _get_or_create_node2d(collectibles_container_path, "Collectibles")


func get_mechanics_container() -> Node2D:
	return _get_or_create_node2d(mechanics_container_path, "AuthoredMechanics")


func get_encounters_container() -> Node2D:
	return _get_or_create_node2d(encounters_container_path, "AuthoredEncounters")


func get_checkpoints_container() -> Node2D:
	return get_node_or_null(checkpoints_container_path) as Node2D


func get_boss() -> BossBase:
	if boss_path.is_empty():
		return null
	return get_node_or_null(boss_path) as BossBase


func get_hud() -> CanvasLayer:
	return get_node_or_null(hud_path) as CanvasLayer


func get_death_zone() -> Area2D:
	return get_node_or_null(death_zone_path) as Area2D


func get_terrain() -> TileMapLayer:
	return get_node_or_null(terrain_path) as TileMapLayer


func get_ambient_root() -> Node2D:
	return get_node_or_null(ambient_root_path) as Node2D


func get_presentation_container() -> Node2D:
	return _get_or_create_node2d(presentation_container_path, "VFX")


func get_runtime_ui_container() -> CanvasLayer:
	var existing := get_node_or_null(runtime_ui_container_path) as CanvasLayer
	if existing != null:
		return existing
	var container := CanvasLayer.new()
	container.name = "RuntimeUI"
	container.layer = 90
	add_child(container)
	return container


func _ensure_player() -> void:
	if get_player() != null:
		return
	var spawn_point := get_player_spawn()
	if spawn_point == null:
		push_error("StageBase %d-%d has no PlayerSpawn." % [stage_act, stage_sub])
		return
	var player := PLAYER_SCENE.instantiate() as Node2D
	if player == null:
		push_error("StageBase could not instantiate the Player scene.")
		return
	player.name = "Player"
	player.position = to_local(spawn_point.global_position)
	add_child(player)
	player_path = get_path_to(player)


func _attach_runtime_controller() -> void:
	if runtime_controller != null:
		return
	var registry := get_node_or_null("/root/AssetRegistry")
	if registry == null:
		push_error("StageBase requires AssetRegistry.")
		return
	var metadata: Dictionary = registry.call(&"get_stage_info", stage_act, stage_sub)
	if metadata.is_empty():
		push_error("StageBase could not resolve metadata for %d-%d." % [stage_act, stage_sub])
		return
	runtime_controller = StageController.new()
	runtime_controller.setup(self, metadata)
	add_child(runtime_controller)


func _get_or_create_node2d(path: NodePath, fallback_name: String) -> Node2D:
	var existing := get_node_or_null(path) as Node2D
	if existing != null:
		return existing
	var container := Node2D.new()
	container.name = fallback_name
	add_child(container)
	return container
