@tool
class_name PrototypeStage
extends Node2D

const BACKGROUND_SPRITE_PATHS := [
	^"Background/Far/FarSprite",
	^"Background/Middle/MiddleSprite",
	^"Background/Front/FrontSprite",
]

@export_range(1, 4, 1) var campaign_act := 1
@export var stage_id: StringName = &"prototype"
@export var stage_title := "Editable Stage Prototype"
@export_multiline var design_notes := "Replace the blockout geometry, paint Terrain, and drag props/enemies/VFX into their named folders."
@export_file("*.ogg") var music_path := "res://Music/Library/Rooftops/Cyberpunk Rooftops.ogg"
@export var far_background: Texture2D
@export var middle_background: Texture2D
@export var front_background: Texture2D
@export var background_tint := Color.WHITE


func _ready() -> void:
	_apply_editor_metadata()
	_apply_backgrounds()
	if Engine.is_editor_hint():
		return
	var guide := get_node_or_null("DesignGuide") as CanvasLayer
	if guide != null:
		guide.visible = false
	var sound_manager := get_node_or_null("/root/SoundManager")
	if sound_manager != null:
		sound_manager.call(&"play_music", music_path)


func _apply_editor_metadata() -> void:
	var title_label := get_node_or_null("DesignGuide/Panel/Margin/VBox/Title") as Label
	var notes_label := get_node_or_null("DesignGuide/Panel/Margin/VBox/Notes") as Label
	if title_label != null:
		title_label.text = "%s  |  %s" % [String(stage_id), stage_title]
	if notes_label != null:
		notes_label.text = design_notes


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
