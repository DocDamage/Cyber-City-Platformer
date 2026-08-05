class_name RunState
extends RefCounted

const DEFAULT_UPGRADES := {
	"max_health": 0,
	"max_energy": 0,
	"energy_regeneration": 0,
	"melee_damage": 0,
	"ranged_damage": 0,
	"dash_distance": 0,
	"dash_efficiency": 0,
}

var player_health := -1
var player_max_health := 0
var player_energy := -1.0
var player_max_energy := 0.0
var score := 0
var stage_id := "1-1"
var stage_scene := ""
var checkpoint_id: StringName = &""
var checkpoint_position := Vector2.ZERO
var checkpoint_scene := ""
var checkpoint_locations: Dictionary = {}
var collected_pickups: Dictionary = {}
var defeated_bosses: Dictionary = {}
var upgrades: Dictionary = DEFAULT_UPGRADES.duplicate(true)
var elapsed_seconds := 0.0


func clear() -> void:
	player_health = -1
	player_max_health = 0
	player_energy = -1.0
	player_max_energy = 0.0
	score = 0
	stage_id = "1-1"
	stage_scene = ""
	checkpoint_id = &""
	checkpoint_position = Vector2.ZERO
	checkpoint_scene = ""
	checkpoint_locations.clear()
	collected_pickups.clear()
	defeated_bosses.clear()
	upgrades = DEFAULT_UPGRADES.duplicate(true)
	elapsed_seconds = 0.0


func to_dict() -> Dictionary:
	return {
		"player_health": player_health,
		"player_max_health": player_max_health,
		"player_energy": player_energy,
		"player_max_energy": player_max_energy,
		"score": score,
		"stage_id": stage_id,
		"stage_scene": stage_scene,
		"checkpoint_id": String(checkpoint_id),
		"checkpoint_position": [checkpoint_position.x, checkpoint_position.y],
		"checkpoint_scene": checkpoint_scene,
		"checkpoint_locations": _vectors_to_arrays(checkpoint_locations),
		"collected_pickups": collected_pickups.duplicate(true),
		"defeated_bosses": defeated_bosses.duplicate(true),
		"upgrades": upgrades.duplicate(true),
		"elapsed_seconds": elapsed_seconds,
	}


func load_dict(data: Dictionary) -> bool:
	if not data.has("stage_id") or not data.has("upgrades"):
		return false
	player_health = int(data.get("player_health", -1))
	player_max_health = int(data.get("player_max_health", 0))
	player_energy = float(data.get("player_energy", -1.0))
	player_max_energy = float(data.get("player_max_energy", 0.0))
	score = int(data.get("score", 0))
	stage_id = String(data.get("stage_id", "1-1"))
	stage_scene = String(data.get("stage_scene", ""))
	checkpoint_id = StringName(data.get("checkpoint_id", ""))
	checkpoint_position = _array_to_vector(data.get("checkpoint_position", []))
	checkpoint_scene = String(data.get("checkpoint_scene", ""))
	checkpoint_locations = _arrays_to_vectors(data.get("checkpoint_locations", {}))
	collected_pickups = (data.get("collected_pickups", {}) as Dictionary).duplicate(true)
	defeated_bosses = (data.get("defeated_bosses", {}) as Dictionary).duplicate(true)
	upgrades = DEFAULT_UPGRADES.duplicate(true)
	upgrades.merge(data.get("upgrades", {}) as Dictionary, true)
	elapsed_seconds = maxf(float(data.get("elapsed_seconds", 0.0)), 0.0)
	return true


func _vectors_to_arrays(values: Dictionary) -> Dictionary:
	var result := {}
	for key: Variant in values:
		var value: Variant = values[key]
		if value is Vector2:
			result[String(key)] = [(value as Vector2).x, (value as Vector2).y]
	return result


func _arrays_to_vectors(values: Variant) -> Dictionary:
	var result := {}
	if values is not Dictionary:
		return result
	for key: Variant in values:
		result[String(key)] = _array_to_vector(values[key])
	return result


func _array_to_vector(value: Variant) -> Vector2:
	if value is Array and value.size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
