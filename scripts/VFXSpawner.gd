extends Node

const EFFECT_SCENES := {
	&"dust": preload("res://scenes/vfx/DustBurst.tscn"),
	&"sparks": preload("res://scenes/vfx/SparkBurst.tscn"),
	&"smoke": preload("res://scenes/vfx/SmokeBurst.tscn"),
	&"explosion_ring": preload("res://scenes/vfx/ExplosionRing.tscn"),
}


func spawn_effect(
		effect_name: StringName,
		target_global_position: Vector2,
		direction := Vector2.RIGHT,
		parent: Node = null
) -> GPUParticles2D:
	var particle_scene := EFFECT_SCENES.get(effect_name) as PackedScene
	if particle_scene == null:
		push_warning("VFXSpawner has no effect named '%s'." % effect_name)
		return null
	return spawn_one_shot(particle_scene, target_global_position, direction, parent)


func spawn_one_shot(
		particle_scene: PackedScene,
		target_global_position: Vector2,
		direction := Vector2.RIGHT,
		parent: Node = null
) -> GPUParticles2D:
	if particle_scene == null:
		return null
	var particles := particle_scene.instantiate() as GPUParticles2D
	if particles == null:
		push_warning("VFXSpawner expected a GPUParticles2D root.")
		return null
	var effect_parent := parent
	if effect_parent == null:
		effect_parent = get_tree().current_scene
	if effect_parent == null:
		effect_parent = get_tree().root
	effect_parent.add_child(particles)
	particles.global_position = target_global_position
	if not direction.is_zero_approx():
		particles.rotation = direction.angle()
	particles.one_shot = true
	particles.restart()
	return particles
