class_name WeaponCatalog
extends RefCounted

const PATH := "res://data/weapons/weapon_families.json"
const UNKNOWN_ICON_PATH := "res://assets/runtime/ui/icons/unknown.png"
const ICON_RUNTIME_SIZE := 28
static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_data = parsed as Dictionary
		else:
			push_error("Weapon family catalog is invalid: %s" % PATH)
	return _data


static func family(family_id: StringName) -> Dictionary:
	return ((data().get("families", {}) as Dictionary).get(String(family_id), {}) as Dictionary).duplicate(true)


static func has_family(family_id: StringName) -> bool:
	return not family(family_id).is_empty()


static func weapons() -> Dictionary:
	return (data().get("items", {}) as Dictionary).duplicate(true)


static func weapon(item_id: StringName) -> Dictionary:
	return ((data().get("items", {}) as Dictionary).get(String(item_id), {}) as Dictionary).duplicate(true)


static func family_for_weapon(item_id: StringName) -> StringName:
	return StringName(weapon(item_id).get("family", ""))


static func icon_path(item_id: StringName, reveal := true) -> String:
	if not reveal:
		return UNKNOWN_ICON_PATH
	var candidate := String(weapon(item_id).get("icon_path", ""))
	if candidate.is_empty() or not ResourceLoader.exists(candidate):
		return UNKNOWN_ICON_PATH
	return candidate


static func icon(item_id: StringName, reveal := true) -> Texture2D:
	return load(icon_path(item_id, reveal)) as Texture2D


static func attack_profile(family_id: StringName, airborne: bool, combo_step: int) -> Dictionary:
	var definition := family(family_id)
	if definition.is_empty():
		definition = family(&"sword")
	if airborne:
		return (definition.get("air_attack", {}) as Dictionary).duplicate(true)
	var combo: Array = definition.get("ground_combo", [])
	if combo.is_empty():
		return {}
	return (combo[clampi(combo_step - 1, 0, combo.size() - 1)] as Dictionary).duplicate(true)


static func technique_profile(family_id: StringName) -> Dictionary:
	var definition := family(family_id)
	if definition.is_empty():
		definition = family(&"sword")
	return (definition.get("technique", {}) as Dictionary).duplicate(true)


static func technique_cost(family_id: StringName) -> float:
	return maxf(float(technique_profile(family_id).get("cost", 12.0)), 0.0)


static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if int(data().get("schema_version", 0)) < 2:
		errors.append("Weapon catalog schema does not include the inventory icon contract.")
	if not ResourceLoader.exists(UNKNOWN_ICON_PATH):
		errors.append("Unknown/locked item icon is missing: %s." % UNKNOWN_ICON_PATH)
	for family_id: StringName in CharacterProfile.WEAPON_FAMILIES:
		var definition := family(family_id)
		if definition.is_empty():
			errors.append("Missing weapon family %s." % family_id)
			continue
		if int(definition.get("base_damage", 0)) <= 0:
			errors.append("Weapon family %s has invalid damage." % family_id)
		if (definition.get("ground_combo", []) as Array).size() != 3:
			errors.append("Weapon family %s does not have three ground attacks." % family_id)
		if (definition.get("air_attack", {}) as Dictionary).is_empty():
			errors.append("Weapon family %s has no air attack." % family_id)
		var technique := definition.get("technique", {}) as Dictionary
		if technique.is_empty() or String(technique.get("id", "")).is_empty() or float(technique.get("cost", -1.0)) < 0.0:
			errors.append("Weapon family %s has no valid technique." % family_id)
	var weapon_definitions := weapons()
	var family_icons := {}
	for item_id: String in weapon_definitions:
		var item := weapon_definitions[item_id] as Dictionary
		var family_id := StringName(item.get("family", ""))
		if not has_family(family_id):
			errors.append("Weapon item %s references invalid family %s." % [item_id, family_id])
		if String(item.get("display_name", "")).is_empty() or String(item.get("description", "")).is_empty() or String(item.get("lore", "")).is_empty():
			errors.append("Weapon item %s lacks inventory presentation metadata." % item_id)
		var category := String(item.get("category", ""))
		if category not in ["melee", "ranged"]:
			errors.append("Weapon item %s has invalid taxonomy category %s." % [item_id, category])
		var item_icon_path := String(item.get("icon_path", ""))
		if item_icon_path.is_empty() or item_icon_path == UNKNOWN_ICON_PATH:
			errors.append("Weapon item %s has no curated family icon." % item_id)
		elif not ResourceLoader.exists(item_icon_path):
			errors.append("Weapon item %s icon is missing: %s." % [item_id, item_icon_path])
		var family_key := String(family_id)
		if family_icons.has(family_key) and String(family_icons[family_key]) != item_icon_path:
			errors.append("Weapon family %s uses inconsistent variant icons." % family_id)
		elif not item_icon_path.is_empty():
			family_icons[family_key] = item_icon_path
	for family_id: StringName in CharacterProfile.WEAPON_FAMILIES:
		if not family_icons.has(String(family_id)):
			errors.append("Weapon family %s has no inventory icon." % family_id)
	return errors
