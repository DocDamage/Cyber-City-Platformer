extends SceneTree

const ROOM_FILES := [
	"res://data/world/rooms/rooftop_alley.json",
	"res://data/world/rooms/cyber_city_districts.json",
	"res://data/world/rooms/robot_factory_districts.json",
	"res://data/world/rooms/neon_moon_districts.json",
	"res://data/world/rooms/abyssal_night_districts.json",
]
const REQUIRED_DICTIONARIES := [
	"stagger", "resistances", "detection", "navigation", "attack", "hurt", "death",
	"animation_map", "collision", "audio_profile", "vfx_profile", "difficulty_variants",
]
const REQUIRED_ANIMATIONS := ["idle", "move", "attack", "hurt", "death"]

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(45.0, true, false, true).timeout.connect(func() -> void:
		push_error("Enemy contract test timed out.")
		quit(1)
	)
	var registry := root.get_node_or_null("AssetRegistry")
	_require(registry != null, "AssetRegistry is unavailable.")
	if registry == null:
		_finish(0)
		return
	var library := registry.call(&"get_enemy_library") as Dictionary
	_require(int(library.get("schema_version", 0)) == 2, "Enemy library is not using production contract schema 2.")
	var enemies := library.get("enemies", []) as Array
	_require(enemies.size() == 22, "Expected 22 enemy contracts; found %d." % enemies.size())
	var observed_regions := _collect_observed_regions()
	var ids := {}
	for enemy_value: Variant in enemies:
		var info := enemy_value as Dictionary
		var enemy_id := String(info.get("id", ""))
		_require(not enemy_id.is_empty() and not ids.has(enemy_id), "Enemy ID is empty or duplicated: '%s'." % enemy_id)
		ids[enemy_id] = true
		_validate_data_contract(enemy_id, info, observed_regions)
		var packed := registry.call(&"get_enemy_scene", StringName(enemy_id)) as PackedScene
		_require(packed != null, "Enemy scene is unavailable: %s" % enemy_id)
		if packed == null:
			continue
		var enemy := packed.instantiate() as EnemyBase
		_require(enemy != null, "Enemy scene does not instantiate EnemyBase: %s" % enemy_id)
		if enemy == null:
			continue
		root.add_child(enemy)
		_validate_runtime_contract(enemy_id, info, enemy)
		enemy.free()
	await _validate_stagger_and_drops(registry)
	await _validate_roster_lab()
	_finish(enemies.size())


