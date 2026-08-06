class_name InteractiveTerminal
extends Area2D

signal activated
signal focus_changed(active: bool, prompt: String)

@export var terminal_id: StringName = &"terminal"
@export_enum("terminal", "switch", "lore") var interaction_kind := "terminal"
@export_enum("encounter", "checkpoint", "save") var persistence := "encounter"
@export_multiline var lore_text := ""

var linked_gate: SecurityGate
var linked_targets: Array[Node] = []
var _player_inside := false
var _activated := false
var _label: Label
var _hold_progress := 0.0

const TERMINAL_TEXTURE := "res://assets/runtime/props/districts/security_grid_shaft/grid_terminal.png"


func _ready() -> void:
	add_to_group(&"interactive_terminals")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(72.0, 100.0)
	collision.shape = shape
	add_child(collision)
	var visual := Sprite2D.new()
	visual.name = "TerminalConsole"
	visual.texture = load(TERMINAL_TEXTURE) as Texture2D
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(2.0, 2.0)
	visual.position.y = 33.0
	var settings := get_node_or_null("/root/SettingsManager")
	visual.modulate = Color.WHITE if settings != null and bool(settings.call(&"get_setting", &"high_contrast_interactables", false)) else Color("b8f7ff")
	add_child(visual)
	_label = Label.new()
	_label.position = Vector2(-70.0, -72.0)
	_label.visible = false
	add_child(_label)
	_bind_prompt_updates()
	_refresh_prompt()
	_restore_persisted_state()
	body_entered.connect(func(body: Node) -> void:
		if body.is_in_group(&"player"):
			_player_inside = true
			_label.visible = true
			focus_changed.emit(true, "%s  ACCESS TERMINAL" % _interact_prompt())
	)
	body_exited.connect(func(body: Node) -> void:
		if body.is_in_group(&"player"):
			_player_inside = false
			_label.visible = false
			focus_changed.emit(false, "")
	)


func _unhandled_input(event: InputEvent) -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	var hold_mode := settings != null and bool(settings.call(&"get_setting", &"hold_to_interact", false))
	if _player_inside and not hold_mode and event.is_action_pressed(&"interact"):
		activate()


func _process(delta: float) -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	var hold_mode := settings != null and bool(settings.call(&"get_setting", &"hold_to_interact", false))
	if not hold_mode or not _player_inside or _activated:
		_hold_progress = 0.0
		return
	_hold_progress = _hold_progress + delta if Input.is_action_pressed(&"interact") else 0.0
	_label.text = "HOLD %s: %d%%" % [_interact_prompt(), mini(roundi(_hold_progress / 0.6 * 100.0), 100)]
	if _hold_progress >= 0.6:
		activate()


func activate() -> void:
	if _activated:
		return
	_activated = true
	_label.text = lore_text if interaction_kind == "lore" and not lore_text.is_empty() else "ACCESS GRANTED"
	if linked_gate != null:
		linked_gate.request_open(terminal_id)
	for target: Node in linked_targets:
		_activate_target(target)
	_persist_state(true)
	activated.emit()


func link_target(target: Node) -> void:
	if target == null or linked_targets.has(target):
		return
	linked_targets.append(target)
	if _activated:
		_activate_target(target)


func reset_interaction() -> void:
	if persistence in ["checkpoint", "save"] and _get_persisted_state():
		return
	_activated = false
	_hold_progress = 0.0
	if _label != null:
		_refresh_prompt()


func is_activated() -> bool:
	return _activated


func _activate_target(target: Node) -> void:
	if target.has_method(&"request_open"):
		target.call(&"request_open", terminal_id)
	elif target.has_method(&"reverse"):
		target.call(&"reverse")
	elif target.has_method(&"set_enabled"):
		target.call(&"set_enabled", false)
	elif target.has_method(&"activate"):
		target.call(&"activate")


func _persist_state(value: bool) -> void:
	if persistence not in ["checkpoint", "save"]:
		return
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		if _in_world_room():
			manager.world_progress.set_object_state(String(terminal_id), value)
			if persistence == "save":
				var save := get_node_or_null("/root/SaveManager")
				if save != null:
					save.call_deferred(&"save_game")
		else:
			manager.call(&"set_stage_flag", _stage_scene_path(), terminal_id, value, persistence == "save")


func _get_persisted_state() -> bool:
	var manager := get_node_or_null("/root/GameManager")
	if manager == null:
		return false
	if _in_world_room():
		return bool(manager.world_progress.get_object_state(String(terminal_id), false))
	return bool(manager.call(&"get_stage_flag", _stage_scene_path(), terminal_id, false))


func _restore_persisted_state() -> void:
	if persistence in ["checkpoint", "save"] and _get_persisted_state():
		_activated = true
		_label.text = "ACCESS RESTORED"


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


func _interact_prompt() -> String:
	var settings := get_node_or_null("/root/SettingsManager")
	return String(settings.call(&"get_action_prompt", &"interact")) if settings != null else "INTERACT"


func _bind_prompt_updates() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return
	for signal_name: StringName in [&"input_device_changed", &"action_binding_changed"]:
		var callback := Callable(self, &"_refresh_prompt")
		if settings.has_signal(signal_name) and not settings.is_connected(signal_name, callback):
			settings.connect(signal_name, callback)


func _refresh_prompt(_unused: Variant = null) -> void:
	if _label == null or _activated:
		return
	_label.text = "PRESS %s: ACCESS" % _interact_prompt()
	if _player_inside:
		focus_changed.emit(true, "%s  ACCESS TERMINAL" % _interact_prompt())
