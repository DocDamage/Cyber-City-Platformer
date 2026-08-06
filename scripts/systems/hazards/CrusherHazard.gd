class_name CrusherHazard
extends Node2D

@export_range(80.0, 500.0, 10.0) var travel_distance := 260.0
@export_range(0.2, 4.0, 0.05) var warning_time := 0.7
@export_range(0.1, 2.0, 0.05) var strike_time := 0.28
@export_range(0.2, 5.0, 0.05) var retract_time := 1.1
@export_range(0.0, 8.0, 0.05) var phase_offset := 0.0

var _origin := Vector2.ZERO
var _elapsed := 0.0
var _hazard: Hazard

const FACTORY_CRUSHER_PATH := "res://assets/runtime/props/TraversalKits/Generated/factory_crusher_bay_v1.png"


func _ready() -> void:
	add_to_group(&"crushers")
	_origin = position
	_elapsed = phase_offset
	_hazard = Hazard.new()
	_hazard.name = "CrusherFace"
	_hazard.hazard_id = &"crusher"
	_hazard.instant_kill = true
	_hazard.hazard_size = Vector2(150.0, 70.0)
	_hazard.active_duration = 0.0
	_hazard.inactive_duration = 0.0
	_hazard.telegraph_duration = 0.0
	add_child(_hazard)
	_ensure_architecture()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var cycle := warning_time + strike_time + retract_time
	var local_time := fposmod(_elapsed, cycle)
	if local_time < warning_time:
		_hazard.set_active(false)
		position = _origin
	elif local_time < warning_time + strike_time:
		_hazard.set_active(true)
		var weight := (local_time - warning_time) / strike_time
		position = _origin + Vector2.DOWN * travel_distance * weight * weight
	else:
		_hazard.set_active(false)
		var weight := (local_time - warning_time - strike_time) / retract_time
		position = _origin + Vector2.DOWN * travel_distance * (1.0 - smoothstep(0.0, 1.0, weight))


func reset_hazard() -> void:
	_elapsed = phase_offset
	position = _origin
	if _hazard != null:
		_hazard.reset_hazard()
		_hazard.set_active(false)


func _ensure_architecture() -> void:
	if TerrainPlatform.region_for_node(self) != "robot_factory" or get_node_or_null("MechanicArchitecture") != null:
		return
	if not ResourceLoader.exists(FACTORY_CRUSHER_PATH, "Texture2D"):
		push_error("Crusher presentation is missing: %s" % FACTORY_CRUSHER_PATH)
		return
	var texture := load(FACTORY_CRUSHER_PATH) as Texture2D
	if texture == null:
		push_error("Crusher presentation failed to load: %s" % FACTORY_CRUSHER_PATH)
		return
	var scale_factor := 0.40
	var sprite := Sprite2D.new()
	sprite.name = "MechanicArchitecture"
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = -1
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position = Vector2(-texture.get_width() * scale_factor * 0.5, -66.0 * scale_factor)
	sprite.set_meta(&"presentation_id", "factory_crusher_bay")
	add_child(sprite)