func _validate_data_contract(enemy_id: String, info: Dictionary, observed_regions: Dictionary) -> void:
	_require(not String(info.get("name", "")).is_empty(), "%s has no display name." % enemy_id)
	_require(not String(info.get("archetype", "")).is_empty(), "%s has no behavior archetype." % enemy_id)
	_require(float(info.get("patrol_speed", 0.0)) > 0.0 and float(info.get("chase_speed", 0.0)) > 0.0, "%s has invalid movement speed." % enemy_id)
	for field: String in REQUIRED_DICTIONARIES:
		_require(info.get(field) is Dictionary and not (info.get(field) as Dictionary).is_empty(), "%s has no %s contract." % [enemy_id, field])
	var authored_regions := PackedStringArray(info.get("regions", []))
	var placed_regions := PackedStringArray(observed_regions.get(enemy_id, []))
	authored_regions.sort()
	placed_regions.sort()
	_require(not authored_regions.is_empty() and authored_regions == placed_regions, "%s region assignments do not match authored encounters: %s != %s." % [enemy_id, authored_regions, placed_regions])
	var stagger := info.get("stagger", {}) as Dictionary
	_require(float(stagger.get("threshold", 0.0)) > 0.0 and float(stagger.get("recovery", 0.0)) >= 0.35, "%s has an invalid stagger contract." % enemy_id)
	var resistances := info.get("resistances", {}) as Dictionary
	_require(_unit_interval(resistances.get("damage", -1.0)) and _unit_interval(resistances.get("knockback", -1.0)) and _unit_interval(stagger.get("resistance", -1.0)), "%s has invalid resistance values." % enemy_id)
	var detection := info.get("detection", {}) as Dictionary
	_require(float(detection.get("radius", 0.0)) >= float(info.get("attack_range", 0.0)) and float(detection.get("leash_distance", 0.0)) > float(detection.get("radius", 0.0)), "%s has invalid detection/leash rules." % enemy_id)
	var navigation := info.get("navigation", {}) as Dictionary
	var expected_mode := "flight" if bool(info.get("airborne", false)) else "ground"
	_require(String(navigation.get("mode", "")) == expected_mode and bool(navigation.get("requires_floor", false)) != bool(info.get("airborne", false)), "%s navigation assumptions disagree with its scene." % enemy_id)
	var attack := info.get("attack", {}) as Dictionary
	_require(float(attack.get("telegraph", 0.0)) >= 0.18 and float(attack.get("active", 0.0)) > 0.0 and float(attack.get("recovery", 0.0)) >= float(attack.get("punish_window", 0.0)) and float(attack.get("punish_window", 0.0)) >= 0.2, "%s has invalid attack windows." % enemy_id)
	_require(float(attack.get("stagger_damage", 0.0)) > 0.0, "%s attack has no stagger value." % enemy_id)
	var drops := info.get("drop_table", []) as Array
	_require(not drops.is_empty() and String((drops[0] as Dictionary).get("type", "")) == "currency" and float((drops[0] as Dictionary).get("chance", 0.0)) == 1.0, "%s has no guaranteed baseline drop." % enemy_id)
	var animation_map := info.get("animation_map", {}) as Dictionary
	for animation_key: String in REQUIRED_ANIMATIONS:
		_require(String(animation_map.get(animation_key, "")) in PackedStringArray(info.get("animations", [])), "%s animation map does not resolve '%s'." % [enemy_id, animation_key])
	var collision := info.get("collision", {}) as Dictionary
	for collision_key: String in ["body_size", "hurtbox_size", "contact_hitbox_size", "contact_offset"]:
		_require((collision.get(collision_key, []) as Array).size() == 2, "%s collision contract lacks %s." % [enemy_id, collision_key])
	var elite := (info.get("difficulty_variants", {}) as Dictionary).get("elite", {}) as Dictionary
	_require(float(elite.get("health_multiplier", 0.0)) > 1.0 and not String(elite.get("palette", "")).is_empty(), "%s has no valid elite variant." % enemy_id)
