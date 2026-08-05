class_name InteractiveTerminal
extends Area2D

signal activated

var linked_gate: SecurityGate
var _player_inside := false
var _activated := false
var _label: Label


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
	visual.color = Color("22e6ff")
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
	)
	body_exited.connect(func(body: Node) -> void:
		if body.is_in_group(&"player"):
			_player_inside = false
			_label.visible = false
	)


func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed(&"interact"):
		activate()


func activate() -> void:
	if _activated:
		return
	_activated = true
	_label.text = "ACCESS GRANTED"
	if linked_gate != null:
		linked_gate.open_gate()
	activated.emit()
