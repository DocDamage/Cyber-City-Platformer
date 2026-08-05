class_name EncounterController
extends Area2D

signal activated
signal completed
signal reset

var encounter_id: StringName
var _enemy_records: Array[Dictionary] = []
var _live_enemies: Array[EnemyBase] = []
var _active := false
var _complete := false


func configure(id: StringName, activation_rect: Rect2, enemies: Array[EnemyBase]) -> void:
	encounter_id = id
	name = "Encounter_%s" % id
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
	for enemy: EnemyBase in enemies:
		_enemy_records.append({
			"scene": enemy.scene_file_path,
			"parent": enemy.get_parent(),
			"position": enemy.global_position,
		})
		_track_enemy(enemy)


func _ready() -> void:
	add_to_group(&"encounters")
	body_entered.connect(_on_body_entered)
	for enemy: EnemyBase in _live_enemies:
		_set_enemy_active(enemy, false)


func is_complete() -> bool:
	return _complete


func force_complete_for_test() -> void:
	if _complete:
		return
	_complete = true
	_active = false
	completed.emit()


func reset_encounter() -> void:
	if _complete:
		return
	for enemy: EnemyBase in _live_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_live_enemies.clear()
	for record: Dictionary in _enemy_records:
		var scene_path := String(record.get("scene", ""))
		var packed := load(scene_path) as PackedScene
		var parent := record.get("parent") as Node
		if packed == null or not is_instance_valid(parent):
			continue
		var enemy := packed.instantiate() as EnemyBase
		parent.add_child(enemy)
		enemy.global_position = record.get("position", Vector2.ZERO)
		_track_enemy(enemy)
		_set_enemy_active(enemy, false)
	_active = false
	monitoring = true
	reset.emit()


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
	for enemy: EnemyBase in _live_enemies:
		_set_enemy_active(enemy, true)
	if body.has_signal(&"died") and not body.is_connected(&"died", _on_player_died):
		body.connect(&"died", _on_player_died)
	activated.emit()


func _on_enemy_died(enemy: EnemyBase) -> void:
	_live_enemies.erase(enemy)
	if _active and _live_enemies.is_empty():
		_complete = true
		_active = false
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
