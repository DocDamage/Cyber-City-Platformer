class_name Hurtbox
extends Area2D

signal hit_received(hitbox: Hitbox, damage: int)

@export var damage_receiver: NodePath

var _invincible := false


func receive_hit(hitbox: Hitbox) -> bool:
	if _invincible or hitbox == null or hitbox.damage <= 0:
		return false

	var receiver := _get_damage_receiver()
	if receiver == null or not receiver.has_method(&"take_damage"):
		return false

	receiver.call(&"take_damage", hitbox.damage)
	hit_received.emit(hitbox, hitbox.damage)
	return true


func set_invincible(value: bool) -> void:
	_invincible = value
	set_deferred("monitorable", not value)


func is_invincible() -> bool:
	return _invincible


func _get_damage_receiver() -> Node:
	if not damage_receiver.is_empty():
		return get_node_or_null(damage_receiver)
	return get_parent()
