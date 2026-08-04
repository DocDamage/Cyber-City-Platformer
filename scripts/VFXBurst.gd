extends GPUParticles2D


func _ready() -> void:
	emitting = true
	_finished_later()


func _finished_later() -> void:
	await get_tree().create_timer(lifetime + 0.15).timeout
	queue_free()
