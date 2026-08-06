extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(12.0, true, false, true).timeout.connect(func() -> void:
		push_error("Quest progression test timed out.")
		quit(1)
	)
	if not _require(not OS.get_environment("CCP_TEST_SAVE_DIR").is_empty(), "Quest test requires an isolated save directory."):
		return
	var errors := QuestDatabase.validate()
	if not _require(errors.is_empty(), "Quest database validation failed: %s" % errors):
		return
	var definitions := QuestDatabase.definitions()
	if not _require(definitions.size() == 4 and (definitions.main_phasebound.steps as Array).size() == 21, "Production quest list is incomplete."):
		return

	var game := root.get_node("GameManager")
	var save := root.get_node("SaveManager")
	save.call(&"set_active_slot", 3)
	save.call(&"reset_save", 3)
	game.call(&"new_game")
	var profile := CharacterProfile.new()
	profile.character_name = "Relay"
	profile.creation_complete = true
	if not _require(game.call(&"commit_character_profile", profile), "Quest test could not install a valid profile."):
		return
	var opening: Dictionary = game.call(&"current_quest_objective")
	if not _require(String(opening.id) == "main_phasebound" and String(opening.objective).contains("night-market") and String(opening.target_room_id) == "cyber_rooftop_market", "HUD/map quest objective does not begin at the production prologue destination."):
		return
	var legacy_reconciled := QuestDatabase.reconcile({}, {
		"story_flag": {"prologue_complete":true, "rooftop_alley_complete":true},
		"item": {"dagger_signal_pair":true},
		"ability": {"basic_teleport":true},
		"warp": {"warp_rooftop_overlook":true},
	})
	if not _require(int((legacy_reconciled.main_phasebound as Dictionary).current_step) == 2 and int((legacy_reconciled.lost_arsenal as Dictionary).current_step) == 1 and int((legacy_reconciled.phase_mastery as Dictionary).current_step) == 0 and int((legacy_reconciled.relay_network as Dictionary).current_step) == 1, "Legacy saves with no quest_states did not reconstruct progress from persistent events."):
		return

	var changed_count := [0]
	game.quest_changed.connect(func(_quest_id: StringName, _state: Dictionary) -> void: changed_count[0] += 1)
	var main_steps: Array = definitions.main_phasebound.steps
	for index: int in range(main_steps.size()):
		var step := main_steps[index] as Dictionary
		game.call(&"set_story_flag", StringName(step.event_id), true, false)
		var state := game.quest_states.main_phasebound as Dictionary
		if not _require(int(state.current_step) == index + 1, "Main quest did not advance through %s." % step.id):
			return
	if not _require(String((game.quest_states.main_phasebound as Dictionary).status) == "complete", "Main quest did not complete after the ending flag."):
		return

	for step_value: Variant in definitions.lost_arsenal.steps:
		var step := step_value as Dictionary
		if not _require(game.call(&"add_inventory_item", StringName(step.event_id), 1, true), "Quest weapon event failed for %s." % step.event_id):
			return
	for step_value: Variant in definitions.phase_mastery.steps:
		var step := step_value as Dictionary
		if not _require(game.call(&"grant_ability", StringName(step.event_id)), "Quest ability event failed for %s." % step.event_id):
			return
	for step_value: Variant in definitions.relay_network.steps:
		var step := step_value as Dictionary
		if not _require(game.call(&"activate_warp_node", String(step.event_id)), "Quest warp event failed for %s." % step.event_id):
			return

	for quest_id: String in game.quest_states:
		if not _require(String((game.quest_states[quest_id] as Dictionary).status) == "complete", "Quest %s is not complete after all authored events." % quest_id):
			return
	var journal: Array = game.call(&"quest_journal_entries")
	if not _require(journal.size() == 4 and int(changed_count[0]) >= 4, "Quest changes are not exposed to the Journal/HUD contract (journal=%d signals=%d)." % [journal.size(), changed_count[0]]):
		return
	if not _require(save.call(&"save_game", 3), "Completed quest state could not be saved."):
		return
	game.call(&"new_game")
	if not _require(save.call(&"load_game", false, 3), "Completed quest state could not be reloaded."):
		return
	for quest_id: String in game.quest_states:
		if not _require(String((game.quest_states[quest_id] as Dictionary).status) == "complete", "Quest %s did not survive save/load reconciliation." % quest_id):
			return

	print("QUEST_PROGRESSION_TEST_OK quests=", definitions.size(), " main_steps=", main_steps.size(), " events=", changed_count[0], " legacy_reconcile=true")
	save.call(&"reset_save", 3)
	quit()


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
