class_name SecurityGate
extends StaticBody2D

const LOCKDOWN_GATE_ART := preload("res://scripts/systems/security/LockdownGateArt.gd")

signal opened
signal closed

@export var gate_size := Vector2(34.0, 180.0)
@export var gate_id: StringName = &"security_gate"
@export_range(1, 8, 1) var required_switches := 1
@export_range(0.0, 30.0, 0.1) var timed_open_duration := 0.0
@export_enum("encounter", "checkpoint", "save") var persistence := "encounter"
var is_open := false
var _collision: CollisionShape2D
var _visual: CanvasItem
var _activated_sources: Dictionary = {}
var _open_generation := 0


func _ready() -> void:
	add_to_group(&"security_gates")
	_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = gate_size
	_collision.shape = shape
	add_child(_collision)
	var gate_art := LOCKDOWN_GATE_ART.new()
	gate_art.configure(gate_size, _resolve_act_number(), &"security")
	_visual = gate_art as CanvasItem
	add_child(_visual)
	_restore_persisted_state.call_deferred()


func open_gate() -> void:
	request_open(&"direct")


func request_open(source_id: StringName) -> void:
	if is_open:
		return
	_activated_sources[String(source_id)] = true
	if _activated_sources.size() < required_switches:
		_update_visual_progress()
		return
	is_open = true
	_open_generation += 1
	_collision.set_deferred("disabled", true)
	create_tween().set_parallel(true).tween_property(_visual, "modulate:a", 0.1, 0.3)
	_persist_state(true)
	opened.emit()
	if timed_open_duration > 0.0:
		_close_after(timed_open_duration, _open_generation)


func close_gate() -> void:
	if not is_open:
		return
	_open_generation += 1
	is_open = false
	_collision.set_deferred("disabled", false)
	_visual.modulate.a = 1.0
	_persist_state(false)
	closed.emit()


func reset_gate() -> void:
	if persistence in ["checkpoint", "save"] and _get_persisted_state():
		_apply_open_state()
		return
	_activated_sources.clear()
	close_gate()
	_update_visual_progress()


func _close_after(duration: float, generation: int) -> void:
	await get_tree().create_timer(duration, true, false, true).timeout
	if generation == _open_generation:
		close_gate()


func _apply_open_state() -> void:
	is_open = true
	if _collision != null:
		_collision.set_deferred("disabled", true)
	if _visual != null:
		_visual.modulate.a = 0.1


func _update_visual_progress() -> void:
	if _visual != null:
		var weight := float(_activated_sources.size()) / float(maxi(required_switches, 1))
		_visual.call(&"set_charge", weight)


func _resolve_act_number() -> int:
	var node: Node = get_parent()
	while node != null:
		if node is StageBase:
			return clampi((node as StageBase).stage_act, 1, 4)
		node = node.get_parent()
	return 2 if String(gate_id).contains("factory") or String(gate_id).contains("conveyor") else 1


func _persist_state(value: bool) -> void:
	if persistence not in ["checkpoint", "save"]:
		return
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		if _in_world_room():
			manager.world_progress.set_object_state(String(gate_id), value)
			if persistence == "save":
				var save := get_node_or_null("/root/SaveManager")
				if save != null:
					save.call_deferred(&"save_game")
		else:
			manager.call(&"set_stage_flag", _stage_scene_path(), gate_id, value, persistence == "save")


func _get_persisted_state() -> bool:
	var manager := get_node_or_null("/root/GameManager")
	if manager == null:
		return false
	if _in_world_room():
		return bool(manager.world_progress.get_object_state(String(gate_id), false))
	return bool(manager.call(&"get_stage_flag", _stage_scene_path(), gate_id, false))


func _restore_persisted_state() -> void:
	if persistence in ["checkpoint", "save"] and _get_persisted_state():
		_apply_open_state()


func _stage_scene_path() -> String:
	var node: Node = self
	while node.get_parent() != null and node.get_parent() != get_tree().root:
		node = node.get_parent()
	return node.scene_file_path


func _in_world_room() -> bool:
	var node := get_parent()
	while node != null:
		if node.is_in_group(&"world_rooms"):
			return true
		node = node.get_parent()
	return false
