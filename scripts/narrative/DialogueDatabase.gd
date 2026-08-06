class_name DialogueDatabase
extends RefCounted

const DIALOGUE_PATH := "res://data/narrative/dialogue.json"
const CUTSCENE_PATH := "res://data/narrative/cutscenes.json"

static var _dialogue: Dictionary = {}
static var _cutscenes: Dictionary = {}


static func entry(entry_id: String) -> Dictionary:
	_ensure_loaded()
	return ((_dialogue.get("entries", {}) as Dictionary).get(entry_id, {}) as Dictionary).duplicate(true)


static func sequence(sequence_id: String) -> Dictionary:
	_ensure_loaded()
	return ((_cutscenes.get("sequences", {}) as Dictionary).get(sequence_id, {}) as Dictionary).duplicate(true)


static func conditions_met(definition: Dictionary, flags: Dictionary) -> bool:
	for condition_value: Variant in definition.get("conditions", []):
		if condition_value is not Dictionary:
			return false
		var condition := condition_value as Dictionary
		var actual: Variant = flags.get(String(condition.get("flag", "")), false)
		if actual != condition.get("equals", true):
			return false
	return true


static func resolve_text(text: String, profile: CharacterProfile) -> String:
	return PronounResolver.resolve(text, profile)


static func validate() -> PackedStringArray:
	_ensure_loaded()
	var errors := PackedStringArray()
	for entry_id: String in (_dialogue.get("entries", {}) as Dictionary):
		var definition := entry(entry_id)
		var lines: Array = definition.get("lines", [])
		if lines.is_empty():
			errors.append("Dialogue %s has no lines." % entry_id)
		for line_value: Variant in lines:
			if line_value is not Dictionary or String((line_value as Dictionary).get("id", "")).is_empty() or String((line_value as Dictionary).get("text", "")).is_empty():
				errors.append("Dialogue %s contains an invalid line." % entry_id)
	for sequence_id: String in (_cutscenes.get("sequences", {}) as Dictionary):
		var definition := sequence(sequence_id)
		if (definition.get("commands", []) as Array).is_empty():
			errors.append("Cutscene %s has no commands." % sequence_id)
		if (definition.get("skip_endpoint", []) as Array).is_empty():
			errors.append("Cutscene %s has no safe skip endpoint." % sequence_id)
		for command_value: Variant in definition.get("commands", []):
			if command_value is Dictionary and String((command_value as Dictionary).get("type", "")) == "dialogue":
				var dialogue_id := String((command_value as Dictionary).get("entry_id", ""))
				if entry(dialogue_id).is_empty():
					errors.append("Cutscene %s references missing dialogue %s." % [sequence_id, dialogue_id])
	return errors


static func clear_runtime_cache() -> void:
	_dialogue.clear()
	_cutscenes.clear()


static func _ensure_loaded() -> void:
	if _dialogue.is_empty():
		_dialogue = _load_json(DIALOGUE_PATH)
	if _cutscenes.is_empty():
		_cutscenes = _load_json(CUTSCENE_PATH)


static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Narrative data is missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is not Dictionary:
		push_error("Narrative data is invalid: %s" % path)
		return {}
	return parsed as Dictionary
