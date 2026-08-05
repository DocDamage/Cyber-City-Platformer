class_name FallingHazard
extends Node2D

@export_range(80.0, 700.0, 10.0) var drop_distance := 320.0
@export_range(0.2, 4.0, 0.05) var telegraph_time := 0.65
@export_range(0.2, 4.0, 0.05) var fall_time := 0.42
@export_range(0.2, 8.0, 0.05) var reset_time := 1.6
@export_range(0.0, 8.0, 0.05) var phase_offset := 0.0

var _origin := Vector2.ZERO
var _elapsed := 0.0
var _hazard: Hazard


func _ready() -> void:
	add_to_group(&"falling_hazards")
	_origin = position
	_elapsed = phase_offset
	_hazard = Hazard.new()
	_hazard.name = "Impact"
	_hazard.hazard_id = &"falling_object"
	_hazard.hazard_size = Vector2(76.0, 76.0)
	_hazard.active_duration = 0.0
	_hazard.inactive_duration = 0.0
	_hazard.telegraph_duration = 0.0
	add_child(_hazard)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var cycle := telegraph_time + fall_time + reset_time
	var local_time := fposmod(_elapsed, cycle)
	if local_time < telegraph_time:
		_hazard.set_active(false)
		position = _origin
	elif local_time < telegraph_time + fall_time:
		_hazard.set_active(true)
		var weight := (local_time - telegraph_time) / fall_time
		position = _origin + Vector2.DOWN * drop_distance * weight * weight
	else:
		_hazard.set_active(false)
		position = _origin + Vector2.DOWN * drop_distance


func reset_hazard() -> void:
	_elapsed = phase_offset
	position = _origin
	if _hazard != null:
		_hazard.reset_hazard()
		_hazard.set_active(false)
