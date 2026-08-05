class_name EncounterController
extends Area2D

const ACT_BALANCE := preload("res://scripts/campaign/ActBalanceProfile.gd")

signal activated
signal wave_started(index: int, total: int)
signal completed
signal reset

var encounter_id: StringName
var lock_arena := true
var _activation_rect := Rect2()
var _waves: Array = []
var _live_enemies: Array[EnemyBase] = []
var _enemy_parent: Node
var _active := false
var _complete := false
var _wave_index := 0
var _act_number := 1
var _arena_barriers: Array[StaticBody2D] = []


func configure(id: StringName, activation_rect: Rect2, enemies: Array[EnemyBase]) -> void:
	var wave: Array[Dictionary] = []
	for enemy: EnemyBase in enemies:
		wave.append({"scene": enemy.scene_file_path, "position": enemy.global_position, "elite": false})
	_enemy_parent = enemies[0].get_parent() if not enemies.is_empty() else get_parent()
	_configure_common(id, activation_rect, [wave])
	for enemy: EnemyBase in enemies:
		_track_enemy(enemy)


func configure_blueprint(id: StringName, activation_rect: Rect2, waves: Array, enemy_parent: Node, registry: Node, should_lock_arena := true, act_number := 1) -> void:
	_enemy_parent = enemy_parent
	lock_arena = should_lock_arena
	_act_number = clampi(act_number, 1, 4)
	var resolved_waves: Array = []
	for wave_value: Variant in waves:
		var resolved_wave: Array[Dictionary] = []
		for entry_value: Variant in wave_value as Array:
			var entry := entry_value as Dictionary
			var packed := registry.call(&"get_enemy_scene", StringName(entry.get("enemy", ""))) as PackedScene if registry != null else null
			if packed == null:
				push_error("Encounter %s could not resolve enemy '%s'." % [id, entry.get("enemy", "")])
				continue
			resolved_wave.append({
				"scene": packed.resource_path,
				"position": entry.get("position", activation_rect.get_center()),
				"elite": bool(entry.get("elite", false)),
			})
		resolved_waves.append(resolved_wave)
	_configure_common(id, activation_rect, resolved_waves)
	_spawn_wave(0, false)


func _configure_common(id: StringName, activation_rect: Rect2, waves: Array) -> void:
	encounter_id = id
	name = "Encounter_%s" % id
	_activation_rect = activation_rect
	_waves = waves.duplicate(true)
	position = activation_rect.get_center()
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape_node := CollisionShape2D.new()
	shape_node.name = "ActivationShape"
	var shape := RectangleShape2D.new()
	shape.size = activation_rect.size
	shape_node.shape = shape
	add_child(shape_node)
	if lock_arena:
		_build_arena_barriers()
		_set_barriers_active(false)


func _ready() -> void:
	add_to_group(&"encounters")
	body_entered.connect(_on_body_entered)
	for enemy: EnemyBase in _live_enemies:
		_set_enemy_active(enemy, false)


func is_complete() -> bool:
	return _complete


func is_active() -> bool:
	return _active


func get_live_enemy_count() -> int:
	return _live_enemies.size()


func get_live_enemies() -> Array[EnemyBase]:
	return _live_enemies.duplicate()


func get_wave_count() -> int:
	return _waves.size()


func get_total_authored_enemy_count() -> int:
	var count := 0
	for wave_value: Variant in _waves:
		count += (wave_value as Array).size()
	return count


func force_complete_for_test() -> void:
	if _complete:
		return
	_complete = true
	_active = false
	_set_barriers_active(false)
	completed.emit()


func reset_encounter() -> void:
	if _complete:
		return
	_clear_live_enemies()
	_wave_index = 0
	_spawn_wave(0, false)
	_active = false
	monitoring = true
	_set_barriers_active(false)
	reset.emit()


func _spawn_wave(index: int, active: bool) -> void:
	if index < 0 or index >= _waves.size() or not is_instance_valid(_enemy_parent):
		return
	_wave_index = index
	for record_value: Variant in _waves[index] as Array:
		var record := record_value as Dictionary
		var packed := load(String(record.get("scene", ""))) as PackedScene
		if packed == null:
			continue
		var enemy := packed.instantiate() as EnemyBase
		_enemy_parent.add_child(enemy)
		ACT_BALANCE.apply_to_enemy(enemy, _act_number)
		enemy.global_position = record.get("position", _activation_rect.get_center())
		if bool(record.get("elite", false)):
			enemy.max_health *= 2
			enemy.health = enemy.max_health
			enemy.sprite.modulate = Color(1.0, 0.35, 0.85)
		_track_enemy(enemy)
		_set_enemy_active(enemy, active)
	if active:
		wave_started.emit(index + 1, _waves.size())


func _track_enemy(enemy: EnemyBase) -> void:
	if enemy == null:
		return
	_live_enemies.append(enemy)
	if not enemy.died.is_connected(_on_enemy_died.bind(enemy)):
		enemy.died.connect(_on_enemy_died.bind(enemy))


func _on_body_entered(body: Node) -> void:
	if _active or _complete or not body.is_in_group(&"player"):
		return
	_active = true
	set_deferred("monitoring", false)
	_set_barriers_active(lock_arena)
	for enemy: EnemyBase in _live_enemies:
		_set_enemy_active(enemy, true)
	if body.has_signal(&"died") and not body.is_connected(&"died", _on_player_died):
		body.connect(&"died", _on_player_died)
	wave_started.emit(_wave_index + 1, _waves.size())
	activated.emit()


func _on_enemy_died(enemy: EnemyBase) -> void:
	_live_enemies.erase(enemy)
	if not _active or not _live_enemies.is_empty():
		return
	if _wave_index + 1 < _waves.size():
		_spawn_wave(_wave_index + 1, true)
		return
	_complete = true
	_active = false
	_set_barriers_active(false)
	completed.emit()


func _on_player_died() -> void:
	if _active and not _complete:
		_reset_after_respawn()


func _reset_after_respawn() -> void:
	await get_tree().create_timer(0.7, true, false, true).timeout
	reset_encounter()


func _set_enemy_active(enemy: EnemyBase, active: bool) -> void:
	if not is_instance_valid(enemy):
		return
	enemy.visible = active
	enemy.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func _clear_live_enemies() -> void:
	for enemy: EnemyBase in _live_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_live_enemies.clear()


func _set_barriers_active(value: bool) -> void:
	for barrier: StaticBody2D in _arena_barriers:
		barrier.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED)
		barrier.visible = value


func _build_arena_barriers() -> void:
	for x_position: float in [_activation_rect.position.x, _activation_rect.end.x]:
		var barrier := StaticBody2D.new()
		barrier.position = Vector2(x_position - _activation_rect.get_center().x, 0.0)
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(24.0, _activation_rect.size.y)
		collision.shape = shape
		barrier.add_child(collision)
		var line := Line2D.new()
		line.width = 5.0
		line.default_color = Color(1.0, 0.1, 0.55, 0.75)
		line.points = PackedVector2Array([Vector2(0, -_activation_rect.size.y * 0.5), Vector2(0, _activation_rect.size.y * 0.5)])
		barrier.add_child(line)
		add_child(barrier)
		_arena_barriers.append(barrier)
