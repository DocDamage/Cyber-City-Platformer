extends Node

var _hit_stop_token := 0
var _restore_time_scale := 1.0


func hit_stop(duration := 0.05) -> void:
	if duration <= 0.0:
		return

	_hit_stop_token += 1
	var current_token := _hit_stop_token
	if Engine.time_scale > 0.0:
		_restore_time_scale = Engine.time_scale
	Engine.time_scale = 0.0

	await get_tree().create_timer(duration, true, false, true).timeout
	if current_token == _hit_stop_token:
		Engine.time_scale = _restore_time_scale


func camera_shake(strength: float, duration := 0.15) -> void:
	if strength <= 0.0 or duration <= 0.0:
		return
	var settings := get_node_or_null("/root/SettingsManager")
	var intensity := float(settings.call(&"get_setting", &"screen_shake_intensity", 1.0)) if settings != null else 1.0
	if intensity <= 0.0:
		return
	get_tree().call_group(&"game_camera", &"shake", strength * intensity, duration)


func _exit_tree() -> void:
	Engine.time_scale = _restore_time_scale