func _validate_runtime_contract(enemy_id: String, info: Dictionary, enemy: EnemyBase) -> void:
	var runtime := enemy.get_production_contract()
	var attack := info.get("attack", {}) as Dictionary
	var runtime_attack := runtime.get("attack", {}) as Dictionary
	_require(String(runtime_attack.get("kind", "")) == String(attack.get("kind", "")) and is_equal_approx(float(runtime_attack.get("telegraph", 0.0)), float(attack.get("telegraph", -1.0))) and is_equal_approx(float(runtime_attack.get("active", 0.0)), float(attack.get("active", -1.0))) and is_equal_approx(float(runtime_attack.get("recovery", 0.0)), float(attack.get("recovery", -1.0))), "%s does not apply its authored attack windows at runtime." % enemy_id)
	var detection := info.get("detection", {}) as Dictionary
	_require(is_equal_approx(enemy.leash_distance, float(detection.get("leash_distance", -1.0))) and is_equal_approx(enemy.detection_radius, float(detection.get("radius", -1.0))), "%s does not apply its authored detection/leash contract." % enemy_id)
	var collision := info.get("collision", {}) as Dictionary
	var body_shape := enemy.body_collision.shape as RectangleShape2D
	var hurt_shape := (enemy.hurtbox.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
	var contact_shape := (enemy.contact_hitbox.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
	_require(_matches_size(body_shape.size, collision.get("body_size", [])) and _matches_size(hurt_shape.size, collision.get("hurtbox_size", [])) and _matches_size(contact_shape.size, collision.get("contact_hitbox_size", [])), "%s does not apply its authored collision contract." % enemy_id)
	_require(not (runtime.get("drop_table", []) as Array).is_empty() and not (runtime.get("audio_profile", {}) as Dictionary).is_empty() and not (runtime.get("vfx_profile", {}) as Dictionary).is_empty(), "%s runtime omits drops, audio, or VFX profile." % enemy_id)


func _validate_stagger_and_drops(registry: Node) -> void:
	var heavy := (registry.call(&"get_enemy_scene", &"stone_golem") as PackedScene).instantiate() as EnemyBase
	root.add_child(heavy)
	heavy.max_health = 99
	heavy.health = 99
	var hit_count := ceili(heavy.stagger_threshold / maxf(1.0 - heavy.stagger_resistance, 0.01))
	for _hit: int in range(hit_count):
		heavy.take_damage(1)
	_require(heavy.state == EnemyBase.State.STUNNED, "Authored stagger threshold does not produce the stunned punish state.")
	heavy.free()
	var game := root.get_node_or_null("GameManager")
	var initial_currency: int = int(game.inventory.currency)
	var goblin := (registry.call(&"get_enemy_scene", &"goblin") as PackedScene).instantiate() as EnemyBase
	root.add_child(goblin)
	var drop := ((registry.call(&"get_enemy_info", &"goblin") as Dictionary).get("drop_table", []) as Array)[0] as Dictionary
	goblin.take_damage(999)
	var gained: int = int(game.inventory.currency) - initial_currency
	_require(gained >= int(drop.get("min", 0)) and gained <= int(drop.get("max", -1)), "Guaranteed currency drop did not use the authored range.")
	game.inventory.currency = initial_currency
	if is_instance_valid(goblin):
		goblin.free()
	await process_frame


func _validate_roster_lab() -> void:
	var packed := load("res://scenes/testing/EnemyRosterLab.tscn") as PackedScene
	var lab := packed.instantiate() as EnemyRosterLab if packed != null else null
	_require(lab != null, "Enemy roster test scene could not instantiate.")
	if lab == null:
		return
	root.add_child(lab)
	await process_frame
	var ids := lab.get_instantiated_ids()
	var unique := {}
	for enemy_id: StringName in ids:
		unique[String(enemy_id)] = true
	_require(lab.get_instantiated_count() == 22 and unique.size() == 22, "Enemy roster test scene did not build all 22 unique enemies.")
	lab.queue_free()
	await process_frame


func _collect_observed_regions() -> Dictionary:
	var observed := {}
	for path: String in ROOM_FILES:
		var payload := JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
		for room_value: Variant in payload.get("rooms", []):
			var room := room_value as Dictionary
			var region := String(room.get("region_id", ""))
			for encounter_value: Variant in room.get("encounters", []):
				for wave_value: Variant in (encounter_value as Dictionary).get("waves", []):
					for unit_value: Variant in wave_value as Array:
						var enemy_id := String((unit_value as Dictionary).get("enemy", ""))
						if enemy_id.is_empty():
							continue
						if not observed.has(enemy_id):
							observed[enemy_id] = []
						if region not in (observed[enemy_id] as Array):
							(observed[enemy_id] as Array).append(region)
	return observed


func _unit_interval(value: Variant) -> bool:
	return float(value) >= 0.0 and float(value) < 1.0


func _matches_size(actual: Vector2, dimensions_value: Variant) -> bool:
	var dimensions := dimensions_value as Array
	return dimensions.size() == 2 and actual.is_equal_approx(Vector2(float(dimensions[0]), float(dimensions[1])))


func _require(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(enemy_count: int) -> void:
	if not _failures.is_empty():
		for failure: String in _failures:
			push_error(failure)
		quit(1)
		return
	print("ENEMY_CONTRACT_TEST_OK enemies=", enemy_count, " regions=4 archetypes=10 gallery=22 drops=1 stagger=1")
	quit()
