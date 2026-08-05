extends Area2D

@export_file("*.tscn") var next_scene_path := "res://scenes/Level2.tscn"
var _triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	$Chevron.modulate.a = 0.55 + sin(Time.get_ticks_msec() * 0.005) * 0.3
	$Chevron.position.y = sin(Time.get_ticks_msec() * 0.003) * 4.0


func _on_body_entered(body: Node) -> void:
	if _triggered or not body.is_in_group(&"player"):
		return
	_triggered = true
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.call(&"change_level", next_scene_path)
	else:
		get_tree().change_scene_to_file(next_scene_path)
