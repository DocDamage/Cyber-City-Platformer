class_name ElectricalFloor
extends Hazard


func _ready() -> void:
	hazard_id = &"electrical_floor"
	knockback = Vector2(120.0, -190.0)
	telegraph_duration = maxf(telegraph_duration, 0.3)
	super()
