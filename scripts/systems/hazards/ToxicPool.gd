class_name ToxicPool
extends Hazard


func _ready() -> void:
	hazard_id = &"toxic_pool"
	active_duration = 0.0
	inactive_duration = 0.0
	telegraph_duration = 0.0
	knockback = Vector2(0.0, -120.0)
	super()
