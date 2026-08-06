class_name PortraitView
extends Control

const SKIN_TONES := [
	Color("f2c6a7"),
	Color("d9a07e"),
	Color("b97858"),
	Color("8c563e"),
	Color("603b32"),
	Color("3d2725"),
]
const PORTRAIT_RECOLOR_SHADER := """
shader_type canvas_item;

uniform sampler2D recolor_mask : filter_linear, repeat_disable;
uniform vec4 hair_target : source_color = vec4(1.0);
uniform vec4 skin_target : source_color = vec4(1.0);
uniform vec4 top_target : source_color = vec4(1.0);
uniform vec4 bottom_target : source_color = vec4(1.0);
uniform float hair_strength = 0.0;
uniform float skin_strength = 1.0;
uniform float top_strength = 0.0;
uniform float bottom_strength = 0.0;
uniform float recolor_enabled = 0.0;

vec3 shade_with_target(vec3 source, vec3 target) {
	float source_luma = dot(source, vec3(0.299, 0.587, 0.114));
	float shade = 0.35 + source_luma * 0.9;
	return clamp(target * shade, vec3(0.0), vec3(1.0));
}

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	vec3 result = source.rgb;
	bool is_portrait_texture = TEXTURE_PIXEL_SIZE.x < 0.01 && TEXTURE_PIXEL_SIZE.y < 0.01;
	if (recolor_enabled > 0.5 && is_portrait_texture) {
		vec3 mask = texture(recolor_mask, UV).rgb;
		result = mix(result, shade_with_target(result, skin_target.rgb), mask.g * skin_strength);
		result = mix(result, shade_with_target(result, hair_target.rgb), mask.r * hair_strength);

		float lower_clothing = smoothstep(0.62, 0.96, UV.y);
		float upper_mix = mask.b * top_strength * (1.0 - lower_clothing * 0.6);
		float lower_mix = mask.b * bottom_strength * lower_clothing;
		result = mix(result, shade_with_target(result, top_target.rgb), upper_mix);
		result = mix(result, shade_with_target(result, bottom_target.rgb), lower_mix);
	}
	COLOR = vec4(result, source.a);
}
"""

@export var portrait_id := "portrait_01"
@export var show_weapon := true

var profile := CharacterProfile.new()
var _definition: Dictionary = {}
var _photo_texture: Texture2D
var _recolor_mask: Texture2D
var _recolor_material: ShaderMaterial


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(96.0, 96.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	apply_profile(profile)


func apply_profile(next_profile: CharacterProfile) -> void:
	profile = next_profile.duplicate_profile() if next_profile != null else CharacterProfile.new()
	portrait_id = profile.portrait_id
	_definition = _find_definition(portrait_id)
	_photo_texture = _load_photo_texture(_definition)
	_recolor_mask = _load_recolor_mask(_definition)
	_configure_recolor_material()
	queue_redraw()


func _draw() -> void:
	if _definition.is_empty():
		_definition = _find_definition("portrait_01")
	var bounds := Rect2(Vector2.ZERO, size)
	var background := Color(String(_definition.get("background", "101936")))
	var accent := Color(String(_definition.get("accent", "27e8ff")))
	draw_rect(bounds, background, true)
	if _photo_texture != null:
		draw_texture_rect(_photo_texture, bounds.grow(-5.0), false)
	draw_rect(bounds.grow(-4.0), accent, false, 4.0)
	if _photo_texture != null:
		if show_weapon:
			_draw_weapon_family(accent, minf(size.x, size.y) / 180.0)
		return
	var scale_factor := minf(size.x, size.y) / 180.0
	var origin := Vector2(size.x * 0.5, size.y * 0.57)
	var skin_index := clampi(profile.appearance.skin_tone_id.trim_prefix("skin_").to_int() - 1, 0, SKIN_TONES.size() - 1)
	var skin: Color = SKIN_TONES[skin_index]
	var hair := _palette_color(profile.appearance.hair_color_id, Color("25243b"))
	var clothing := _palette_color(profile.appearance.top_color_id, accent.darkened(0.25))
	var head_radius := 30.0 * scale_factor
	var silhouette := String(_definition.get("silhouette", "angular"))
	draw_circle(origin + Vector2(0.0, -34.0) * scale_factor, head_radius, skin)
	_draw_hair(origin, scale_factor, head_radius, hair, silhouette)
	var shoulder_rect := Rect2(origin + Vector2(-52.0, 0.0) * scale_factor, Vector2(104.0, 74.0) * scale_factor)
	draw_rect(shoulder_rect, clothing, true)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(-52.0, 0.0) * scale_factor,
		origin + Vector2(-26.0, -12.0) * scale_factor,
		origin + Vector2(26.0, -12.0) * scale_factor,
		origin + Vector2(52.0, 0.0) * scale_factor,
	]), clothing.lightened(0.18))
	draw_circle(origin + Vector2(-10.0, -38.0) * scale_factor, 3.0 * scale_factor, Color("10131f"))
	draw_circle(origin + Vector2(10.0, -38.0) * scale_factor, 3.0 * scale_factor, Color("10131f"))
	if show_weapon:
		_draw_weapon_family(accent, scale_factor)


