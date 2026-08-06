class_name TeleportController
extends Node2D

signal aim_started
signal aim_changed(direction: Vector2)
signal marker_thrown(marker: TeleportMarker)
signal marker_attached(valid: bool, destination: Vector2, reason: StringName)
signal marker_recalled
signal teleport_completed(destination: Vector2)
signal teleport_failed(reason: StringName)

enum MarkerState { READY, AIMING, FLYING, ATTACHED }

const MARKER_SCENE := preload("res://scenes/Player/TeleportMarker.tscn")

@export var throw_speed := 620.0
@export var maximum_range := 420.0
@export_range(0.0, 1.0, 0.01) var aim_deadzone := 0.22
@export var trajectory_length := 150.0

var state := MarkerState.READY
var aim_direction := Vector2.RIGHT
var destination := Vector2.ZERO
var destination_valid := false
var rejection_reason: StringName = &""
var marker: TeleportMarker
var resolver: TeleportDestinationResolver
var _player: CharacterBody2D
var _ignore_next_release := false


func _ready() -> void:
	resolver = TeleportDestinationResolver.new()
	resolver.name = "DestinationResolver"
	add_child(resolver)
	set_process(false)
	queue_redraw()


func configure(player: CharacterBody2D) -> bool:
	_player = player
	return resolver.configure(player)


func _process(delta: float) -> void:
	if state != MarkerState.AIMING or _player == null:
		return
	var stick := Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	var settings := get_node_or_null("/root/SettingsManager")
	var mouse_direction := (_player.get_global_mouse_position() - _player.global_position).normalized()
	var next_direction := filtered_aim_direction(stick, mouse_direction, delta)
	var assist := float(settings.call(&"get_setting", &"aim_assist_strength", 0.25)) if settings != null else 0.25
	if assist > 0.0 and not next_direction.is_zero_approx():
		var snapped_angle := snappedf(next_direction.angle(), PI / 4.0)
		next_direction = next_direction.normalized().lerp(Vector2.from_angle(snapped_angle), assist).normalized()
	if not next_direction.is_zero_approx():
		aim_direction = next_direction.normalized()
		aim_changed.emit(aim_direction)
		queue_redraw()


func filtered_aim_direction(stick: Vector2, mouse_direction: Vector2, delta: float) -> Vector2:
	var settings := get_node_or_null("/root/SettingsManager")
	var deadzone := float(settings.call(&"get_setting", &"aim_deadzone", aim_deadzone)) if settings != null else aim_deadzone
	var active_family := StringName(settings.call(&"get_active_input_family")) if settings != null else &"keyboard_mouse"
	if stick.length() < deadzone:
		return aim_direction if active_family == &"controller" else mouse_direction.normalized()
	var target := stick.normalized()
	var response := float(settings.call(&"get_setting", &"aim_response", 0.72)) if settings != null else 0.72
	var frame_scale := clampf(delta * 60.0, 0.0, 4.0)
	var blend := 1.0 - pow(1.0 - response, frame_scale)
	return aim_direction.lerp(target, clampf(blend, 0.0, 1.0)).normalized()


func handle_teleport_pressed() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	var tap_mode := settings != null and String(settings.call(&"get_setting", &"teleport_aim_behavior", "hold")) == "tap"
	match state:
		MarkerState.READY:
			begin_aim()
		MarkerState.AIMING:
			if tap_mode:
				throw_marker()
		MarkerState.FLYING:
			recall_marker()
		MarkerState.ATTACHED:
			_ignore_next_release = true
			warp_to_marker()


func handle_teleport_released() -> void:
	if _ignore_next_release:
		_ignore_next_release = false
		return
	var settings := get_node_or_null("/root/SettingsManager")
	var tap_mode := settings != null and String(settings.call(&"get_setting", &"teleport_aim_behavior", "hold")) == "tap"
	if state == MarkerState.AIMING and not tap_mode:
		throw_marker()


