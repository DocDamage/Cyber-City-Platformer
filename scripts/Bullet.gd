extends Area2D

const SPEED := 400.0

var direction := 1.0
@export var damage := 1
var _spent := false


func _physics_process(delta: float) -> void:
	position.x += direction * SPEED * delta


func _on_body_entered(body: Node) -> void:
	_hit_target(body)


func _on_area_entered(area: Area2D) -> void:
	var target := area.get_parent()
	_hit_target(target)


func _hit_target(target: Node) -> void:
	if _spent:
		return
	_spent = true
	if target.has_method(&"take_damage"):
		target.call(&"take_damage", damage)
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
