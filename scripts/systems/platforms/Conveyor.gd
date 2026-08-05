class_name Conveyor
extends StaticBody2D

@export_range(-400.0, 400.0, 10.0) var speed := 115.0
@export var reversible := false
@export_range(0.5, 10.0, 0.1) var reverse_interval := 3.0
@export_range(0.0, 10.0, 0.1) var active_interval := 0.0
@export_range(0.0, 10.0, 0.1) var inactive_interval := 0.0
@export var hazardous := false
@export_range(1, 10, 1) var hazard_damage := 1
@export var starts_active := true
@export var conveyor_size := Vector2(180.0, 22.0)

var _elapsed := 0.0
var _direction := 1.0
var _active := true
var _hazard: Hazard


func _ready() -> void:
	add_to_group(&"conveyors")
	_active = starts_active
	_ensure_components()
	_apply_velocity()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if active_interval > 0.0 and inactive_interval > 0.0:
		var period := active_interval + inactive_interval
		set_active(fposmod(_elapsed, period) < active_interval)
	if reversible and _elapsed >= reverse_interval:
		_elapsed = 0.0
		_direction *= -1.0
		_apply_velocity()
		_play_motion_cue()


func _apply_velocity() -> void:
	constant_linear_velocity = Vector2(speed * _direction, 0.0) if _active else Vector2.ZERO
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		visual.color = (Color("ff4fd8") if _direction > 0.0 else Color("7a5cff")) if _active else Color("34394f")
	var arrow := get_node_or_null("DirectionArrow") as Label
	if arrow != null:
		arrow.text = (">>>" if _direction > 0.0 else "<<<") if _active else "---"
	if _hazard != null:
		_hazard.set_active(_active)


func set_active(value: bool) -> void:
	if _active == value:
		return
	_active = value
	_apply_velocity()
	_play_motion_cue()


func reverse() -> void:
	_direction *= -1.0
	_elapsed = 0.0
	_apply_velocity()
	_play_motion_cue()


func reset_conveyor() -> void:
	_elapsed = 0.0
	_direction = 1.0
	_active = starts_active
	_apply_velocity()


func _play_motion_cue() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call(&"play_sfx", &"conveyor", global_position, -11.0)


func _ensure_components() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = conveyor_size
		collision.shape = shape
		add_child(collision)
	var half := conveyor_size * 0.5
	if get_node_or_null("Visual") == null:
		var visual := Polygon2D.new()
		visual.name = "Visual"
		visual.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
		visual.color = Color("ff4fd8")
		add_child(visual)
	var arrow := Label.new()
	arrow.name = "DirectionArrow"
	arrow.position = Vector2(-24.0, -13.0)
	arrow.add_theme_color_override("font_color", Color.WHITE)
	add_child(arrow)
	if hazardous:
		_hazard = Hazard.new()
		_hazard.name = "BeltHazard"
		_hazard.hazard_id = &"hazard_conveyor"
		_hazard.damage = hazard_damage
		_hazard.hazard_size = conveyor_size + Vector2(0.0, 16.0)
		_hazard.active_duration = 0.0
		_hazard.inactive_duration = 0.0
		_hazard.position.y = -12.0
		add_child(_hazard)
