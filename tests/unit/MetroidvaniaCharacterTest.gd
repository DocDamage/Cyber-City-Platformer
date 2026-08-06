extends SceneTree

const VISUAL_SCENE := preload("res://scenes/Player/PlayerVisual.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var errors := CreatorAnimationCatalog.validate_catalog()
	if not _require(errors.is_empty(), "Animation catalog errors: %s" % errors):
		return
	if not _require(CreatorCatalog.portraits().size() == 12 and CreatorCatalog.voices().size() == 5, "Creator identity catalogs are incomplete."):
		return
	var portrait_textures := {}
	var portrait_gender_counts := {"female": 0, "male": 0}
	for portrait: Dictionary in CreatorCatalog.portraits():
		var texture_path := String(portrait.get("texture", ""))
		var recolor_mask_path := String(portrait.get("recolor_mask", ""))
		var gender := String(portrait.get("gender", ""))
		portrait_textures[texture_path] = true
		portrait_gender_counts[gender] = int(portrait_gender_counts.get(gender, 0)) + 1
		if not _require(not String(portrait.get("archetype", "")).is_empty() and ResourceLoader.exists(texture_path, "Texture2D") and ResourceLoader.exists(recolor_mask_path, "Texture2D"), "Portrait art, recolor mask, or archetype metadata is incomplete: %s" % portrait):
			return
	if not _require(portrait_textures.size() == 12 and int(portrait_gender_counts.female) == 6 and int(portrait_gender_counts.male) == 6, "Portrait roster must contain 12 unique images split evenly by gender: textures=%d genders=%s" % [portrait_textures.size(), portrait_gender_counts]):
		return
	for category: String in ["skin_tone", "face", "hair_style", "top"]:
		if not _require(not CreatorCatalog.options(category).is_empty(), "Creator category is empty: %s" % category):
			return
	var profile := CharacterProfile.new()
	profile.character_name = "  Nyx  "
	profile.pronoun_set_id = &"she_her"
	profile.voice_profile_id = "missing"
	profile.portrait_id = "portrait_12"
	profile.appearance.skin_tone_id = "skin_04"
	profile.starting_weapon_family = &"spear"
	profile.creation_complete = true
	profile.sanitize()
	if not _require(profile.character_name == "Nyx" and profile.voice_profile_id == "voice_01" and profile.is_valid(true), "Profile sanitization did not produce a valid character."):
		return
	profile.appearance.hair_style_id = "missing_hair"
	profile.appearance.sanitize()
	if not _require(profile.appearance.hair_style_id == CharacterAppearance.DEFAULTS.hair_style_id and profile.appearance.is_valid(), "Appearance ID validation did not restore a compatible default."):
		return
	var round_trip := CharacterProfile.new()
	if not _require(round_trip.load_dict(profile.to_dict()) and round_trip.to_dict() == profile.to_dict(), "Character profile did not round trip."):
		return
	var dialogue := PronounResolver.resolve("{player_name} says {subject} {be} ready; the key is {possessive_pronoun}.", profile)
	if not _require(dialogue == "Nyx says she is ready; the key is hers.", "Pronoun resolution failed: %s" % dialogue):
		return
	for family_id: StringName in CharacterProfile.WEAPON_FAMILIES:
		var attack := WeaponCatalog.attack_profile(family_id, false, 1)
		if not _require(float(attack.get("damage", 0.0)) > 0.0 and WeaponCatalog.technique_cost(family_id) >= 0.0, "Weapon calculations are invalid for %s." % family_id):
			return
	if not _require(WeaponCatalog.validate().is_empty() and WeaponCatalog.weapons().size() == 14, "Weapon inventory presentation catalog is incomplete: %s" % WeaponCatalog.validate()):
		return
	var weapon_icon_paths := {}
	for item_id: String in WeaponCatalog.weapons():
		var item := WeaponCatalog.weapon(StringName(item_id))
		weapon_icon_paths[String(item.get("icon_path", ""))] = true
		if not _require(WeaponCatalog.icon(StringName(item_id)) != null, "Weapon icon did not load for %s." % item_id):
			return
	if not _require(weapon_icon_paths.size() == CharacterProfile.WEAPON_FAMILIES.size() and WeaponCatalog.icon_path(&"missing_item") == WeaponCatalog.UNKNOWN_ICON_PATH and WeaponCatalog.icon(&"missing_item") != null, "Weapon icon families or unknown-item fallback are incomplete."):
		return
	var inventory := InventoryState.new()
	if not _require(inventory.add_item(&"scrap", 2) and inventory.add_item(&"scrap", 3) and inventory.count(&"scrap") == 5 and inventory.add_item(&"dagger_signal_pair", 1, true) and not inventory.add_item(&"dagger_signal_pair", 1, true), "Inventory stacking or unique-item rejection failed."):
		return
	var equipment := EquipmentState.new()
	if not _require(not equipment.equip_weapon("staff_lumen_rod", &"staff", inventory) and not equipment.equip_weapon("dagger_signal_pair", &"staff", inventory) and equipment.equip_weapon("dagger_signal_pair", &"dagger", inventory), "Equipment inventory/family restrictions failed."):
		return
	var abilities := AbilityState.new()
	if not _require(abilities.has(&"basic_teleport") and not abilities.has(&"phase_barrier") and abilities.grant(&"phase_barrier") and abilities.has(&"phase_barrier"), "Ability gate state did not enforce or grant progression."):
		return
	var world_progress := WorldProgress.new()
	world_progress.clear()
	world_progress.discover_room("cyber_rooftop_lane")
	world_progress.set_object_state("unit_shortcut", true)
	world_progress.activate_warp("warp_rooftop_overlook")
	var restored_world := WorldProgress.new()
	if not _require(restored_world.load_dict(world_progress.to_dict()) and restored_world.discovered_rooms.has("cyber_rooftop_lane") and bool(restored_world.get_object_state("unit_shortcut", false)) and restored_world.activated_warp_nodes.has("warp_rooftop_overlook") and restored_world.map_completion(99) > 0.0, "Persistent object/map discovery serialization failed."):
		return
	var recolor_profile := profile.duplicate_profile()
	recolor_profile.appearance.hair_color_id = "hair_color_cyan"
	recolor_profile.appearance.top_color_id = "cloth_color_magenta"
	recolor_profile.appearance.bottom_color_id = "cloth_color_gold"
	var portrait_view := PortraitView.new()
	root.add_child(portrait_view)
	await process_frame
	portrait_view.apply_profile(recolor_profile)
	var recolor_material := portrait_view.material as ShaderMaterial
	if not _require(recolor_material != null and portrait_view.get("_recolor_mask") is Texture2D and float(recolor_material.get_shader_parameter("recolor_enabled")) == 1.0 and float(recolor_material.get_shader_parameter("hair_strength")) == 1.0 and float(recolor_material.get_shader_parameter("top_strength")) == 1.0 and float(recolor_material.get_shader_parameter("bottom_strength")) == 1.0, "Portrait palette controls did not configure the recolor shader."):
		return
	var visual := VISUAL_SCENE.instantiate() as PlayerVisual
	root.add_child(visual)
	await process_frame
	visual.apply_profile(profile)
	visual.play_animation(&"attack_1", true)
	await create_timer(0.15, true, false, true).timeout
	var source_frame := visual.get_source_frame()
	if not _require(source_frame >= 37 and source_frame <= 42, "Layered visual did not advance through the attack catalog."):
		return
	for layer: AnimatedSprite2D in visual._layers:
		if layer.visible and not _require(layer.animation == visual.current_animation and layer.frame == visual.current_frame, "A visible player layer drifted out of sync."):
			return
	var bark := VoiceBarkPlayer.new()
	root.add_child(bark)
	await process_frame
	if not _require(bark.validate_manifest().is_empty(), "Voice preview manifest contains missing or invalid clips."):
		return
	if not _require(not bark._select_clip("voice_01", "greeting").is_empty(), "Voice preview lookup could not resolve a clip."):
		return
	var bark_now := Time.get_ticks_msec() / 1000.0
	bark.global_cooldown = 10.0
	bark.set("_last_global_time", bark_now)
	if not _require(bark.call(&"_bark_rejection_reason", &"damage", bark_now) == &"global_cooldown", "Voice bark global cooldown did not reject an immediate repeat."):
		return
	bark.global_cooldown = 0.0
	bark.set("_last_global_time", -1000.0)
	bark.set("_active_priority", 3)
	if not _require(bark.call(&"_bark_rejection_reason", &"grunting", bark_now) == &"priority", "Low-priority bark interrupted an active damage bark."):
		return
	print("METROIDVANIA_CHARACTER_TEST_OK frames=102 portraits=12 voices=5 state_contracts=true bark_priority=true source_frame=", source_frame)
	portrait_view.queue_free()
	visual.queue_free()
	bark.stop_bark()
	bark.queue_free()
	await process_frame
	await process_frame
	inventory = null
	equipment = null
	abilities = null
	world_progress = null
	restored_world = null
	CreatorAnimationCatalog.clear_runtime_cache()
	quit()


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
