@tool
class_name CampaignStage
extends StageBase

const BACKGROUND_SPRITE_PATHS := [
	^"Background/Far/FarSprite",
	^"Background/Middle/MiddleSprite",
	^"Background/Front/FrontSprite",
]

@export_range(1, 4, 1) var campaign_act := 1
@export var stage_id: StringName = &"1-1"
@export var stage_title := "Campaign Stage"
@export_file("*.ogg") var music_path := ""
@export var far_background: Texture2D
@export var middle_background: Texture2D
@export var front_background: Texture2D
@export var background_tint := Color.WHITE
@export var use_layer_tints := false
@export var far_background_tint := Color.WHITE
@export var middle_background_tint := Color.WHITE
@export var front_background_tint := Color.WHITE
@export var background_coverage_size := Vector2(960.0, 540.0)


func _ready() -> void:
	_set_stage_coordinates_from_id()
	super()
	_apply_backgrounds()


func _set_stage_coordinates_from_id() -> void:
	stage_act = campaign_act
	var coordinates := String(stage_id).split("-", false, 1)
	if coordinates.size() == 2 and coordinates[1].is_valid_int():
		stage_sub = coordinates[1].to_int()


func _apply_backgrounds() -> void:
	var textures: Array[Texture2D] = [far_background, middle_background, front_background]
	var layer_tints: Array[Color] = [
		far_background_tint if use_layer_tints else background_tint,
		middle_background_tint if use_layer_tints else background_tint,
		front_background_tint if use_layer_tints else background_tint,
	]
	for index in range(BACKGROUND_SPRITE_PATHS.size()):
		var sprite := get_node_or_null(BACKGROUND_SPRITE_PATHS[index]) as Sprite2D
		if sprite == null:
			continue
		sprite.texture = textures[index]
		sprite.modulate = layer_tints[index]
		_fit_background_to_viewport(sprite)


func _fit_background_to_viewport(sprite: Sprite2D) -> void:
	if sprite.texture == null:
		return
	var texture_size := sprite.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var coverage := Vector2(maxf(background_coverage_size.x, 960.0), maxf(background_coverage_size.y, 540.0))
	var cover_scale := maxf(coverage.x / texture_size.x, coverage.y / texture_size.y)
	sprite.scale = Vector2(cover_scale, cover_scale)
