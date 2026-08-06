class_name LaserGrid
extends Hazard


func _ready() -> void:
	hazard_id = &"laser_grid"
	knockback = Vector2(240.0, -110.0)
	telegraph_duration = maxf(telegraph_duration, 0.4)
	super()
