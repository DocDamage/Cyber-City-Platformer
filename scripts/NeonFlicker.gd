extends PointLight2D

@export var minimum_energy := 1.2
@export var maximum_energy := 1.8
@export var flicker_speed := 16.0

var target_energy := 1.5


func _process(delta: float) -> void:
	if randf() < flicker_speed * delta:
		target_energy = randf_range(minimum_energy, maximum_energy)
	energy = lerpf(energy, target_energy, minf(delta * 18.0, 1.0))
