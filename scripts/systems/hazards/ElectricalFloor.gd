class_name ElectricalFloor
extends Hazard


func _ready() -> void:
	hazard_id = &"electrical_floor"
	knockback = Vector2(120.0, -190.0)
	telegraph_duration = maxf(telegraph_duration, 0.3)
	super()


func set_active(value: bool) -> void:
	super(value)
	var visual := get_node_or_null("HazardVisual") as Polygon2D
	if visual != null and is_active:
		visual.color = Color(0.1, 0.9, 1.0, 0.94)
