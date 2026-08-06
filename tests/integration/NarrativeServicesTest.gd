extends SceneTree


class TestPlayer:
	extends Node2D
	var disabled := false
	func _ready() -> void: add_to_group(&"player")
	func set_input_disabled(value: bool) -> void: disabled = value


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(12.0, true, false, true).timeout.connect(func() -> void:
		push_error("Narrative/services test timed out.")
		quit(1)
	)
	var save_directory := OS.get_environment("CCP_TEST_SAVE_DIR")
	if not _require(not save_directory.is_empty(), "Narrative test requires an isolated save directory."):
		return
	if not _require(DialogueDatabase.validate().is_empty(), "Narrative databases failed validation: %s" % DialogueDatabase.validate()):
		return
	var game := root.get_node("GameManager")
	var save := root.get_node("SaveManager")
	var settings := root.get_node("SettingsManager")
	save.call(&"set_active_slot", 3)
	save.call(&"reset_save", 3)
	game.call(&"new_game")
	var profile := CharacterProfile.new()
	profile.character_name = "Nova"
	profile.pronoun_set_id = &"she_her"
	profile.creation_complete = true
	if not _require(game.call(&"commit_character_profile", profile), "Could not install narrative test profile."):
		return
	var resolved := DialogueDatabase.resolve_text("{player_name}: {subject_cap} {have} {possessive_adjective} marker.", profile)
	if not _require(resolved == "Nova: She has her marker.", "Dialogue token substitution is wrong: %s" % resolved):
		return
	settings.call(&"set_setting", &"instant_text", true, false)
	var dialogue := root.get_node("DialogueController")
	dialogue.call_deferred(&"show_entry", "prologue_rooftop_arrival")
	await process_frame
	if not _require(paused, "Dialogue did not pause hazards, enemies, and world simulation."):
		return
	for _line: int in range(3):
		await _wait_for_line(dialogue)
		dialogue.call(&"advance_for_test")
		await process_frame
	for _frame: int in range(10):
		await process_frame
		if String(dialogue.active_entry_id).is_empty():
			break
	if not _require(String(dialogue.active_entry_id).is_empty() and dialogue.history.size() == 3 and not paused, "Dialogue did not advance through all resolved lines or restore the prior pause state."):
		return
	if not _require(String((dialogue.history[0] as Dictionary).text).contains("Nova"), "Dialogue history did not keep resolved player-name text."):
		return
	var test_player := TestPlayer.new()
	root.add_child(test_player)
	await process_frame
	var director := root.get_node("CutsceneDirector")
	game.seen_cutscenes.erase("rooftop_district_exit")
	game.story_flags.erase("rooftop_alley_complete")
	director.call_deferred(&"play_sequence", "rooftop_district_exit", test_player)
	await process_frame
	director.call(&"request_skip")
	for _frame: int in range(12):
		await process_frame
		if String(director.active_sequence_id).is_empty():
			break
	if not _require(game.has_story_flag(&"rooftop_alley_complete") and not test_player.disabled and bool(game.seen_cutscenes.get("rooftop_district_exit", false)), "Cutscene skip endpoint did not apply required world state and unlock control."):
		return
	for _autosave_frame: int in range(4):
		await process_frame
	var narrative_save: Dictionary = save.call(&"get_save_summary", 3)
	var saved_story_flags := narrative_save.get("story_flags", {}) as Dictionary
	var saved_cutscenes := narrative_save.get("seen_cutscenes", {}) as Dictionary
	if not _require(bool(saved_story_flags.get("rooftop_alley_complete", false)) and bool(saved_cutscenes.get("rooftop_district_exit", false)), "Cutscene completion did not atomically autosave its story flag and seen state."):
		return
	test_player.queue_free()
	await process_frame
	var service := CustomizationService.new()
	root.add_child(service)
	await process_frame
	var original_hair: String = String(game.character_profile.appearance.hair_style_id)
	var alternate_hair := "hair_f2" if original_hair != "hair_f2" else "hair_m1"
	if not _require(service.open(&"barber") and service.set_draft_option(&"hair_style_id", alternate_hair), "Barber preview could not open or update its draft."):
		return
	service.cancel()
	await process_frame
	if not _require(game.character_profile.appearance.hair_style_id == original_hair, "Canceling barber preview mutated the saved profile."):
		return
	var original_top: String = String(game.character_profile.appearance.top_id)
	var alternate_top := "cloth_2" if original_top != "cloth_2" else "cloth_3"
	if not _require(service.open(&"tailor") and service.set_draft_option(&"top_id", alternate_top), "Tailor preview could not open or update its draft."):
		return
	service.confirm()
	await process_frame
	if not _require(game.character_profile.appearance.top_id == alternate_top, "Confirming tailor preview did not commit the profile."):
		return
	var pickup := PersistentPickup.new()
	pickup.configure({"id":"dagger_signal_pair", "family":"dagger", "state_id":"test_dagger_pickup"})
	root.add_child(pickup)
	await process_frame
	if not _require(pickup.collect_for_test(), "Alternate-weapon pickup could not be collected."):
		return
	await process_frame
	if not _require(game.inventory.has_item(&"dagger_signal_pair") and bool(game.world_progress.get_object_state("test_dagger_pickup", false)), "Unique pickup did not persist inventory and world-object state."):
		return
	var reloaded_pickup := PersistentPickup.new()
	reloaded_pickup.configure({"id":"dagger_signal_pair", "family":"dagger", "state_id":"test_dagger_pickup"})
	var reloaded_pickup_reference: WeakRef = weakref(reloaded_pickup)
	root.add_child(reloaded_pickup)
	for _frame: int in range(2):
		await process_frame
	if not _require(reloaded_pickup_reference.get_ref() == null, "Collected unique pickup respawned after reconstruction."):
		return
	if not _require(game.call(&"equip_main_weapon", "dagger_signal_pair", &"dagger") and game.equipment.weapon_family_id == &"dagger", "Collected alternate family could not be equipped."):
		return
	var visual := (load("res://scenes/Player/PlayerVisual.tscn") as PackedScene).instantiate() as PlayerVisual
	root.add_child(visual)
	await process_frame
	var visual_profile: CharacterProfile = game.character_profile.duplicate_profile() as CharacterProfile
	visual_profile.appearance.top_id = "cloth_1"
	visual_profile.appearance.bottom_id = "cloth_3"
	visual.apply_profile(visual_profile)
	if not _require(visual.top_front.visible and visual.bottom_front.visible and visual.top_front.sprite_frames != visual.bottom_front.sprite_frames and (visual.weapon_front.visible or visual.weapon_back.visible), "Layered renderer did not independently map clothing and the newly equipped visible weapon."):
		return
	var market := WorldDatabase.room("cyber_rooftop_market")
	var mara_entries: Array = []
	for service_value: Variant in market.get("services", []):
		var service_data := service_value as Dictionary
		if String(service_data.get("id", "")) == "mara_rooftop":
			mara_entries = service_data.get("dialogue_entries", [])
	var conversation_states := [
		[{"met_mara":true,"helix_warden_defeated":true}, "market_mara_post_helix"],
		[{"met_mara":true,"helix_warden_defeated":true,"assembly_colossus_defeated":true}, "market_mara_post_factory"],
		[{"met_mara":true,"assembly_colossus_defeated":true,"lunar_oracle_defeated":true}, "market_mara_post_oracle"],
		[{"met_mara":true,"game_complete":true}, "market_mara_post_game"],
	]
	for scenario: Array in conversation_states:
		if not _require(_first_eligible_dialogue(mara_entries, scenario[0] as Dictionary) == String(scenario[1]), "Mara dialogue did not update for major-event state %s." % scenario[1]):
			return
	print("NARRATIVE_SERVICES_TEST_OK dialogue=3 skip=true barber=true tailor=true pickup=dagger npc_states=4")
	visual.queue_free()
	service.queue_free()
	await process_frame
	CreatorAnimationCatalog.clear_runtime_cache()
	DialogueDatabase.clear_runtime_cache()
	save.call(&"reset_save", 3)
	quit()


func _wait_for_line(dialogue: Node) -> void:
	for _frame: int in range(60):
		await process_frame
		if not String(dialogue.active_entry_id).is_empty() and bool(dialogue.get("_line_complete")):
			return


func _first_eligible_dialogue(entries: Array, flags: Dictionary) -> String:
	for entry_id: Variant in entries:
		var definition := DialogueDatabase.entry(String(entry_id))
		if DialogueDatabase.conditions_met(definition, flags):
			return String(entry_id)
	return ""


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