func _draw_hair(origin: Vector2, scale_factor: float, head_radius: float, hair: Color, silhouette: String) -> void:
	var top := origin + Vector2(0.0, -52.0) * scale_factor
	var points := PackedVector2Array([
		top + Vector2(-30.0, 8.0) * scale_factor,
		top + Vector2(-20.0, -18.0) * scale_factor,
		top + Vector2(0.0, -28.0 if silhouette in ["spike", "crest", "antenna"] else -18.0) * scale_factor,
		top + Vector2(24.0, -14.0) * scale_factor,
		top + Vector2(head_radius / scale_factor, 12.0) * scale_factor,
		top + Vector2(16.0, 2.0) * scale_factor,
		top + Vector2(-12.0, 4.0) * scale_factor,
	])
	draw_colored_polygon(points, hair)
	if silhouette in ["tail", "sweep", "hood"]:
		draw_colored_polygon(PackedVector2Array([
			top + Vector2(22.0, 0.0) * scale_factor,
			top + Vector2(42.0, 34.0) * scale_factor,
			top + Vector2(22.0, 42.0) * scale_factor,
		]), hair.darkened(0.1))


func _draw_weapon_family(accent: Color, scale_factor: float) -> void:
	var family := String(profile.starting_weapon_family)
	var anchor := Vector2(size.x - 30.0 * scale_factor, 38.0 * scale_factor)
	match family:
		"bow":
			draw_arc(anchor, 20.0 * scale_factor, -1.4, 1.4, 12, accent, 4.0 * scale_factor)
		"staff":
			draw_line(anchor + Vector2(-18.0, 28.0) * scale_factor, anchor + Vector2(10.0, -20.0) * scale_factor, accent, 5.0 * scale_factor)
			draw_circle(anchor + Vector2(11.0, -21.0) * scale_factor, 7.0 * scale_factor, accent)
		"heavy":
			draw_line(anchor + Vector2(-18.0, 25.0) * scale_factor, anchor + Vector2(8.0, -14.0) * scale_factor, accent, 6.0 * scale_factor)
			draw_rect(Rect2(anchor + Vector2(-2.0, -24.0) * scale_factor, Vector2(24.0, 15.0) * scale_factor), accent, true)
		_:
			draw_line(anchor + Vector2(-18.0, 28.0) * scale_factor, anchor + Vector2(14.0, -22.0) * scale_factor, accent, 5.0 * scale_factor)


func _find_definition(id: String) -> Dictionary:
	for value: Variant in CreatorCatalog.portraits():
		if value is Dictionary and String((value as Dictionary).get("id", "")) == id:
			return (value as Dictionary).duplicate(true)
	return {}


func _load_photo_texture(definition: Dictionary) -> Texture2D:
	var texture_path := String(definition.get("texture", ""))
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return null
	return load(texture_path) as Texture2D


func _load_recolor_mask(definition: Dictionary) -> Texture2D:
	var mask_path := String(definition.get("recolor_mask", ""))
	if mask_path.is_empty() or not ResourceLoader.exists(mask_path, "Texture2D"):
		return null
	return load(mask_path) as Texture2D


func _configure_recolor_material() -> void:
	if _recolor_material == null:
		var recolor_shader := Shader.new()
		recolor_shader.code = PORTRAIT_RECOLOR_SHADER
		_recolor_material = ShaderMaterial.new()
		_recolor_material.shader = recolor_shader
		material = _recolor_material
	_recolor_material.set_shader_parameter("recolor_enabled", 1.0 if _photo_texture != null and _recolor_mask != null else 0.0)
	if _recolor_mask != null:
		_recolor_material.set_shader_parameter("recolor_mask", _recolor_mask)

	var skin_index := clampi(profile.appearance.skin_tone_id.trim_prefix("skin_").to_int() - 1, 0, SKIN_TONES.size() - 1)
	_recolor_material.set_shader_parameter("skin_target", SKIN_TONES[skin_index])

	var hair_option := CreatorCatalog.option("hair_color", profile.appearance.hair_color_id)
	var top_option := CreatorCatalog.option("clothing_color", profile.appearance.top_color_id)
	var bottom_option := CreatorCatalog.option("clothing_color", profile.appearance.bottom_color_id)
	_recolor_material.set_shader_parameter("hair_target", Color(String(hair_option.get("modulate", "ffffff"))))
	_recolor_material.set_shader_parameter("top_target", Color(String(top_option.get("modulate", "ffffff"))))
	_recolor_material.set_shader_parameter("bottom_target", Color(String(bottom_option.get("modulate", "ffffff"))))
	_recolor_material.set_shader_parameter("hair_strength", 1.0 if hair_option.has("modulate") else 0.0)
	_recolor_material.set_shader_parameter("top_strength", 1.0 if top_option.has("modulate") else 0.0)
	_recolor_material.set_shader_parameter("bottom_strength", 1.0 if bottom_option.has("modulate") else 0.0)


func _palette_color(option_id: String, fallback: Color) -> Color:
	var category := "hair_color" if option_id.begins_with("hair_") else "clothing_color"
	var option := CreatorCatalog.option(category, option_id)
	return Color(String(option.modulate)) if option.has("modulate") else fallback
