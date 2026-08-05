class_name AuthoredTraversal
extends Node2D

var section_id: StringName
var section_kind: StringName
var optional_route := false
var _platforms: Array[StaticBody2D] = []


func configure(entry: Dictionary) -> void:
	section_id = StringName(entry.get("id", "traversal"))
	section_kind = StringName(entry.get("kind", "jump_steps"))
	optional_route = bool(entry.get("optional", false))
	name = "Traversal_%s" % section_id
	position = entry.get("position", Vector2.ZERO)
	_build_layout(float(entry.get("height", 420.0)))


func get_descriptor() -> Dictionary:
	return {"id": String(section_id), "kind": String(section_kind), "optional": optional_route, "platform_count": _platforms.size()}


func _ready() -> void:
	add_to_group(&"authored_traversal")


func _build_layout(height: float) -> void:
	match section_kind:
		&"wall_jump_shaft":
			_add_platform(Vector2(-82, -height * 0.5), Vector2(24, height), Color("27566d"))
			_add_platform(Vector2(82, -height * 0.5), Vector2(24, height), Color("27566d"))
			_add_platform(Vector2(0, -height), Vector2(190, 20), Color("26d9ef"))
		&"vertical_route":
			_add_platform(Vector2(-145, -80), Vector2(150, 18))
			_add_platform(Vector2(90, -180), Vector2(135, 18))
			_add_platform(Vector2(-90, -290), Vector2(135, 18))
			_add_platform(Vector2(150, -390), Vector2(160, 18))
		&"high_route":
			_add_platform(Vector2(-240, -80), Vector2(150, 18))
			_add_platform(Vector2(-70, -155), Vector2(130, 18))
			_add_platform(Vector2(105, -205), Vector2(130, 18))
			_add_platform(Vector2(270, -125), Vector2(150, 18))
		&"dash_gap", &"long_gap", &"low_gravity_gap":
			_add_platform(Vector2(-210, -75), Vector2(190, 18))
			_add_platform(Vector2(210, -75), Vector2(190, 18))
		&"moving_platform_route":
			_add_platform(Vector2(-280, -40), Vector2(180, 18))
			_add_platform(Vector2(280, -120), Vector2(180, 18))
		&"conveyor_route":
			_add_platform(Vector2(-210, -70), Vector2(170, 18))
			_add_platform(Vector2(0, -125), Vector2(150, 18))
			_add_platform(Vector2(210, -70), Vector2(170, 18))
		&"hazard_steps":
			_add_platform(Vector2(-190, -40), Vector2(115, 18))
			_add_platform(Vector2(0, -95), Vector2(115, 18))
			_add_platform(Vector2(190, -40), Vector2(115, 18))
		_:
			_add_platform(Vector2(-150, -45), Vector2(130, 18))
			_add_platform(Vector2(0, -95), Vector2(130, 18))
			_add_platform(Vector2(150, -45), Vector2(130, 18))
	if optional_route:
		var label := Label.new()
		label.text = "OPTIONAL ROUTE"
		label.position = Vector2(-58, -250)
		label.add_theme_color_override("font_color", Color("ffc857"))
		add_child(label)


func _add_platform(local_position: Vector2, size: Vector2, color := Color("315d78")) -> void:
	var platform := StaticBody2D.new()
	platform.position = local_position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	platform.add_child(collision)
	var half := size * 0.5
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	visual.color = color
	platform.add_child(visual)
	add_child(platform)
	_platforms.append(platform)
