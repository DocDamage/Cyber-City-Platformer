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
