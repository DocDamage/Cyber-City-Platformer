class_name SteamVent
extends Hazard


func _ready() -> void:
	hazard_id = &"steam_vent"
	knockback = Vector2(90.0, -310.0)
	telegraph_duration = maxf(telegraph_duration, 0.55)
	super()
