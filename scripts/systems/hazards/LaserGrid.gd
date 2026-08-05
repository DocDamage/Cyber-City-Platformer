class_name LaserGrid
extends Hazard


func _ready() -> void:
	hazard_id = &"laser_grid"
	knockback = Vector2(240.0, -110.0)
	telegraph_duration = maxf(telegraph_duration, 0.4)
	super()


func set_active(value: bool) -> void:
	super(value)
	var visual := get_node_or_null("HazardVisual") as Polygon2D
	if visual != null:
		visual.color = Color(1.0, 0.05, 0.65, 0.92) if is_active else visual.color
