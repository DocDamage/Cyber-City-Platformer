class_name ToxicPool
extends Hazard


func _ready() -> void:
	hazard_id = &"toxic_pool"
	active_duration = 0.0
	inactive_duration = 0.0
	telegraph_duration = 0.0
	knockback = Vector2(0.0, -120.0)
	super()


func set_active(value: bool) -> void:
	super(value)
	var visual := get_node_or_null("HazardVisual") as Polygon2D
	if visual != null:
		visual.color = Color(0.55, 0.05, 0.78, 0.82) if is_active else visual.color
