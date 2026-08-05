class_name RotatingLaser
extends Node2D

@export_range(40.0, 420.0, 5.0) var radius := 180.0
@export_range(0.1, 5.0, 0.05) var rotation_speed := 0.8
@export var clockwise := true
@export var starts_enabled := true

var _hazard: Hazard
var _line: Line2D


func _ready() -> void:
	add_to_group(&"rotating_lasers")
	_hazard = Hazard.new()
	_hazard.name = "LaserBeam"
	_hazard.hazard_id = &"rotating_laser"
	_hazard.hazard_size = Vector2(radius, 18.0)
	_hazard.position.x = radius * 0.5
	_hazard.active_duration = 0.0
	_hazard.inactive_duration = 0.0
	_hazard.telegraph_duration = 0.0
	_hazard.starts_enabled = starts_enabled
	add_child(_hazard)
	_line = Line2D.new()
	_line.name = "LaserVisual"
	_line.width = 7.0
	_line.default_color = Color(1.0, 0.05, 0.65, 0.9)
	_line.points = PackedVector2Array([Vector2.ZERO, Vector2(radius, 0.0)])
	add_child(_line)
	set_enabled(starts_enabled)


func _physics_process(delta: float) -> void:
	if starts_enabled:
		rotation += rotation_speed * delta * (1.0 if clockwise else -1.0)


func set_enabled(value: bool) -> void:
	starts_enabled = value
	if _hazard != null:
		_hazard.set_enabled(value)
	if _line != null:
		_line.visible = value


func reset_hazard() -> void:
	rotation = 0.0
	set_enabled(starts_enabled)
