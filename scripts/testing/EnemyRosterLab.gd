class_name EnemyRosterLab
extends Node2D

const COLUMNS := 6
const CELL_SIZE := Vector2(150.0, 125.0)
const ORIGIN := Vector2(82.0, 110.0)

var _instantiated_ids: Array[StringName] = []


func _ready() -> void:
	_build_roster()


func get_instantiated_count() -> int:
	return _instantiated_ids.size()


func get_instantiated_ids() -> Array[StringName]:
	return _instantiated_ids.duplicate()


func _build_roster() -> void:
	var registry := get_node_or_null("/root/AssetRegistry")
	if registry == null:
		push_error("EnemyRosterLab requires AssetRegistry.")
		return
	var library := registry.call(&"get_enemy_library") as Dictionary
	for index: int in range((library.get("enemies", []) as Array).size()):
		var info := (library.get("enemies", []) as Array)[index] as Dictionary
		var enemy_id := StringName(info.get("id", ""))
		var packed := registry.call(&"get_enemy_scene", enemy_id) as PackedScene
		if packed == null:
			push_error("EnemyRosterLab could not load '%s'." % enemy_id)
			continue
		var enemy := packed.instantiate() as EnemyBase
		if enemy == null:
			push_error("EnemyRosterLab could not instantiate '%s'." % enemy_id)
			continue
		var column := index % COLUMNS
		var row := index / COLUMNS
		enemy.position = ORIGIN + Vector2(column, row) * CELL_SIZE
		add_child(enemy)
		enemy.set_home_position(enemy.global_position)
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		var label := Label.new()
		label.name = "Label_%s" % enemy_id
		label.text = String(info.get("name", enemy_id))
		label.position = enemy.position + Vector2(-68.0, 32.0)
		label.size = Vector2(136.0, 28.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("8ff7ff"))
		add_child(label)
		_instantiated_ids.append(enemy_id)
