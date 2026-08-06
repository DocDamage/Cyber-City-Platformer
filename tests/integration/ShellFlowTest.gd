extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var save_directory := OS.get_environment("CCP_TEST_SAVE_DIR")
	if not _require(not save_directory.is_empty(), "Shell test requires CCP_TEST_SAVE_DIR."):
		return
	var save_manager := root.get_node("SaveManager")
	var manager := root.get_node("GameManager")
	var settings := root.get_node("SettingsManager")
	save_manager.call(&"reset_all_slots")
	manager.call(&"new_game")

	var title := (load("res://scenes/ui/TitleScreen.tscn") as PackedScene).instantiate() as Control
	root.add_child(title)
	await process_frame
	var continue_button := _find_button(title, "CONTINUE")
	if not _require(continue_button != null and continue_button.disabled, "Continue is enabled without a valid save."):
		return
	if not _require(_find_button(title, "STAGE SELECT") == null, "Legacy Stage Select leaked into the player-facing title flow."):
		return
	for option in ["NEW GAME", "CONTINUE", "LOAD GAME", "SETTINGS", "CREDITS", "QUIT"]:
		if not _require(_find_button(title, option) != null, "Title screen is missing option: %s" % option):
			return
	if not _require(_find_label_containing(title, "ATTACK: Z") != null and _find_label_containing(title, "V / TRIGGER") == null, "Title screen did not render the current keyboard bindings."):
		return
	var controller_input := InputEventJoypadButton.new()
	controller_input.button_index = JOY_BUTTON_X
	controller_input.pressed = true
	settings.call(&"_input", controller_input)
	if not _require(_find_label_containing(title, "ATTACK: X / SQUARE") != null and _find_label_containing(title, "PHASE: RB / R1") != null, "Title prompts did not switch immediately to the current controller layout."):
		return
	title.free()

	var stage := (load("res://Stages/Act1_CyberCity/1-1_RooftopAlley/Stage.tscn") as PackedScene).instantiate() as StageBase
	root.add_child(stage)
	for _frame in range(5):
		await process_frame
	var pause_menu := stage.find_child("PauseMenu", true, false) as PauseMenu
	if not _require(pause_menu != null, "Campaign stage did not install PauseMenu."):
		return
	manager.call(&"add_inventory_item", &"bow_lunar_prism", 1, true)
	pause_menu.pause()
	if not _require(paused, "Pause menu did not pause the SceneTree."):
		return
	var map_views := pause_menu.find_children("*", "WorldMapView", true, false)
	if not _require(map_views.size() == 1 and _find_label_containing(pause_menu, "VIEW / SHARE: close") != null, "Controller map help did not expose the live map binding."):
		return
	var map_view := map_views[0] as WorldMapView
	var completion := map_view.completion_percentages(manager)
	if not _require(map_view.objective_room_id(manager) == "cyber_rooftop_market" and completion.has("overall") and completion.has("cyber_city") and completion.has("robot_factory") and completion.has("neon_moon") and completion.has("abyssal_night") and int(completion.cyber_city) > 0 and int(completion.robot_factory) == 0, "Map does not expose the main-objective destination and per-region/overall completion contract."):
		return
	var initial_zoom := map_view.zoom
	var zoom_input := InputEventJoypadButton.new()
	zoom_input.button_index = JOY_BUTTON_RIGHT_SHOULDER
	zoom_input.pressed = true
	map_view.call(&"_gui_input", zoom_input)
	if not _require(map_view.zoom > initial_zoom, "Controller map zoom input was not handled."):
		return
	pause_menu.pause(1)
	await process_frame
	var lunar_prism_button := _find_button_containing(pause_menu, "Lunar Prism")
	var equipment_selectors := pause_menu.find_children("*", "OptionButton", true, false).size()
	var has_module_slots := _find_label_containing(pause_menu, "MODULE SLOTS") != null
	var has_comparison := _find_label_containing(pause_menu, "LIVE → PREVIEW") != null
	if not _require(equipment_selectors == 2 and has_module_slots and has_comparison and lunar_prism_button != null and lunar_prism_button.icon != null and lunar_prism_button.get_theme_constant("icon_max_width") == WeaponCatalog.ICON_RUNTIME_SIZE, "Equipment tab lacks slots, sort/filter, stat comparison, curated icons, or collected variants (selectors=%d slots=%s comparison=%s variant=%s)." % [equipment_selectors, has_module_slots, has_comparison, lunar_prism_button != null]):
		return
	lunar_prism_button.pressed.emit()
	await process_frame
	if not _require(manager.equipment.main_weapon_id == "bow_lunar_prism" and manager.equipment.weapon_family_id == &"bow" and _find_label_containing(pause_menu, "EQUIPPED LUNAR PRISM") != null, "Collected weapon variant did not equip with immediate confirmation."):
		return
	pause_menu.set("_equipment_filter_mode", 1)
	pause_menu.call(&"_refresh_equipment", manager)
	await process_frame
	var locked_maul_button := _find_button_containing(pause_menu, "Foundry Maul")
	if not _require(locked_maul_button != null and locked_maul_button.disabled and locked_maul_button.icon != null and locked_maul_button.icon.resource_path == WeaponCatalog.UNKNOWN_ICON_PATH, "Locked equipment did not use the curated unknown-item fallback icon."):
		return
	pause_menu.pause(2)
	if not _require(_find_rich_text_containing(pause_menu, "Cleanroom prism limbs") != null and _find_rich_text_containing(pause_menu, "[EQUIPPED]") != null and _find_rich_text_containing(pause_menu, "KEY ITEMS") != null and _find_rich_text_containing(pause_menu, "MATERIALS") != null, "Inventory tab lacks taxonomy, description, lore, or equip status."):
		return
	pause_menu.pause(3)
	if not _require(_find_rich_text_containing(pause_menu, "Hold RB / R1 to aim") != null and _find_rich_text_containing(pause_menu, "Hold V / RB") == null, "Abilities help did not render the current controller bindings."):
		return
	pause_menu.resume()
	if not _require(not paused, "Pause menu did not resume the SceneTree."):
		return
	var tabs := pause_menu.find_child("*", true, false) as Control
	var tab_container := pause_menu.find_children("*", "TabContainer", true, false)
	if not _require(tab_container.size() == 1 and (tab_container[0] as TabContainer).get_tab_count() == 6, "Pause root does not expose the six metroidvania tabs."):
		return
	stage.free()
	await process_frame

	manager.campaign_progress.campaign_complete = true
	manager.current_score = 654321
	manager.run_state.stage_scene = "res://Stages/Act4_AbyssalNight/4-5_HeartOfTheVoid/Stage.tscn"
	manager.run_state.stage_id = "4-5"
	if not _require(save_manager.call(&"save_game"), "Completed campaign save failed."):
		return
	title = (load("res://scenes/ui/TitleScreen.tscn") as PackedScene).instantiate() as Control
	root.add_child(title)
	await process_frame
	continue_button = _find_button(title, "CONTINUE")
	if not _require(continue_button != null and not continue_button.disabled, "A valid campaign slot did not enable Continue."):
		return
	title.free()

	var stage_select := (load("res://scenes/ui/StageSelectScreen.tscn") as PackedScene).instantiate() as Control
	root.add_child(stage_select)
	await process_frame
	if not _require(_count_buttons(stage_select) == 21, "Stage Select does not contain twenty stages plus Return."):
		return
	stage_select.free()
	var ending := (load("res://scenes/ui/EndingScreen.tscn") as PackedScene).instantiate() as Control
	root.add_child(ending)
	await process_frame
	if not _require(_find_label_containing(ending, "654321") != null, "Ending results do not show the saved final score."):
		return
	ending.free()
	var credits := (load("res://scenes/ui/CreditsScreen.tscn") as PackedScene).instantiate() as Control
	root.add_child(credits)
	await process_frame
	if not _require(_find_label_containing(credits, "Godot Engine 4.7") != null, "Credits content is incomplete."):
		return
	credits.free()
	save_manager.call(&"reset_all_slots")
	print("SHELL_FLOW_TEST_OK title=6 tabs=6 debug_stages=20 ending=true")
	quit()


func _find_button(ancestor: Node, text: String) -> Button:
	for node: Node in ancestor.find_children("*", "Button", true, false):
		if node is Button and (node as Button).text == text:
			return node as Button
	return null


func _find_button_containing(ancestor: Node, text: String) -> Button:
	for node: Node in ancestor.find_children("*", "Button", true, false):
		if node is Button and (node as Button).text.contains(text):
			return node as Button
	return null


func _count_buttons(ancestor: Node) -> int:
	return ancestor.find_children("*", "Button", true, false).size()


func _find_label_containing(ancestor: Node, text: String) -> Label:
	for node: Node in ancestor.find_children("*", "Label", true, false):
		if node is Label and (node as Label).text.contains(text):
			return node as Label
	return null


func _find_rich_text_containing(ancestor: Node, text: String) -> RichTextLabel:
	for node: Node in ancestor.find_children("*", "RichTextLabel", true, false):
		if node is RichTextLabel and (node as RichTextLabel).text.contains(text):
			return node as RichTextLabel
	return null


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
