class_name CharacterAppearance
extends RefCounted

const DEFAULTS := {
	"body_id": "body_01",
	"skin_tone_id": "skin_01",
	"face_id": "face_01",
	"hair_style_id": "hair_f1",
	"hair_color_id": "hair_color_01",
	"top_id": "cloth_1",
	"top_color_id": "cloth_color_01",
	"bottom_id": "cloth_1",
	"bottom_color_id": "cloth_color_01",
}

var body_id := String(DEFAULTS.body_id)
var skin_tone_id := String(DEFAULTS.skin_tone_id)
var face_id := String(DEFAULTS.face_id)
var hair_style_id := String(DEFAULTS.hair_style_id)
var hair_color_id := String(DEFAULTS.hair_color_id)
var top_id := String(DEFAULTS.top_id)
var top_color_id := String(DEFAULTS.top_color_id)
var bottom_id := String(DEFAULTS.bottom_id)
var bottom_color_id := String(DEFAULTS.bottom_color_id)
var cosmetic_flags: Dictionary = {}


func duplicate_appearance() -> CharacterAppearance:
	var copy := CharacterAppearance.new()
	copy.load_dict(to_dict())
	return copy


func is_valid() -> bool:
	return (
		CreatorCatalog.has_option("body", body_id)
		and CreatorCatalog.has_option("skin_tone", skin_tone_id)
		and CreatorCatalog.has_option("face", face_id)
		and CreatorCatalog.has_option("hair_style", hair_style_id)
		and CreatorCatalog.has_option("hair_color", hair_color_id)
		and CreatorCatalog.has_option("top", top_id)
		and CreatorCatalog.has_option("clothing_color", top_color_id)
		and CreatorCatalog.has_option("bottom", bottom_id)
		and CreatorCatalog.has_option("clothing_color", bottom_color_id)
	)


func sanitize() -> void:
	body_id = _valid_or_default("body", body_id, "body_id")
	skin_tone_id = _valid_or_default("skin_tone", skin_tone_id, "skin_tone_id")
	face_id = _valid_or_default("face", face_id, "face_id")
	hair_style_id = _valid_or_default("hair_style", hair_style_id, "hair_style_id")
	hair_color_id = _valid_or_default("hair_color", hair_color_id, "hair_color_id")
	top_id = _valid_or_default("top", top_id, "top_id")
	top_color_id = _valid_or_default("clothing_color", top_color_id, "top_color_id")
	bottom_id = _valid_or_default("bottom", bottom_id, "bottom_id")
	bottom_color_id = _valid_or_default("clothing_color", bottom_color_id, "bottom_color_id")


func to_dict() -> Dictionary:
	return {
		"body_id": body_id,
		"skin_tone_id": skin_tone_id,
		"face_id": face_id,
		"hair_style_id": hair_style_id,
		"hair_color_id": hair_color_id,
		"top_id": top_id,
		"top_color_id": top_color_id,
		"bottom_id": bottom_id,
		"bottom_color_id": bottom_color_id,
		"cosmetic_flags": cosmetic_flags.duplicate(true),
	}


func load_dict(data: Variant) -> bool:
	if data is not Dictionary:
		return false
	var values := data as Dictionary
	body_id = String(values.get("body_id", DEFAULTS.body_id))
	skin_tone_id = String(values.get("skin_tone_id", DEFAULTS.skin_tone_id))
	face_id = String(values.get("face_id", DEFAULTS.face_id))
	hair_style_id = String(values.get("hair_style_id", DEFAULTS.hair_style_id))
	hair_color_id = String(values.get("hair_color_id", DEFAULTS.hair_color_id))
	top_id = String(values.get("top_id", DEFAULTS.top_id))
	top_color_id = String(values.get("top_color_id", DEFAULTS.top_color_id))
	bottom_id = String(values.get("bottom_id", DEFAULTS.bottom_id))
	bottom_color_id = String(values.get("bottom_color_id", DEFAULTS.bottom_color_id))
	cosmetic_flags = (values.get("cosmetic_flags", {}) as Dictionary).duplicate(true)
	sanitize()
	return is_valid()


func _valid_or_default(category: String, value: String, key: String) -> String:
	return value if CreatorCatalog.has_option(category, value) else String(DEFAULTS[key])
