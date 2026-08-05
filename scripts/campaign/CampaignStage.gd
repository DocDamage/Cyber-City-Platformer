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
	for index in range(BACKGROUND_SPRITE_PATHS.size()):
		var sprite := get_node_or_null(BACKGROUND_SPRITE_PATHS[index]) as Sprite2D
		if sprite == null:
			continue
		sprite.texture = textures[index]
		sprite.modulate = background_tint
		_fit_background_to_viewport(sprite)


func _fit_background_to_viewport(sprite: Sprite2D) -> void:
	if sprite.texture == null:
		return
	var texture_size := sprite.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var cover_scale := maxf(960.0 / texture_size.x, 540.0 / texture_size.y)
	sprite.scale = Vector2(cover_scale, cover_scale)
