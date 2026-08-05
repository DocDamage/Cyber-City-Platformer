extends StageBase

const ROOF_LEFT := Vector2i(0, 0)
const ROOF_MIDDLE := Vector2i(1, 0)
const ROOF_RIGHT := Vector2i(2, 0)
const BACKGROUND_NODE_PATHS := [
	^"Background Skyline/Cyberpunk City Sunset",
	^"Background Skyline/Distant Silhouette",
	^"Background Skyline/Neon Skyline",
	^"Background Skyline/Near City",
	^"Background Skyline/Reflections",
]

@export_enum("Rooftops:0", "Factory Approach:1") var layout_variant := 0
@export_range(1, 4, 1) var campaign_act := 1
@export var background_texture_names := PackedStringArray([
	"Cyber City/Cyber City/Backgroud/BACKGROUND (6)/Backgroud (6) 1.png",
	"Cyber City/Cyber City/Backgroud/BACKGROUND (5)/Backgroud (5) 1.png",
	"Cyber City/Cyber City/Backgroud/BACKGROUND (3)/Backgroud (3) 1.png",
	"Cyber City/Cyber City/Backgroud/BACKGROUND (2)/Backgroud (2) 1.png",
	"Cyber City/Cyber City/Backgroud/BACKGROUND (1)/Backgroud (1) 1.png",
])
@export var level_id: StringName = &"rooftops_01"
@export_file("*.ogg") var music_path := "res://assets/runtime/audio/music/Rooftops/Cyberpunk Rooftops.ogg"

@onready var terrain: TileMapLayer = $"Rooftop Terrain"


func _ready() -> void:
	super()
	_apply_campaign_background()
	_paint_rooftop_layout()


func _apply_campaign_background() -> void:
	var registry := get_node_or_null("/root/AssetRegistry")
	if registry == null:
		push_error("Level requires the AssetRegistry autoload.")
		return
	for index in range(BACKGROUND_NODE_PATHS.size()):
		var sprite := get_node_or_null(BACKGROUND_NODE_PATHS[index]) as Sprite2D
		if sprite == null:
			continue
		var texture_name := ""
		if index < background_texture_names.size():
			texture_name = background_texture_names[index]
		if texture_name.is_empty():
			sprite.texture = null
		else:
			sprite.texture = registry.call(&"get_stage_background_texture", campaign_act, texture_name) as Texture2D


func _paint_rooftop_layout() -> void:
	terrain.clear()
	if layout_variant == 0:
		_paint_rooftop(-4, 44, 14)
		_paint_rooftop(7, 14, 10)
		_paint_rooftop(17, 24, 8)
		for y in range(5, 14):
			terrain.set_cell(Vector2i(28, y), 0, ROOF_MIDDLE)
	else:
		_paint_rooftop(-4, 16, 14)
		_paint_rooftop(12, 29, 11)
		_paint_rooftop(25, 44, 8)
		for y in range(9, 14):
			terrain.set_cell(Vector2i(38, y), 0, ROOF_MIDDLE)


func _paint_rooftop(start_x: int, end_x: int, y: int) -> void:
	for x in range(start_x, end_x):
		var atlas_coordinates := ROOF_MIDDLE
		if x == start_x:
			atlas_coordinates = ROOF_LEFT
		elif x == end_x - 1:
			atlas_coordinates = ROOF_RIGHT
		terrain.set_cell(Vector2i(x, y), 0, atlas_coordinates)

