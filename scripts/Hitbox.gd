class_name Hitbox
extends Area2D

signal hit_landed(hurtbox: Hurtbox)

@export_range(0, 999, 1) var damage := 1
@export var active_on_ready := true
@export var single_hit_per_activation := true
@export_range(0.0, 1.0, 0.01) var hit_stop_duration := 0.0
@export_range(0.0, 32.0, 0.5) var camera_shake_strength := 0.0
@export_range(0.0, 1.0, 0.01) var camera_shake_duration := 0.12

var _active := false
var _activation_id := 0
var _hit_hurtboxes := {}


func _ready() -> void:
	_active = active_on_ready
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func activate(duration := 0.0) -> void:
	_activation_id += 1
	_hit_hurtboxes.clear()
	_active = true
	_scan_overlaps()
	if duration > 0.0:
		_deactivate_after(duration, _activation_id)


func deactivate() -> void:
	_activation_id += 1
	_active = false


func is_active() -> bool:
	return _active


func _deactivate_after(duration: float, activation_id: int) -> void:
	await get_tree().create_timer(duration).timeout
	if activation_id == _activation_id:
		_active = false


func _scan_overlaps() -> void:
	for area in get_overlapping_areas():
		if area is Hurtbox:
			try_hit(area as Hurtbox)


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		try_hit(area as Hurtbox)


func try_hit(hurtbox: Hurtbox) -> bool:
	if not _active or hurtbox == null:
		return false
	if single_hit_per_activation and _hit_hurtboxes.has(hurtbox):
		return false
	if not hurtbox.receive_hit(self):
		return false

	if single_hit_per_activation:
		_hit_hurtboxes[hurtbox] = true
	var feedback := get_node_or_null("/root/CombatFeedback")
	if feedback != null and hit_stop_duration > 0.0:
		feedback.call(&"hit_stop", hit_stop_duration)
	if feedback != null and camera_shake_strength > 0.0:
		feedback.call(&"camera_shake", camera_shake_strength, camera_shake_duration)
	hit_landed.emit(hurtbox)
	return true
