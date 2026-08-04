class_name CheckpointTerminal
extends Area2D

signal activated(checkpoint_id: StringName)

@export var checkpoint_id: StringName = &"checkpoint_01"
@export var spawn_offset := Vector2(0.0, -54.0)

var _active := false
var _elapsed := 0.0

@onready var screen: Polygon2D = $Screen
@onready var light: PointLight2D = $PointLight2D
@onready var status: Label = $Status


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var manager := _game_manager()
	_active = manager != null and manager.get("current_checkpoint_id") == checkpoint_id \
			and manager.get("current_checkpoint_scene") == _get_level_scene_path()
	_apply_state()


func _process(delta: float) -> void:
	_elapsed += delta
	var pulse := (sin(_elapsed * (3.0 if _active else 6.0)) + 1.0) * 0.5
	light.energy = lerpf(0.75, 1.35, pulse)
	if not _active:
		screen.modulate.a = lerpf(0.55, 1.0, pulse)


func _on_body_entered(body: Node) -> void:
	if _active or not body.is_in_group(&"player"):
		return
	_active = true
	var spawn_position := global_position + spawn_offset
	var manager := _game_manager()
	if manager != null:
		manager.call(&"activate_checkpoint", checkpoint_id, spawn_position, _get_level_scene_path())
		manager.call(&"set_player_health", manager.get("player_max_health"))
		manager.call(&"set_player_energy", manager.get("player_max_energy"))
	if body.has_method(&"restore_from_checkpoint"):
		body.call(&"restore_from_checkpoint")
	var sound_manager := get_node_or_null("/root/SoundManager")
	if sound_manager != null:
		sound_manager.call(&"play_sfx", &"checkpoint", global_position, -2.0)
	_apply_state()
	activated.emit(checkpoint_id)


func _apply_state() -> void:
	if _active:
		screen.color = Color("64ffb4")
		light.color = Color("4dffb0")
		status.text = "SYNCED"
		status.modulate = Color("78ffc1")
	else:
		screen.color = Color("16d9ff")
		light.color = Color("00eaff")
		status.text = "CHECKPOINT"
		status.modulate = Color("65eaff")


func _get_level_scene_path() -> String:
	var node: Node = self
	while node.get_parent() != null and node.get_parent() != get_tree().root:
		node = node.get_parent()
	return node.scene_file_path


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")
