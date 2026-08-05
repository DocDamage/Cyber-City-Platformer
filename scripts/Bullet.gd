extends Hitbox

const SPARK_VFX := preload("res://scenes/vfx/SparkBurst.tscn")

@export var speed := 400.0

var direction := 1
var _spent := false


func _ready() -> void:
	super()
	hit_landed.connect(_on_hit_landed)


func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta


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
		vfx.call(&"spawn_one_shot", SPARK_VFX, global_position, Vector2(-direction, 0.0))


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
