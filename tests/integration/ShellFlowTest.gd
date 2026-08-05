extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var save_directory := OS.get_environment("CCP_TEST_SAVE_DIR")
	if not _require(not save_directory.is_empty(), "Shell test requires CCP_TEST_SAVE_DIR."):
		return
	var save_manager := root.get_node("SaveManager")
	var manager := root.get_node("GameManager")
	save_manager.call(&"reset_save")
	manager.call(&"new_game")

	var title := (load("res://scenes/ui/TitleScreen.tscn") as PackedScene).instantiate() as Control
	root.add_child(title)
	await process_frame
	var continue_button := _find_button(title, "CONTINUE")
	var stage_select_button := _find_button(title, "STAGE SELECT")
	if not _require(continue_button != null and continue_button.disabled, "Continue is enabled without a valid save."):
		return
	if not _require(stage_select_button != null and stage_select_button.disabled, "Stage Select is enabled before campaign completion."):
		return
	for option in ["NEW GAME", "CONTINUE", "STAGE SELECT", "SETTINGS", "CREDITS", "QUIT"]:
		if not _require(_find_button(title, option) != null, "Title screen is missing option: %s" % option):
			return
	title.free()

	var stage := (load("res://Stages/Act1_CyberCity/1-1_RooftopAlley/Stage.tscn") as PackedScene).instantiate() as StageBase
	root.add_child(stage)
	for _frame in range(5):
		await process_frame
	var pause_menu := stage.find_child("PauseMenu", true, false) as PauseMenu
	if not _require(pause_menu != null, "Campaign stage did not install PauseMenu."):
		return
	pause_menu.pause()
	if not _require(paused, "Pause menu did not pause the SceneTree."):
		return
	pause_menu.resume()
	if not _require(not paused, "Pause menu did not resume the SceneTree."):
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
	stage_select_button = _find_button(title, "STAGE SELECT")
	if not _require(stage_select_button != null and not stage_select_button.disabled, "Campaign completion did not unlock Stage Select."):
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
	save_manager.call(&"reset_save")
	print("SHELL_FLOW_TEST_OK title=6 stages=20 pause=true ending=true")
	quit()


func _find_button(ancestor: Node, text: String) -> Button:
	for node: Node in ancestor.find_children("*", "Button", true, false):
		if node is Button and (node as Button).text == text:
			return node as Button
	return null


func _count_buttons(ancestor: Node) -> int:
	return ancestor.find_children("*", "Button", true, false).size()


func _find_label_containing(ancestor: Node, text: String) -> Label:
	for node: Node in ancestor.find_children("*", "Label", true, false):
		if node is Label and (node as Label).text.contains(text):
			return node as Label
	return null


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
