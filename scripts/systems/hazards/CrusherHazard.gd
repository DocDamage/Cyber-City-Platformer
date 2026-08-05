class_name CrusherHazard
extends Node2D

@export_range(80.0, 500.0, 10.0) var travel_distance := 260.0
@export_range(0.2, 4.0, 0.05) var warning_time := 0.7
@export_range(0.1, 2.0, 0.05) var strike_time := 0.28
@export_range(0.2, 5.0, 0.05) var retract_time := 1.1
@export_range(0.0, 8.0, 0.05) var phase_offset := 0.0

var _origin := Vector2.ZERO
var _elapsed := 0.0
var _hazard: Hazard


func _ready() -> void:
	add_to_group(&"crushers")
	_origin = position
	_elapsed = phase_offset
	_hazard = Hazard.new()
	_hazard.name = "CrusherFace"
	_hazard.hazard_id = &"crusher"
	_hazard.instant_kill = true
	_hazard.hazard_size = Vector2(150.0, 70.0)
	_hazard.active_duration = 0.0
	_hazard.inactive_duration = 0.0
	_hazard.telegraph_duration = 0.0
	add_child(_hazard)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var cycle := warning_time + strike_time + retract_time
	var local_time := fposmod(_elapsed, cycle)
	if local_time < warning_time:
		_hazard.set_active(false)
		position = _origin
	elif local_time < warning_time + strike_time:
		_hazard.set_active(true)
		var weight := (local_time - warning_time) / strike_time
		position = _origin + Vector2.DOWN * travel_distance * weight * weight
	else:
		_hazard.set_active(false)
		var weight := (local_time - warning_time - strike_time) / retract_time
		position = _origin + Vector2.DOWN * travel_distance * (1.0 - smoothstep(0.0, 1.0, weight))


func reset_hazard() -> void:
	_elapsed = phase_offset
	position = _origin
	if _hazard != null:
		_hazard.reset_hazard()
		_hazard.set_active(false)
