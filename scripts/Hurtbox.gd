class_name Hurtbox
extends Area2D

signal hit_received(hitbox: Hitbox, damage: int)

@export var damage_receiver: NodePath
@export_range(0.0, 5.0, 0.01) var invincibility_duration := 0.12

var _invincible := false
var _invincibility_generation := 0


func _ready() -> void:
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func receive_hit(hitbox: Hitbox) -> bool:
	if _invincible or hitbox == null or hitbox.damage <= 0:
		return false

	var receiver := _get_damage_receiver()
	if receiver == null or not receiver.has_method(&"take_damage"):
		return false

	var result: Variant = receiver.call(&"take_damage", hitbox.damage)
	if result is bool and not result:
		return false
	hit_received.emit(hitbox, hitbox.damage)
	if invincibility_duration > 0.0:
		start_invincibility(invincibility_duration)
	return true


func set_invincible(value: bool) -> void:
	_invincibility_generation += 1
	_invincible = value
	set_deferred("monitoring", not value)
	set_deferred("monitorable", not value)


func is_invincible() -> bool:
	return _invincible


func start_invincibility(duration := invincibility_duration) -> void:
	if duration <= 0.0:
		return
	_invincibility_generation += 1
	var generation := _invincibility_generation
	_invincible = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	_end_invincibility_after(duration, generation)


func _end_invincibility_after(duration: float, generation: int) -> void:
	await get_tree().create_timer(duration, true, false, true).timeout
	if generation != _invincibility_generation:
		return
	_invincible = false
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)


func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		(area as Hitbox).try_hit(self)


func _get_damage_receiver() -> Node:
	if not damage_receiver.is_empty():
		return get_node_or_null(damage_receiver)
	return get_parent()
