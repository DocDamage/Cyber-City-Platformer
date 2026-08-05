class_name StageExit
extends Area2D

signal entered
signal lock_changed(locked: bool)

@export_file("*.tscn") var next_scene_path := ""
@export var starts_locked := false

var _triggered := false
var is_locked := false


func _ready() -> void:
	add_to_group(&"stage_exits")
	body_entered.connect(_on_body_entered)
	set_locked(starts_locked)


func _process(_delta: float) -> void:
	var chevron := get_node_or_null("Chevron") as CanvasItem
	if chevron == null:
		return
	chevron.modulate.a = 0.55 + sin(Time.get_ticks_msec() * 0.005) * 0.3
	if chevron is Node2D:
		(chevron as Node2D).position.y = sin(Time.get_ticks_msec() * 0.003) * 4.0


func _on_body_entered(body: Node) -> void:
	if is_locked or _triggered or not body.is_in_group(&"player"):
		return
	_triggered = true
	entered.emit()
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		if next_scene_path.is_empty():
			manager.call(&"advance_stage")
		else:
			manager.call(&"change_level", next_scene_path)
	elif not next_scene_path.is_empty():
		get_tree().change_scene_to_file(next_scene_path)


func set_locked(value: bool) -> void:
	if is_locked == value and monitoring == not value:
		return
	is_locked = value
	set_deferred("monitoring", not is_locked)
	var label := get_node_or_null("Label") as Label
	if label != null:
		label.text = "DEFEAT BOSS" if is_locked else "STAGE EXIT"
	var chevron := get_node_or_null("Chevron") as CanvasItem
	if chevron != null:
		chevron.modulate = Color(1.0, 0.2, 0.35, 0.45) if is_locked else Color.WHITE
	lock_changed.emit(is_locked)
