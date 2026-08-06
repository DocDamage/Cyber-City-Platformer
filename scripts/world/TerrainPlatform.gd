class_name TerrainPlatform
extends StaticBody2D

const SKINS := {
	"cyber_city": {
		"texture": "res://assets/runtime/environments/Act1_CyberCity/Rooftops 2/Environment/tileset.png",
		"cell": 16,
		"top_left": Vector2i(0, 1),
		"top_middle": Vector2i(1, 1),
		"top_right": Vector2i(2, 1),
		"fill": Vector2i(2, 2),
		"visual_depth_cells": 2,
	},
	"robot_factory": {
		"texture": "res://assets/runtime/environments/Act2_RobotFactory/Mega Robot Factory/CENA (!)/TILESET/Tileset.png",
		"cell": 32,
		"top_left": Vector2i(6, 0),
		"top_middle": Vector2i(7, 0),
		"top_right": Vector2i(8, 0),
		"fill": Vector2i(9, 4),
		"visual_depth_cells": 3,
	},
	"neon_moon": {
		"texture": "res://assets/runtime/environments/Act3_NeonMoon/Neon Moon Protocol/Trerrain/Terrain 24x24 (1).png",
		"cell": 24,
		"top_left": Vector2i(4, 30),
		"top_middle": Vector2i(5, 30),
		"top_right": Vector2i(6, 30),
		"fill": Vector2i(6, 9),
		"visual_depth_cells": 3,
	},
	"abyssal_night": {
		"texture": "res://assets/runtime/environments/Act4_AbyssalNight/Abyssal Night/Abyssal Night – Color (2)/Trerrain/Terrain 24x24 (1).png",
		"cell": 24,
		"top_left": Vector2i(6, 30),
		"top_middle": Vector2i(7, 30),
		"top_right": Vector2i(8, 30),
		"fill": Vector2i(8, 9),
		"visual_depth_cells": 3,
	},
}

# The original generated catwalk is intentionally limited to the legacy Act 1
# authored traversal set. World-room terrain remains native to its supplied
# environment sheet, which keeps the 202-room art contract independent from
# this remaster.
const TRAVERSAL_SKINS := {
	"cyber_city": {
		"texture": "res://assets/runtime/props/TraversalKits/Generated/cyber_rooftop_catwalk_v1.png",
		"cell": 16,
		"top_left": Rect2(176, 118, 16, 16),
		"top_middle": Rect2(176, 118, 16, 16),
		"top_right": Rect2(176, 118, 16, 16),
		"fill": Rect2(176, 134, 16, 16),
		"visual_depth_cells": 2,
	},
}

var world_rect := Rect2()
var visual_rect := Rect2()


func configure(rect: Rect2, region_id: String, district_id: String) -> void:
	world_rect = rect
	visual_rect = rect
	position = rect.get_center()
	name = "TerrainPlatform"
	set_meta(&"world_rect", rect)
	set_meta(&"visual_rect", rect)
	set_meta(&"district_id", district_id)
	set_meta(&"region_id", region_id)
	_build_collision(rect.size)
	_build_art(rect.size, region_id)


func _build_collision(size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	collision.name = "Collision"
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	add_child(collision)
	set_meta(&"collision_size", size)


func _build_art(size: Vector2, region_id: String) -> void:
	var art := create_surface_art(size, region_id)
	if art != null:
		add_child(art)


static func create_surface_art(size: Vector2, region_id: String, visual_depth_cells_override := 0, use_traversal_skin := false) -> TerrainSurfaceArt:
	var skin_catalog: Dictionary = TRAVERSAL_SKINS if use_traversal_skin and TRAVERSAL_SKINS.has(region_id) else SKINS
	var skin: Dictionary = skin_catalog.get(region_id, SKINS["cyber_city"])
	var path := String(skin.get("texture", ""))
	if not ResourceLoader.exists(path, "Texture2D"):
		push_error("Terrain platform is missing art texture %s." % path)
		return null
	var texture := load(path) as Texture2D
	var cell := float(skin.get("cell", 16))
	var half := size * 0.5
	var visual_depth_cells := int(skin.get("visual_depth_cells", 1))
	if visual_depth_cells_override > 0:
		visual_depth_cells = visual_depth_cells_override
	var art_size := Vector2(size.x, maxf(size.y, cell * float(visual_depth_cells)))
	var art := TerrainSurfaceArt.new()
	art.name = "TerrainArt"
	art.position = -half
	art.configure(art_size, texture, {
		"fill": _skin_region(skin.get("fill", Vector2i.ZERO), cell),
		"top_left": _skin_region(skin.get("top_left", Vector2i.ZERO), cell),
		"top_middle": _skin_region(skin.get("top_middle", Vector2i.ZERO), cell),
		"top_right": _skin_region(skin.get("top_right", Vector2i.ZERO), cell),
	}, cell, path)
	art.set_meta(&"collision_surface_y", -half.y)
	art.set_meta(&"visual_surface_y", art.position.y)
	return art


static func region_for_node(start: Node) -> String:
	var node := start
	while node != null:
		if node is WorldRoom:
			return String((node as WorldRoom).definition.get("region_id", "cyber_city"))
		if node is CampaignStage:
			return {1:"cyber_city", 2:"robot_factory", 3:"neon_moon", 4:"abyssal_night"}.get((node as CampaignStage).campaign_act, "cyber_city")
		node = node.get_parent()
	return "cyber_city"


static func prefers_traversal_skin(start: Node) -> bool:
	var node := start
	while node != null:
		if node is CampaignStage:
			return (node as CampaignStage).campaign_act == 1
		node = node.get_parent()
	return false


static func _tile_region(atlas_coordinate: Vector2i, cell: float) -> Rect2:
	return Rect2(Vector2(atlas_coordinate) * cell, Vector2(cell, cell))


static func _skin_region(value: Variant, cell: float) -> Rect2:
	if value is Rect2:
		return value as Rect2
	if value is Vector2i:
		return _tile_region(value as Vector2i, cell)
	return Rect2(Vector2.ZERO, Vector2(cell, cell))
