@tool
class_name StageBase
extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")

@export var stage_act: int = 1
@export var stage_sub: int = 1
@export var environment_tint: Color = Color.WHITE
@export var player_spawn_path: NodePath
@export var stage_exit_path: NodePath

var runtime_controller: StageController


func _ready() -> void:
	var canvas_modulate := find_child("CanvasModulate", true, false) as CanvasModulate
	if canvas_modulate != null:
		canvas_modulate.color = environment_tint
	if Engine.is_editor_hint():
		return
	_ensure_player()
	_attach_runtime_controller.call_deferred()


func get_player() -> Node:
	for player: Node in get_tree().get_nodes_in_group(&"player"):
		if is_ancestor_of(player):
			return player
	return find_child("Player", true, false)


func get_player_spawn() -> Marker2D:
	if not player_spawn_path.is_empty():
		return get_node_or_null(player_spawn_path) as Marker2D
	return find_child("PlayerSpawn", true, false) as Marker2D


func get_stage_exit() -> StageExit:
	if not stage_exit_path.is_empty():
		return get_node_or_null(stage_exit_path) as StageExit
	for node: Node in get_tree().get_nodes_in_group(&"stage_exits"):
		if is_ancestor_of(node) and node is StageExit:
			return node as StageExit
	return find_child("StageExit", true, false) as StageExit


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
