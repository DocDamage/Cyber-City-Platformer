class_name BreakawayPlatform
extends StaticBody2D

@export var platform_size := Vector2(96.0, 18.0)
@export_range(0.1, 3.0, 0.1) var collapse_delay := 0.6
@export_range(0.5, 8.0, 0.1) var reset_delay := 2.5

var _collapsing := false
var _generation := 0
var _collision: CollisionShape2D
var _visual: TerrainSurfaceArt

const CITY_SKYBRIDGE_PATH := "res://assets/runtime/props/TraversalKits/Generated/cyber_skybridge_truss_v1.png"


func _ready() -> void:
	add_to_group(&"breakaway_platforms")
	_build_components()


func _on_body_entered(body: Node) -> void:
	if not _collapsing and body.is_in_group(&"player"):
		_collapse_cycle()


func _collapse_cycle() -> void:
	_collapsing = true
	_generation += 1
	var generation := _generation
	_visual.modulate = Color("ff7086")
	await get_tree().create_timer(collapse_delay).timeout
	if generation != _generation:
		return
	_collision.set_deferred("disabled", true)
	_visual.visible = false
	await get_tree().create_timer(reset_delay).timeout
	if generation != _generation:
		return
	_collision.set_deferred("disabled", false)
	_visual.visible = true
	_visual.modulate = Color.WHITE
	_collapsing = false


func reset_platform() -> void:
	_generation += 1
	_collapsing = false
	if _collision != null:
		_collision.set_deferred("disabled", false)
	if _visual != null:
		_visual.visible = true
		_visual.modulate = Color.WHITE


func _build_components() -> void:
	_collision = CollisionShape2D.new()
	_collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = platform_size
	_collision.shape = shape
	add_child(_collision)
	_visual = TerrainPlatform.create_surface_art(platform_size, TerrainPlatform.region_for_node(self), 0, TerrainPlatform.prefers_traversal_skin(self))
	if _visual != null:
		_visual.name = "Visual"
		_visual.set_meta(&"mechanic_role", "breakaway_platform")
		add_child(_visual)
	_ensure_architecture()
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	var sensor_shape := CollisionShape2D.new()
	var sensor_rectangle := RectangleShape2D.new()
	sensor_rectangle.size = platform_size + Vector2(0.0, 10.0)
	sensor_shape.shape = sensor_rectangle
	sensor.add_child(sensor_shape)
	add_child(sensor)
	sensor.body_entered.connect(_on_body_entered)


func _ensure_architecture() -> void:
	if TerrainPlatform.region_for_node(self) != "cyber_city" or get_node_or_null("MechanicArchitecture") != null:
		return
	if not ResourceLoader.exists(CITY_SKYBRIDGE_PATH, "Texture2D"):
		push_error("Breakaway platform presentation is missing: %s" % CITY_SKYBRIDGE_PATH)
		return
	var texture := load(CITY_SKYBRIDGE_PATH) as Texture2D
	if texture == null:
		push_error("Breakaway platform presentation failed to load: %s" % CITY_SKYBRIDGE_PATH)
		return
	var scale_factor := 0.28
	var surface_anchor := Vector2(0.0, -platform_size.y * 0.5)
	var sprite := Sprite2D.new()
	sprite.name = "MechanicArchitecture"
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = -1
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position = Vector2(surface_anchor.x - texture.get_width() * scale_factor * 0.5, surface_anchor.y - 48.0 * scale_factor)
	sprite.set_meta(&"presentation_id", "skybridge_breakaway")
	sprite.set_meta(&"surface_anchor", surface_anchor)
	add_child(sprite)
