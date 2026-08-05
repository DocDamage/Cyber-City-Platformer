class_name ActBalanceProfile
extends RefCounted

const PROFILES := {
	1: {
		"health": 0.9, "damage": 1.0, "speed": 0.92, "attack_rate": 0.92,
		"detection": 0.9, "score": 1.0, "knockback_resistance": 0.0,
		"target_wave_size": 2, "elite_rate": 0.0,
	},
	2: {
		"health": 1.0, "damage": 1.0, "speed": 1.0, "attack_rate": 1.0,
		"detection": 1.0, "score": 1.1, "knockback_resistance": 0.08,
		"target_wave_size": 2, "elite_rate": 0.0,
	},
	3: {
		"health": 1.08, "damage": 1.12, "speed": 1.06, "attack_rate": 1.08,
		"detection": 1.05, "score": 1.2, "knockback_resistance": 0.16,
		"target_wave_size": 2, "elite_rate": 0.08,
	},
	4: {
		"health": 1.16, "damage": 1.22, "speed": 1.12, "attack_rate": 1.15,
		"detection": 1.1, "score": 1.35, "knockback_resistance": 0.24,
		"target_wave_size": 2, "elite_rate": 0.28,
	},
}


static func get_profile(act_number: int) -> Dictionary:
	return (PROFILES.get(clampi(act_number, 1, 4), PROFILES[1]) as Dictionary).duplicate(true)


static func apply_to_enemy(enemy: EnemyBase, act_number: int) -> void:
	if enemy == null:
		return
	var profile := get_profile(act_number)
	enemy.max_health = maxi(roundi(enemy.max_health * float(profile.health)), 1)
	enemy.health = enemy.max_health
	enemy.attack_damage = maxi(roundi(enemy.attack_damage * float(profile.damage)), 1)
	enemy.patrol_speed *= float(profile.speed)
	enemy.chase_speed *= float(profile.speed)
	enemy.attack_cooldown /= float(profile.attack_rate)
	var base_detection := enemy.detection_radius
	if base_detection <= 0.0:
		base_detection = enemy.get_default_detection_radius()
	enemy.set_detection_radius(base_detection * float(profile.detection))
	enemy.score_value = maxi(roundi(enemy.score_value * float(profile.score)), 1)
	enemy.knockback_resistance = float(profile.knockback_resistance)
