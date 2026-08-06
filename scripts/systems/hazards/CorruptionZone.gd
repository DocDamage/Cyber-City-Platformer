class_name CorruptionZone
extends Hazard

@export_range(1.0, 50.0, 1.0) var exposure_per_tick := 18.0


func _ready() -> void:
	hazard_id = &"corruption_zone"
	knockback = Vector2(70.0, -90.0)
	telegraph_duration = maxf(telegraph_duration, 0.5)
	super()


func _damage_body(body: Node2D) -> void:
	var valid_target := body.is_in_group(&"player") or (affects_enemies and body.is_in_group(&"enemies"))
	if not valid_target or float(_damage_cooldowns.get(body, 0.0)) > 0.0:
		return
	_damage_cooldowns[body] = 0.55
	if body.has_method(&"apply_corruption"):
		body.call(&"apply_corruption", exposure_per_tick)
	var game := get_node_or_null("/root/GameManager")
	var resisted: bool = body.is_in_group(&"player") and game != null and game.abilities.has(&"corruption_resistance")
	if not resisted and damage > 0 and body.has_method(&"take_damage"):
		var accepted: Variant = body.call(&"take_damage", damage)
		if accepted is bool and not accepted:
			_damage_cooldowns.erase(body)
			return
	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity += knockback
