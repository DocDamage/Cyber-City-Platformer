class_name StageContentCatalog
extends RefCounted

const ACT_1 := preload("res://scripts/campaign/content/Act1Content.gd")
const ACT_2 := preload("res://scripts/campaign/content/Act2Content.gd")
const ACT_3 := preload("res://scripts/campaign/content/Act3Content.gd")
const ACT_4 := preload("res://scripts/campaign/content/Act4Content.gd")


static func get_blueprint(stage_id: String) -> Dictionary:
	var act_text := stage_id.get_slice("-", 0)
	if not act_text.is_valid_int():
		return {}
	var blueprint: Dictionary
	match act_text.to_int():
		1: blueprint = ACT_1.get_blueprint(stage_id)
		2: blueprint = ACT_2.get_blueprint(stage_id)
		3: blueprint = ACT_3.get_blueprint(stage_id)
		4: blueprint = ACT_4.get_blueprint(stage_id)
		_: return {}
	return blueprint.duplicate(true)


static func validate(blueprint: Dictionary, is_boss_stage: bool) -> PackedStringArray:
	var errors := PackedStringArray()
	var known_ids := {}
	if String(blueprint.get("stage_id", "")).is_empty():
		errors.append("missing stage_id")
	var mechanics: Array = blueprint.get("mechanics", [])
	if mechanics.is_empty():
		errors.append("requires at least one authored mechanic")
	for entry_value: Variant in mechanics:
		var entry := entry_value as Dictionary
		var entry_id := String(entry.get("id", ""))
		if entry_id.is_empty() or String(entry.get("kind", "")).is_empty():
			errors.append("mechanic entries require stable id and kind")
		elif known_ids.has(entry_id):
			errors.append("duplicate content id: %s" % entry_id)
		else:
			known_ids[entry_id] = true
	for section_value: Variant in blueprint.get("traversal", []):
		var section := section_value as Dictionary
		var section_id := String(section.get("id", ""))
		if section_id.is_empty() or String(section.get("kind", "")).is_empty():
			errors.append("traversal entries require stable id and kind")
		elif known_ids.has(section_id):
			errors.append("duplicate content id: %s" % section_id)
		else:
			known_ids[section_id] = true
	for encounter_value: Variant in blueprint.get("encounters", []):
		var encounter := encounter_value as Dictionary
		var encounter_id := String(encounter.get("id", ""))
		var activation := encounter.get("activation", Rect2()) as Rect2
		var waves := encounter.get("waves", []) as Array
		if encounter_id.is_empty() or activation.size.x <= 0.0 or activation.size.y <= 0.0 or waves.is_empty():
			errors.append("encounters require id, positive activation bounds, and waves")
		elif known_ids.has(encounter_id):
			errors.append("duplicate content id: %s" % encounter_id)
		else:
			known_ids[encounter_id] = true
		for wave_value: Variant in waves:
			if (wave_value as Array).is_empty():
				errors.append("encounter %s has an empty wave" % encounter_id)
	for entry_value: Variant in mechanics:
		var entry := entry_value as Dictionary
		for target_value: Variant in entry.get("targets", []):
			if not known_ids.has(String(target_value)):
				errors.append("mechanic %s references missing target %s" % [entry.get("id", ""), target_value])
	if is_boss_stage:
		var arena := blueprint.get("boss_arena", {}) as Dictionary
		if arena.is_empty() or not arena.has("bounds"):
			errors.append("boss stage requires authored arena bounds")
	else:
		if (blueprint.get("traversal", []) as Array).size() < 2:
			errors.append("standard stage requires two authored traversal sections")
		if (blueprint.get("encounters", []) as Array).size() < 2:
			errors.append("standard stage requires two authored combat encounters")
	return errors
