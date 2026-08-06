class_name PlayerVisual
extends Node2D

signal animation_changed(animation_name: StringName)
signal frame_changed(animation_name: StringName, frame_index: int, source_frame: int)
signal animation_event(event_name: StringName)
signal animation_finished(animation_name: StringName)
signal profile_applied(profile: CharacterProfile)

@export var default_animation: StringName = &"idle"
@export var playback_speed := 1.0

var profile := CharacterProfile.new()
var current_animation: StringName = &"idle"
var current_frame := 0
var facing_left := false
var _frame_elapsed := 0.0
var _playing := true
var _layers: Array[AnimatedSprite2D] = []

@onready var hair_back: AnimatedSprite2D = $BackLayers/HairBack
@onready var bottom_back: AnimatedSprite2D = $BackLayers/BottomBack
@onready var top_back: AnimatedSprite2D = $BackLayers/TopBack
@onready var weapon_back: AnimatedSprite2D = $BackLayers/WeaponBack
@onready var body: AnimatedSprite2D = $Body
@onready var face: AnimatedSprite2D = $Face
@onready var bottom_front: AnimatedSprite2D = $FrontLayers/BottomFront
@onready var top_front: AnimatedSprite2D = $FrontLayers/TopFront
@onready var hair_front: AnimatedSprite2D = $FrontLayers/HairFront
@onready var weapon_front: AnimatedSprite2D = $FrontLayers/WeaponFront


func _ready() -> void:
	_layers = [hair_back, bottom_back, top_back, weapon_back, body, face, bottom_front, top_front, hair_front, weapon_front]
	apply_profile(profile)
	play_animation(default_animation, true)


func _process(delta: float) -> void:
	if not _playing or playback_speed <= 0.0:
		return
	var definition := CreatorAnimationCatalog.animation(current_animation)
	if definition.is_empty():
		return
	var fps := maxf(float(definition.get("fps", 8.0)) * playback_speed, 0.01)
	_frame_elapsed += delta
	var seconds_per_frame := 1.0 / fps
	while _frame_elapsed >= seconds_per_frame:
		_frame_elapsed -= seconds_per_frame
		_advance_frame(bool(definition.get("loop", false)))


func apply_profile(next_profile: CharacterProfile) -> void:
	profile = next_profile.duplicate_profile() if next_profile != null else CharacterProfile.new()
	profile.sanitize()
	var appearance := profile.appearance
	var body_frame := CreatorCatalog.option("body", appearance.body_id)
	var skin := CreatorCatalog.option("skin_tone", appearance.skin_tone_id)
	var face_option := CreatorCatalog.option("face", appearance.face_id)
	var hair := CreatorCatalog.option("hair_style", appearance.hair_style_id)
	var top := CreatorCatalog.option("top", appearance.top_id)
	var bottom := CreatorCatalog.option("bottom", appearance.bottom_id)
	var weapon := CreatorCatalog.weapon_layers(String(profile.starting_weapon_family))
	_configure_layer(body, String(skin.get("path", "")))
	_configure_layer(face, String(face_option.get("path", "")))
	_configure_layer(hair_back, String(hair.get("back_path", "")))
	_configure_layer(hair_front, String(hair.get("front_path", "")))
	_configure_layer(top_back, String(top.get("back_path", "")))
	_configure_layer(top_front, String(top.get("front_path", "")))
	_configure_layer(bottom_back, String(bottom.get("back_path", "")))
	_configure_layer(bottom_front, String(bottom.get("front_path", "")))
	_configure_layer(weapon_back, String(weapon.get("back_path", "")))
	_configure_layer(weapon_front, String(weapon.get("front_path", "")))
	_set_pair_modulate(hair_back, hair_front, _option_color("hair_color", appearance.hair_color_id))
	_set_pair_modulate(top_back, top_front, _option_color("clothing_color", appearance.top_color_id))
	_set_pair_modulate(bottom_back, bottom_front, _option_color("clothing_color", appearance.bottom_color_id))
	_apply_body_frame(body_frame)
	_sync_layers()
	profile_applied.emit(profile.duplicate_profile())


func play_animation(animation_name: StringName, from_start := false) -> void:
	if CreatorAnimationCatalog.animation(animation_name).is_empty():
		animation_name = &"idle"
	if current_animation == animation_name and not from_start:
		_playing = true
		return
	current_animation = animation_name
	current_frame = 0
	_frame_elapsed = 0.0
	_playing = true
	_sync_layers()
	animation_changed.emit(current_animation)
	_emit_frame_state()


func pause_animation() -> void:
	_playing = false


func set_facing_left(value: bool) -> void:
	facing_left = value
	for layer: AnimatedSprite2D in _layers:
		layer.flip_h = facing_left


func set_visual_modulate(value: Color) -> void:
	modulate = value


func get_source_frame() -> int:
	return CreatorAnimationCatalog.source_frame(current_animation, current_frame)


func _advance_frame(loops: bool) -> void:
	var count := CreatorAnimationCatalog.frame_count(current_animation)
	if count <= 0:
		return
	var next_frame := current_frame + 1
	if next_frame >= count:
		if loops:
			next_frame = 0
		else:
			next_frame = count - 1
			_playing = false
			animation_finished.emit(current_animation)
	current_frame = next_frame
	_sync_layers()
	_emit_frame_state()


func _sync_layers() -> void:
	for layer: AnimatedSprite2D in _layers:
		if layer.sprite_frames != null and layer.sprite_frames.has_animation(current_animation):
			layer.animation = current_animation
			layer.frame = mini(current_frame, layer.sprite_frames.get_frame_count(current_animation) - 1)
			layer.frame_progress = 0.0
		layer.flip_h = facing_left


func _emit_frame_state() -> void:
	var source := get_source_frame()
	frame_changed.emit(current_animation, current_frame, source)
	var event_name := CreatorAnimationCatalog.frame_event(current_animation, current_frame)
	if not event_name.is_empty():
		animation_event.emit(event_name)


func _configure_layer(layer: AnimatedSprite2D, path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"):
		layer.visible = false
		layer.sprite_frames = SpriteFrames.new()
		return
	var texture := load(path) as Texture2D
	layer.sprite_frames = CreatorAnimationCatalog.build_sprite_frames(texture)
	layer.visible = true


func _option_color(category: String, option_id: String) -> Color:
	var entry := CreatorCatalog.option(category, option_id)
	var hex := String(entry.get("modulate", "ffffff"))
	return Color(hex)


func _apply_body_frame(frame: Dictionary) -> void:
	var width_scale := clampf(float(frame.get("visual_scale_x", 1.0)), 0.88, 1.14)
	for layer: AnimatedSprite2D in _layers:
		layer.scale = Vector2(width_scale, 1.0)


func _set_pair_modulate(first: CanvasItem, second: CanvasItem, value: Color) -> void:
	first.self_modulate = value
	second.self_modulate = value
