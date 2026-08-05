class_name VoidPit
extends Hazard


func _ready() -> void:
	hazard_id = &"void_pit"
	instant_kill = true
	active_duration = 0.0
	inactive_duration = 0.0
	telegraph_duration = 0.0
	knockback = Vector2.ZERO
	super()


func set_active(value: bool) -> void:
	super(value)
	var visual := get_node_or_null("HazardVisual") as Polygon2D
	if visual != null:
		visual.color = Color(0.02, 0.0, 0.09, 0.96) if is_active else visual.color