func begin_aim(direction := Vector2.ZERO) -> bool:
	if state != MarkerState.READY or _player == null:
		return false
	state = MarkerState.AIMING
	if not direction.is_zero_approx():
		aim_direction = direction.normalized()
	elif not is_zero_approx(_player.get("facing_direction")):
		aim_direction = Vector2(float(_player.get("facing_direction")), 0.0)
	set_process(true)
	if _player.has_method(&"enter_teleport_aim"):
		_player.call(&"enter_teleport_aim")
	aim_started.emit()
	queue_redraw()
	return true


func throw_marker() -> bool:
	if state != MarkerState.AIMING or _player == null:
		return false
	set_process(false)
	state = MarkerState.FLYING
	marker = MARKER_SCENE.instantiate() as TeleportMarker
	var parent := _player.get_parent()
	parent.add_child(marker)
	marker.attached.connect(_on_marker_attached)
	marker.failed.connect(_on_marker_failed)
	marker.tree_exiting.connect(_on_marker_tree_exiting)
	marker.launch(_player.global_position + Vector2(0.0, -12.0), aim_direction * throw_speed, maximum_range)
	if _player.has_method(&"exit_teleport_aim"):
		_player.call(&"exit_teleport_aim", true)
	marker_thrown.emit(marker)
	queue_redraw()
	return true


func warp_to_marker() -> bool:
	if state != MarkerState.ATTACHED or not destination_valid or _player == null:
		teleport_failed.emit(rejection_reason if not rejection_reason.is_empty() else &"invalid_destination")
		return false
	var final_check := resolver.validate_position(destination)
	if not bool(final_check.valid):
		rejection_reason = StringName(final_check.reason)
		destination_valid = false
		teleport_failed.emit(rejection_reason)
		return false
	var target := Vector2(final_check.position)
	if not _player.call(&"teleport_to_destination", target):
		teleport_failed.emit(&"player_rejected")
		return false
	recall_marker(false)
	teleport_completed.emit(target)
	return true


func recall_marker(emit_signal := true) -> void:
	if marker != null and is_instance_valid(marker):
		marker.queue_free()
	marker = null
	state = MarkerState.READY
	destination = Vector2.ZERO
	destination_valid = false
	rejection_reason = &""
	set_process(false)
	queue_redraw()
	if emit_signal:
		marker_recalled.emit()


func cancel_all() -> void:
	if state == MarkerState.AIMING and _player != null and _player.has_method(&"exit_teleport_aim"):
		_player.call(&"exit_teleport_aim", false)
	recall_marker()


func _on_marker_attached(anchor: Vector2, normal: Vector2) -> void:
	state = MarkerState.ATTACHED
	var result := resolver.resolve(anchor, normal)
	destination_valid = bool(result.valid)
	destination = Vector2(result.position)
	rejection_reason = StringName(result.reason)
	marker_attached.emit(destination_valid, destination, rejection_reason)
	queue_redraw()


func _on_marker_failed(reason: StringName) -> void:
	teleport_failed.emit(reason)
	recall_marker(false)


func _on_marker_tree_exiting() -> void:
	if state == MarkerState.FLYING:
		state = MarkerState.READY
		marker = null
		queue_redraw()


func _draw() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	var high_contrast := settings != null and bool(settings.call(&"get_setting", &"high_contrast_teleport_reticle", false))
	var aim_color := Color("fff46b") if high_contrast else Color(0.3, 0.95, 1.0, 0.8)
	if state == MarkerState.AIMING:
		draw_dashed_line(Vector2(0.0, -12.0), Vector2(0.0, -12.0) + aim_direction * trajectory_length, aim_color, 3.0 if high_contrast else 2.0, 7.0)
		draw_circle(Vector2(0.0, -12.0) + aim_direction * trajectory_length, 9.0 if high_contrast else 7.0, aim_color, false, 3.0)
	elif state == MarkerState.ATTACHED and _player != null:
		var local_destination := to_local(destination)
		var color := (Color("fff46b") if destination_valid else Color.WHITE) if high_contrast else (Color("58f0b4") if destination_valid else Color("ff526f"))
		draw_circle(local_destination, 15.0, color, false, 3.0)
		draw_line(local_destination + Vector2(-8, 0), local_destination + Vector2(8, 0), color, 2.0)
		draw_line(local_destination + Vector2(0, -8), local_destination + Vector2(0, 8), color, 2.0)
