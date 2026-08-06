class_name EquipmentState
extends RefCounted

const FAMILY_STARTERS := {
	"sword": "sword_phase_edge",
	"dagger": "dagger_signal_pair",
	"spear": "spear_arc_lance",
	"heavy": "heavy_foundry_maul",
	"bow": "bow_voltage_arc",
	"staff": "staff_lumen_rod",
}

var main_weapon_id := "sword_phase_edge"
var weapon_family_id: StringName = &"sword"
var body_module_id := ""
var accessory_ids: Array[String] = ["", ""]


func clear(family_id: StringName = &"sword") -> void:
	weapon_family_id = family_id if family_id in CharacterProfile.WEAPON_FAMILIES else &"sword"
	main_weapon_id = String(FAMILY_STARTERS[String(weapon_family_id)])
	body_module_id = ""
	accessory_ids = ["", ""]


func equip_weapon(weapon_id: String, family_id: StringName, inventory: InventoryState = null) -> bool:
	if weapon_id.is_empty() or family_id not in CharacterProfile.WEAPON_FAMILIES:
		return false
	var authored_family := WeaponCatalog.family_for_weapon(StringName(weapon_id))
	if not authored_family.is_empty() and authored_family != family_id:
		return false
	if inventory != null and not inventory.has_item(StringName(weapon_id)):
		return false
	main_weapon_id = weapon_id
	weapon_family_id = family_id
	return true


func to_dict() -> Dictionary:
	return {
		"main_weapon_id": main_weapon_id,
		"weapon_family_id": String(weapon_family_id),
		"body_module_id": body_module_id,
		"accessory_ids": accessory_ids.duplicate(),
	}


func load_dict(data: Variant) -> bool:
	if data is not Dictionary:
		return false
	var values := data as Dictionary
	var family := StringName(values.get("weapon_family_id", "sword"))
	clear(family)
	var loaded_weapon := String(values.get("main_weapon_id", main_weapon_id))
	if not loaded_weapon.is_empty():
		main_weapon_id = loaded_weapon
	body_module_id = String(values.get("body_module_id", ""))
	var loaded_accessories: Array = values.get("accessory_ids", [])
	for index: int in range(mini(loaded_accessories.size(), 2)):
		accessory_ids[index] = String(loaded_accessories[index])
	return true
