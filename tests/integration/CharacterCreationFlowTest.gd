extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(15.0, true, false, true).timeout.connect(func() -> void:
		push_error("Character creation flow test timed out.")
		quit(1)
	)
	var save_directory := OS.get_environment("CCP_TEST_SAVE_DIR")
	if not _require(not save_directory.is_empty(), "Character creation flow test requires CCP_TEST_SAVE_DIR."):
		return
	var manager := root.get_node("GameManager")
	var save_manager := root.get_node("SaveManager")
	save_manager.call(&"reset_all_slots")
	manager.call(&"new_game")

	manager.call(&"open_save_slots", &"new_game")
	var slots := await _wait_for_scene(&"SaveSlotScreen", manager)
	if not _require(slots != null, "New Game did not open save-slot selection."):
		return
	slots.call(&"_select_slot", 2, &"empty")
	var creator := await _wait_for_scene(&"CharacterCreator", manager)
	if not _require(creator != null and int(save_manager.active_slot) == 2, "Selecting slot 2 did not open Character Creator with the requested active slot."):
		return
	for _layout_frame: int in range(3):
		await process_frame
	var action_bar := creator.get("_action_bar") as Control
	var creator_scroll := creator.get("_creator_scroll") as ScrollContainer
	var creator_bounds: Rect2 = creator.get_global_rect()
	var action_bounds: Rect2 = action_bar.get_global_rect() if action_bar != null else Rect2()
	if not _require(action_bar != null and action_bar.is_visible_in_tree() and creator_bounds.encloses(action_bounds), "Character Creator action bar is clipped outside the 960x540 design viewport: creator=%s actions=%s" % [creator_bounds, action_bounds]):
		return
	var layout_controls: Dictionary = creator.get("_option_controls")
	var creator_scrollbar: VScrollBar = creator_scroll.get_v_scroll_bar() if creator_scroll != null else null
	var last_option := layout_controls.get(&"portrait_id") as Control
	var scroll_bounds: Rect2 = creator_scroll.get_global_rect() if creator_scroll != null else Rect2()
	var last_option_bounds: Rect2 = last_option.get_global_rect() if last_option != null else Rect2()
	var options_scrollable := creator_scrollbar != null and creator_scrollbar.max_value > creator_scrollbar.page
	var final_option_visible := last_option != null and scroll_bounds.encloses(last_option_bounds)
	if not _require(creator_scroll != null and creator_scrollbar != null and (options_scrollable or final_option_visible), "Character Creator final options are neither visible nor vertically scrollable: scroll=%s option=%s range=%.1f/%.1f" % [scroll_bounds, last_option_bounds, creator_scrollbar.max_value, creator_scrollbar.page]):
		return

	var controls: Dictionary = layout_controls
	for control_id: StringName in [&"body_id", &"skin_tone_id", &"face_id", &"hair_style_id", &"hair_color_id", &"top_id", &"top_color_id", &"bottom_id", &"bottom_color_id", &"starting_weapon_family", &"portrait_id"]:
		if not _require(controls.has(control_id) and controls[control_id] is OptionButton, "Character Creator did not map option control '%s'." % control_id):
			return

	var draft := creator.get("_draft") as CharacterProfile
	var name_edit := creator.get("_name_edit") as LineEdit
	name_edit.text = "Vexa"
	draft.pronoun_set_id = &"she_her"
	draft.voice_profile_id = "voice_05"
	draft.portrait_id = "portrait_12"
	draft.starting_weapon_family = &"staff"
	draft.appearance.skin_tone_id = "skin_06"
	draft.appearance.face_id = "face_07"
	draft.appearance.hair_style_id = "hair_m1"
	draft.appearance.hair_color_id = "hair_color_magenta"
	draft.appearance.top_id = "cloth_3"
	draft.appearance.top_color_id = "cloth_color_gold"
	draft.appearance.bottom_id = "cloth_2"
	draft.appearance.bottom_color_id = "cloth_color_cyan"
	creator.call(&"_refresh_preview")
	creator.call(&"_confirm_character")

	var world := await _wait_for_scene(&"WorldRoot", manager, 360)
	if not _require(world != null, "Confirming a valid character did not enter WorldRoot."):
		return
	for _frame: int in range(8):
		await process_frame
	if not _require(manager.character_profile.creation_complete and manager.character_profile.character_name == "Vexa", "Confirmed character profile was not committed."):
		return
	if not _require(manager.character_profile.pronoun_set_id == &"she_her" and manager.character_profile.voice_profile_id == "voice_05", "Identity selections did not reach gameplay state."):
		return
	if not _require(manager.equipment.weapon_family_id == &"staff" and manager.inventory.has_item(&"staff_lumen_rod"), "Starting weapon selection did not initialize equipment and inventory."):
		return
	if not _require(manager.world_progress.current_room_id == WorldProgress.START_ROOM and manager.world_progress.discovered_rooms.has(WorldProgress.START_ROOM), "WorldRoot did not load and discover the starting room."):
		return
	var visual := world.get_node("Player/PlayerVisual") as PlayerVisual
	if not _require(visual != null and visual.profile.character_name == "Vexa" and visual.profile.starting_weapon_family == &"staff", "Gameplay PlayerVisual did not receive the confirmed character profile."):
		return
	if not _require(save_manager.call(&"has_valid_save", 2), "Character confirmation did not create the selected slot's initial save."):
		return
	var saved_payload: Dictionary = save_manager.call(&"get_save_summary", 2)
	var summary: Dictionary = saved_payload.get("summary", {})
	if not _require(String(summary.get("character_name", "")) == "Vexa" and String(summary.get("weapon_family_id", "")) == "staff", "Initial save summary does not match the created character."):
		return

	manager.call(&"open_save_slots", &"load")
	var load_slots := await _wait_for_scene(&"SaveSlotScreen", manager)
	if not _require(load_slots != null, "Load Game did not reopen save-slot selection."):
		return
	var slot_visuals := load_slots.find_children("Slot*PlayerVisual", "PlayerVisual", true, false)
	if not _require(slot_visuals.size() == 1, "Save-slot selection did not render one exact live preview for the occupied slot."):
		return
	var slot_visual := slot_visuals[0] as PlayerVisual
	var preview_appearance := slot_visual.profile.appearance
	if not _require(slot_visual.profile.character_name == "Vexa" and preview_appearance.skin_tone_id == "skin_06" and preview_appearance.face_id == "face_07" and preview_appearance.hair_style_id == "hair_m1" and preview_appearance.hair_color_id == "hair_color_magenta" and preview_appearance.top_id == "cloth_3" and preview_appearance.top_color_id == "cloth_color_gold" and preview_appearance.bottom_id == "cloth_2" and preview_appearance.bottom_color_id == "cloth_color_cyan" and slot_visual.profile.starting_weapon_family == &"staff", "Save-slot live preview mismatch: profile=%s summary=%s" % [slot_visual.profile.to_dict(), summary]):
		return

	manager.call(&"new_game")
	if not _require(save_manager.call(&"load_game", false, 2), "Created character save could not be loaded."):
		return
	if not _require(manager.character_profile.character_name == "Vexa" and manager.character_profile.appearance.top_id == "cloth_3" and manager.equipment.weapon_family_id == &"staff", "Character profile did not survive the save/load round trip."):
		return

	save_manager.call(&"reset_all_slots")
	print("CHARACTER_CREATION_FLOW_TEST_OK slot=2 room=", manager.world_progress.current_room_id, " weapon=", manager.equipment.weapon_family_id)
	var dialogue := root.get_node("DialogueController")
	dialogue.call(&"cancel_current")
	await process_frame
	var dialogue_voice := dialogue.get("_voice") as VoiceBarkPlayer
	if dialogue_voice != null:
		dialogue_voice.stop_bark()
	if is_instance_valid(world):
		for bark_node: Node in world.find_children("*", "VoiceBarkPlayer", true, false):
			(bark_node as VoiceBarkPlayer).stop_bark()
	await process_frame
	current_scene = null
	if is_instance_valid(world):
		world.queue_free()
	if is_instance_valid(load_slots):
		load_slots.queue_free()
	world = null
	visual = null
	slot_visual = null
	slot_visuals.clear()
	load_slots = null
	dialogue_voice = null
	dialogue = null
	creator = null
	action_bar = null
	creator_scroll = null
	creator_scrollbar = null
	last_option = null
	slots = null
	name_edit = null
	draft = null
	controls.clear()
	for _frame: int in range(4):
		await process_frame
	CreatorAnimationCatalog.clear_runtime_cache()
	for _frame: int in range(2):
		await process_frame
	quit()


func _wait_for_scene(scene_name: StringName, manager: Node, frame_limit := 240) -> Node:
	for _frame: int in range(frame_limit):
		await process_frame
		if current_scene != null and current_scene.name == scene_name and not bool(manager.get("_transitioning")):
			return current_scene
	return null


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
