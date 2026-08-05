extends Hitbox

@export_range(40.0, 1200.0, 10.0) var speed := 285.0
@export_range(0.1, 10.0, 0.1) var max_lifetime := 4.0

var travel_direction := Vector2.LEFT
var _life_remaining := 0.0
var _spent := false


func _ready() -> void:
	super()
	add_to_group(&"boss_projectiles")
	_life_remaining = max_lifetime
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not hit_landed.is_connected(_on_hit_landed):
		hit_landed.connect(_on_hit_landed)


func launch(direction: Vector2) -> void:
	travel_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.LEFT
	rotation = travel_direction.angle()


func _physics_process(delta: float) -> void:
	position += travel_direction * speed * delta
	_life_remaining -= delta
	if _life_remaining <= 0.0:
		_consume(false)


func _on_body_entered(_body: Node) -> void:
	_consume(true)


func _on_hit_landed(_hurtbox: Hurtbox) -> void:
	_consume(true)


func _consume(spawn_sparks: bool) -> void:
	if _spent:
		return
	_spent = true
	if spawn_sparks:
		var vfx := get_node_or_null("/root/VFXSpawner")
		if vfx != null:
			vfx.call(&"spawn_effect", &"sparks", global_position, -travel_direction)
	deactivate()
	set_deferred("monitoring", false)
	queue_free()
