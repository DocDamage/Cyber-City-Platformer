extends GPUParticles2D

@export_range(0.0, 2.0, 0.05) var cleanup_padding := 0.2


func _ready() -> void:
	one_shot = true
	if not finished.is_connected(_on_finished):
		finished.connect(_on_finished, CONNECT_ONE_SHOT)
	restart()
	_cleanup_fallback()


func _on_finished() -> void:
	queue_free()


func _cleanup_fallback() -> void:
	await get_tree().create_timer(preprocess + lifetime + cleanup_padding).timeout
	if is_instance_valid(self):
		queue_free()
