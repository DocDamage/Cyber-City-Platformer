extends Hitbox

const SPARK_VFX := preload("res://scenes/vfx/SparkBurst.tscn")

@export var speed := 400.0
@export_range(0.1, 10.0, 0.1) var max_lifetime := 3.0

var direction: Variant = Vector2.RIGHT
var _spent := false
var _lifetime := 0.0


func _ready() -> void:
	super()
	hit_landed.connect(_on_hit_landed)


func _physics_process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= max_lifetime:
		_consume()
		return
	var travel_direction: Vector2 = (direction as Vector2).normalized() if direction is Vector2 else Vector2(float(direction), 0.0).normalized()
	position += travel_direction * speed * delta


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
	var vfx := get_node_or_null("/root/VFXSpawner")
	if vfx != null:
		var travel_direction: Vector2 = (direction as Vector2).normalized() if direction is Vector2 else Vector2(float(direction), 0.0).normalized()
		vfx.call(&"spawn_one_shot", SPARK_VFX, global_position, -travel_direction)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
