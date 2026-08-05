class_name DestructibleSwitch
extends Node2D

signal destroyed(switch_id: StringName)

@export var switch_id: StringName = &"destructible_switch"
@export_range(1, 20, 1) var max_health := 3

var linked_targets: Array[Node] = []
var health := 0
var _destroyed := false
var _visual: Polygon2D


func _ready() -> void:
	add_to_group(&"destructible_switches")
	health = max_health
	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([Vector2(-28, -32), Vector2(28, -32), Vector2(36, 0), Vector2(20, 35), Vector2(-24, 30), Vector2(-36, 0)])
	_visual.color = Color("a62cff")
	add_child(_visual)
	var hurtbox := Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 4
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(72, 72)
	collision.shape = shape
	hurtbox.add_child(collision)
	add_child(hurtbox)


func take_damage(amount: int) -> bool:
	if _destroyed or amount <= 0:
		return false
	health = maxi(health - amount, 0)
	_visual.modulate = Color.WHITE
	create_tween().tween_property(_visual, "modulate", Color.WHITE.lerp(Color("a62cff"), 0.8), 0.12)
	if health == 0:
		_destroy()
	return true


func link_target(target: Node) -> void:
	if target != null and not linked_targets.has(target):
		linked_targets.append(target)


func reset_switch() -> void:
	if _destroyed:
		return
	health = max_health


func _destroy() -> void:
	_destroyed = true
	for target: Node in linked_targets:
		if target.has_method(&"request_open"):
			target.call(&"request_open", switch_id)
	destroyed.emit(switch_id)
	queue_free()
