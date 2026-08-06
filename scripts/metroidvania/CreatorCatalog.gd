class_name CreatorCatalog
extends RefCounted

const CATALOG_PATH := "res://data/characters/creator_catalog.json"
const PORTRAIT_PATH := "res://data/characters/portrait_catalog.json"
const VOICE_PATH := "res://data/characters/voice_profiles.json"

static var _catalog: Dictionary = {}
static var _portraits: Dictionary = {}
static var _voices: Dictionary = {}


static func catalog() -> Dictionary:
	if _catalog.is_empty():
		_catalog = _load_json(CATALOG_PATH)
	return _catalog


static func portraits() -> Array:
	if _portraits.is_empty():
		_portraits = _load_json(PORTRAIT_PATH)
	return (_portraits.get("portraits", []) as Array).duplicate(true)


static func voices() -> Array:
	if _voices.is_empty():
		_voices = _load_json(VOICE_PATH)
	return (_voices.get("profiles", []) as Array).duplicate(true)


static func voice_manifest() -> Dictionary:
	if _voices.is_empty():
		_voices = _load_json(VOICE_PATH)
	return _voices


static func options(category: String) -> Array:
	return ((catalog().get("options", {}) as Dictionary).get(category, []) as Array).duplicate(true)


static func option(category: String, option_id: String) -> Dictionary:
	for entry: Variant in options(category):
		if entry is Dictionary and String((entry as Dictionary).get("id", "")) == option_id:
			return (entry as Dictionary).duplicate(true)
	return {}


static func has_option(category: String, option_id: String) -> bool:
	return not option(category, option_id).is_empty()


static func has_portrait(portrait_id: String) -> bool:
	return portraits().any(func(entry: Variant) -> bool:
		return entry is Dictionary and String((entry as Dictionary).get("id", "")) == portrait_id
	)


static func portrait(portrait_id: String) -> Dictionary:
	for entry: Variant in portraits():
		if entry is Dictionary and String((entry as Dictionary).get("id", "")) == portrait_id:
			return (entry as Dictionary).duplicate(true)
	return {}


static func has_voice(voice_id: String) -> bool:
	return voices().any(func(entry: Variant) -> bool:
		return entry is Dictionary and String((entry as Dictionary).get("id", "")) == voice_id
	)


static func weapon_layers(family_id: String) -> Dictionary:
	return ((catalog().get("weapon_layers", {}) as Dictionary).get(family_id, {}) as Dictionary).duplicate(true)


static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Creator catalog is missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is not Dictionary:
		push_error("Creator catalog is invalid: %s" % path)
		return {}
	return parsed as Dictionary
