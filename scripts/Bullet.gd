extends Hitbox

const SPEED := 400.0
const SPARK_VFX := preload("res://scenes/vfx/SparkBurst.tscn")

var direction := 1.0
var _spent := false


func _ready() -> void:
	super()
	hit_landed.connect(_on_hit_landed)


func _physics_process(delta: float) -> void:
	position.x += direction * SPEED * delta


func _on_body_entered(_body: Node) -> void:
	_consume(true)


func _on_hit_landed(_hurtbox: Hurtbox) -> void:
	_consume(true)


func _consume(spawn_impact := false) -> void:
	if _spent:
		return
	_spent = true
	if spawn_impact:
		_spawn_sparks()
	deactivate()
	set_deferred("monitoring", false)
	queue_free()


func _spawn_sparks() -> void:
	var sparks := SPARK_VFX.instantiate()
	sparks.global_position = global_position
	sparks.rotation = PI if direction > 0.0 else 0.0
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(sparks)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
