class_name CharacterProfile
extends RefCounted

const PRONOUN_IDS := [&"they_them", &"she_her", &"he_him"]
const WEAPON_FAMILIES := [&"sword", &"dagger", &"spear", &"heavy", &"bow", &"staff"]

var character_name := "Runner"
var pronoun_set_id: StringName = &"they_them"
var voice_profile_id := "voice_01"
var portrait_id := "portrait_01"
var appearance := CharacterAppearance.new()
var starting_weapon_family: StringName = &"sword"
var creation_complete := false


func duplicate_profile() -> CharacterProfile:
	var copy := CharacterProfile.new()
	copy.load_dict(to_dict())
	return copy


func is_valid(require_complete := false) -> bool:
	return (
		(not require_complete or creation_complete)
		and not character_name.strip_edges().is_empty()
		and character_name.length() <= 24
		and pronoun_set_id in PRONOUN_IDS
		and CreatorCatalog.has_voice(voice_profile_id)
		and CreatorCatalog.has_portrait(portrait_id)
		and appearance != null
		and appearance.is_valid()
		and starting_weapon_family in WEAPON_FAMILIES
	)


func sanitize() -> void:
	character_name = character_name.strip_edges().left(24)
	if character_name.is_empty():
		character_name = "Runner"
	if pronoun_set_id not in PRONOUN_IDS:
		pronoun_set_id = &"they_them"
	if not CreatorCatalog.has_voice(voice_profile_id):
		voice_profile_id = "voice_01"
	if not CreatorCatalog.has_portrait(portrait_id):
		portrait_id = "portrait_01"
	if appearance == null:
		appearance = CharacterAppearance.new()
	appearance.sanitize()
	if starting_weapon_family not in WEAPON_FAMILIES:
		starting_weapon_family = &"sword"


func to_dict() -> Dictionary:
	return {
		"character_name": character_name,
		"pronoun_set_id": String(pronoun_set_id),
		"voice_profile_id": voice_profile_id,
		"portrait_id": portrait_id,
		"appearance": appearance.to_dict(),
		"starting_weapon_family": String(starting_weapon_family),
		"creation_complete": creation_complete,
	}


func load_dict(data: Variant) -> bool:
	if data is not Dictionary:
		return false
	var values := data as Dictionary
	character_name = String(values.get("character_name", "Runner"))
	pronoun_set_id = StringName(values.get("pronoun_set_id", "they_them"))
	voice_profile_id = String(values.get("voice_profile_id", "voice_01"))
	portrait_id = String(values.get("portrait_id", "portrait_01"))
	appearance = CharacterAppearance.new()
	appearance.load_dict(values.get("appearance", {}))
	starting_weapon_family = StringName(values.get("starting_weapon_family", "sword"))
	creation_complete = bool(values.get("creation_complete", false))
	sanitize()
	return is_valid(false)
