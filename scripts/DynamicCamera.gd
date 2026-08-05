class_name DynamicCamera
extends Camera2D

@export_group("Follow")
@export_range(0.0, 320.0, 1.0) var look_ahead_distance := 112.0
@export_range(0.1, 20.0, 0.1) var look_ahead_speed := 6.0
@export_range(-240.0, 240.0, 1.0) var vertical_offset := -80.0

var _facing_direction := 1.0
var _look_ahead_x := 0.0
var _base_offset := Vector2.ZERO
var _shake_strength := 0.0
var _shake_duration := 0.0
var _shake_remaining := 0.0
var _random := RandomNumberGenerator.new()
var _stage_bounds := Rect2(0.0, 0.0, 1408.0, 540.0)


func _ready() -> void:
	add_to_group(&"game_camera")
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0
	_base_offset = offset
	_look_ahead_x = _facing_direction * look_ahead_distance
	position = Vector2(_look_ahead_x, vertical_offset)
	_random.randomize()
	configure_bounds(_stage_bounds)


func _process(delta: float) -> void:
	var target_x := _facing_direction * look_ahead_distance
	var follow_weight := 1.0 - exp(-look_ahead_speed * delta)
	_look_ahead_x = lerpf(_look_ahead_x, target_x, follow_weight)
	position = Vector2(_look_ahead_x, vertical_offset)
	_update_shake(delta)


func set_facing_direction(direction: float) -> void:
	if not is_zero_approx(direction):
		_facing_direction = signf(direction)


func configure_bounds(bounds: Rect2, offset_y := vertical_offset) -> void:
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		push_warning("DynamicCamera rejected invalid bounds: %s" % bounds)
		return
	_stage_bounds = bounds
	limit_left = floori(bounds.position.x)
	limit_top = floori(bounds.position.y)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)
	vertical_offset = offset_y
	limit_smoothed = true


func get_configured_bounds() -> Rect2:
	return _stage_bounds


func get_clamped_center_for_world_position(world_position: Vector2, viewport_size := Vector2(960.0, 540.0)) -> Vector2:
	var half_view := viewport_size * 0.5
	var minimum := _stage_bounds.position + half_view
	var maximum := _stage_bounds.end - half_view
	if maximum.x < minimum.x:
		minimum.x = _stage_bounds.get_center().x
		maximum.x = minimum.x
	if maximum.y < minimum.y:
		minimum.y = _stage_bounds.get_center().y
		maximum.y = minimum.y
	return Vector2(
		clampf(world_position.x, minimum.x, maximum.x),
		clampf(world_position.y, minimum.y, maximum.y),
	)


func shake(strength: float, duration := 0.15) -> void:
	if strength <= 0.0 or duration <= 0.0:
		return
	_shake_strength = maxf(_shake_strength, strength)
	_shake_remaining = maxf(_shake_remaining, duration)
	_shake_duration = maxf(_shake_duration, _shake_remaining)


func _update_shake(delta: float) -> void:
	if _shake_remaining <= 0.0:
		offset = _base_offset
		_shake_strength = 0.0
		_shake_duration = 0.0
		return

	var falloff := _shake_remaining / maxf(_shake_duration, 0.001)
	var amplitude := _shake_strength * falloff * falloff
	offset = _base_offset + Vector2(
		_random.randf_range(-amplitude, amplitude),
		_random.randf_range(-amplitude, amplitude)
	)
	_shake_remaining = maxf(_shake_remaining - delta, 0.0)
