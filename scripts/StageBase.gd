@tool
class_name StageBase
extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")

@export var stage_act: int = 1
@export var stage_sub: int = 1
@export var environment_tint: Color = Color.WHITE


func _ready() -> void:
	var canvas_modulate := find_child("CanvasModulate", true, false) as CanvasModulate
	if canvas_modulate != null:
		canvas_modulate.color = environment_tint

	if Engine.is_editor_hint() or _find_player() != null:
		return

	var spawn_point := find_child("PlayerSpawn", true, false) as Marker2D
	if spawn_point == null:
		return

	var player := PLAYER_SCENE.instantiate() as Node2D
	if player == null:
		push_error("StageBase could not instance the Player scene.")
		return

	player.name = "Player"
	player.position = to_local(spawn_point.global_position)
	add_child(player)


func _find_player() -> Node:
	for player in get_tree().get_nodes_in_group(&"player"):
		if is_ancestor_of(player):
			return player
	return find_child("Player", true, false)
