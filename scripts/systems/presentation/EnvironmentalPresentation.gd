class_name EnvironmentalPresentation
extends Node2D

var act_number := 1
var substage_number := 1
var stage_bounds := Rect2(0, 0, 1408, 540)
var _accent := Color("22ddff")
var _pulse_light: PointLight2D
var _elapsed := 0.0
var _reduced_effects := false


func configure(act: int, substage: int, bounds: Rect2) -> void:
	act_number = clampi(act, 1, 4)
	substage_number = maxi(substage, 1)
	stage_bounds = bounds
	_accent = _act_color(act_number).lerp(Color.WHITE, float(substage_number - 1) * 0.055)
	name = "EnvironmentalPresentation"


func _ready() -> void:
	add_to_group(&"ambient_presentation")
	var settings := get_node_or_null("/root/SettingsManager")
	_reduced_effects = settings != null and bool(settings.call(&"get_setting", &"reduced_flashing", false))
	_build_ambient_particles()
	_build_pulse_light()
	_build_foreground_frame()


func _process(delta: float) -> void:
	if _reduced_effects or _pulse_light == null:
		return
	_elapsed += delta
	_pulse_light.energy = 0.42 + sin(_elapsed * (0.65 + substage_number * 0.07)) * 0.12


func _build_ambient_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.name = "AmbientMotes"
	particles.z_index = -8
	particles.position = stage_bounds.get_center()
	particles.amount = 8 if _reduced_effects else 22
	particles.lifetime = 5.5
	particles.randomness = 0.8
	particles.visibility_rect = Rect2(-stage_bounds.size * 0.5, stage_bounds.size)
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(stage_bounds.size.x * 0.5, stage_bounds.size.y * 0.42, 1.0)
	material.direction = Vector3(0.25, -1.0, 0.0)
	material.spread = 32.0
	material.initial_velocity_min = 7.0
	material.initial_velocity_max = 18.0
	material.gravity = Vector3(0.0, -2.5, 0.0)
	material.scale_min = 0.55
	material.scale_max = 1.5
	material.color = Color(_accent, 0.34)
	particles.process_material = material
	add_child(particles)


func _build_pulse_light() -> void:
	_pulse_light = PointLight2D.new()
	_pulse_light.name = "AmbientPulse"
	_pulse_light.position = Vector2(stage_bounds.position.x + stage_bounds.size.x * (0.28 + substage_number * 0.07), stage_bounds.get_center().y - 80.0)
	_pulse_light.color = _accent
	_pulse_light.energy = 0.42
	_pulse_light.texture_scale = 2.4
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(_accent, 0.52), Color(_accent, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 192
	texture.height = 192
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_pulse_light.texture = texture
	add_child(_pulse_light)


func _build_foreground_frame() -> void:
	var frame := Line2D.new()
	frame.name = "ForegroundFrame"
	frame.z_index = 14
	frame.width = 9.0
	frame.default_color = Color(_accent, 0.2)
	frame.points = PackedVector2Array([
		Vector2(stage_bounds.position.x, stage_bounds.end.y - 18.0),
		Vector2(stage_bounds.end.x, stage_bounds.end.y - 18.0),
	])
	add_child(frame)


func _act_color(act: int) -> Color:
	match act:
		2: return Color("ff7a32")
		3: return Color("75a7ff")
		4: return Color("d329ff")
		_: return Color("22ddff")
