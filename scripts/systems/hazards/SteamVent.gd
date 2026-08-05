class_name SteamVent
extends Hazard


func _ready() -> void:
	hazard_id = &"steam_vent"
	knockback = Vector2(90.0, -310.0)
	telegraph_duration = maxf(telegraph_duration, 0.55)
	super()


func set_active(value: bool) -> void:
	super(value)
	var visual := get_node_or_null("HazardVisual") as Polygon2D
	if visual != null and is_active:
		visual.color = Color(0.78, 0.95, 1.0, 0.78)
