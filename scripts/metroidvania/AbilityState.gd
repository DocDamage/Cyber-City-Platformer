class_name AbilityState
extends RefCounted

const DEFAULTS := {
	"basic_teleport": 1,
	"phase_barrier": 0,
	"heavy_ground_break": 0,
	"magnetic_rail": 0,
	"gravity_anchor": 0,
	"corruption_resistance": 0,
	"chain_teleport": 0,
	"energy_field": 0,
}

var levels: Dictionary = DEFAULTS.duplicate(true)


func clear() -> void:
	levels = DEFAULTS.duplicate(true)


func grant(ability_id: StringName, amount := 1) -> bool:
	var key := String(ability_id)
	if not levels.has(key) or amount <= 0:
		return false
	levels[key] = int(levels[key]) + amount
	return true


func has(ability_id: StringName, minimum_level := 1) -> bool:
	return int(levels.get(String(ability_id), 0)) >= minimum_level


func to_dict() -> Dictionary:
	return levels.duplicate(true)


func load_dict(data: Variant) -> bool:
	levels = DEFAULTS.duplicate(true)
	if data is not Dictionary:
		return false
	for key: Variant in data:
		if levels.has(String(key)):
			levels[String(key)] = maxi(int(data[key]), 0)
	levels.basic_teleport = maxi(int(levels.basic_teleport), 1)
	return true
