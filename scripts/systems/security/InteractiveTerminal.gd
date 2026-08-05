class_name InteractiveTerminal
extends Area2D

signal activated
signal focus_changed(active: bool, prompt: String)

var linked_gate: SecurityGate
var _player_inside := false
var _activated := false
var _label: Label
var _hold_progress := 0.0


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
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-24.0, -36.0), Vector2(24.0, -36.0),
		Vector2(24.0, 36.0), Vector2(-24.0, 36.0),
	])
	var settings := get_node_or_null("/root/SettingsManager")
	visual.color = Color.WHITE if settings != null and bool(settings.call(&"get_setting", &"high_contrast_interactables", false)) else Color("22e6ff")
	add_child(visual)
	_label = Label.new()
	_label.position = Vector2(-70.0, -72.0)
	_label.text = "PRESS E / Y: ACCESS"
	_label.visible = false
	add_child(_label)
	body_entered.connect(func(body: Node) -> void:
		if body.is_in_group(&"player"):
			_player_inside = true
			_label.visible = true
			focus_changed.emit(true, "E / Y  ACCESS TERMINAL")
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
	_label.text = "HOLD E / Y: %d%%" % mini(roundi(_hold_progress / 0.6 * 100.0), 100)
	if _hold_progress >= 0.6:
		activate()


func activate() -> void:
	if _activated:
		return
	_activated = true
	_label.text = "ACCESS GRANTED"
	if linked_gate != null:
		linked_gate.open_gate()
	activated.emit()
