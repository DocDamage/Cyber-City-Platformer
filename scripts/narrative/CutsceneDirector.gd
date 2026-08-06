extends Node

signal sequence_started(sequence_id: String)
signal command_executed(sequence_id: String, command_type: StringName)
signal sequence_finished(sequence_id: String, skipped: bool)

var active_sequence_id := ""
var skip_requested := false
var _player: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not active_sequence_id.is_empty() and event.is_action_pressed(&"skip_cutscene"):
		request_skip()
		get_viewport().set_input_as_handled()


func play_sequence(sequence_id: String, player_override: Node = null) -> bool:
	if not active_sequence_id.is_empty():
		return false
	var definition := DialogueDatabase.sequence(sequence_id)
	var game := get_node_or_null("/root/GameManager")
	if definition.is_empty() or game == null:
		return false
	if bool(definition.get("once", false)) and bool(game.seen_cutscenes.get(sequence_id, false)):
		return false
	active_sequence_id = sequence_id
	skip_requested = false
	_player = player_override if player_override != null else get_tree().get_first_node_in_group(&"player")
	sequence_started.emit(sequence_id)
	for command_value: Variant in definition.get("commands", []):
		if skip_requested:
			break
		if command_value is Dictionary:
			await _execute_command(command_value as Dictionary, false)
	var skipped := skip_requested
	if skipped:
		var dialogue := get_node_or_null("/root/DialogueController")
		if dialogue != null:
			dialogue.call(&"cancel_current")
		for command_value: Variant in definition.get("skip_endpoint", []):
			if command_value is Dictionary:
				await _execute_command(command_value as Dictionary, true)
	game.seen_cutscenes[sequence_id] = true
	# Sequence commands intentionally batch persistence so skip and played paths
	# cannot save a half-applied endpoint. This final flag commits the complete,
	# deterministic sequence state exactly once.
	game.call(&"set_story_flag", StringName("cutscene_%s_seen" % sequence_id), true, true)
	active_sequence_id = ""
	skip_requested = false
	_player = null
	sequence_finished.emit(sequence_id, skipped)
	return true


func request_skip() -> void:
	if active_sequence_id.is_empty():
		return
	skip_requested = true
	var dialogue := get_node_or_null("/root/DialogueController")
	if dialogue != null:
		dialogue.call(&"cancel_current")


func _execute_command(command: Dictionary, endpoint: bool) -> void:
	var command_type := StringName(command.get("type", ""))
	var game := get_node_or_null("/root/GameManager")
	match command_type:
		&"lock_player":
			if _player != null and _player.has_method(&"set_input_disabled"):
				_player.call(&"set_input_disabled", true)
		&"unlock_player":
			if _player != null and _player.has_method(&"set_input_disabled"):
				_player.call(&"set_input_disabled", false)
		&"dialogue":
			if not endpoint:
				var dialogue := get_node_or_null("/root/DialogueController")
				if dialogue != null:
					await dialogue.call(&"show_entry", String(command.get("entry_id", "")))
		&"wait":
			if not endpoint:
				await get_tree().create_timer(maxf(float(command.get("seconds", 0.0)), 0.0), true, false, true).timeout
		&"set_flag":
			if game != null:
				game.call(&"set_story_flag", StringName(command.get("id", "")), command.get("value", true), false)
		&"grant_item":
			if game != null:
				game.call(&"add_inventory_item", StringName(command.get("id", "")), int(command.get("amount", 1)), bool(command.get("unique", false)))
		&"grant_ability":
			if game != null:
				game.call(&"grant_ability", StringName(command.get("id", "")), int(command.get("amount", 1)))
		&"play_sfx":
			var audio := get_node_or_null("/root/AudioManager")
			if audio != null:
				audio.call(&"play_sfx", StringName(command.get("id", "")))
		&"transition_room":
			if not endpoint:
				var world := get_node_or_null("/root/WorldManager")
				if world != null:
					world.call(&"transition_to", String(command.get("room_id", "")), String(command.get("spawn_id", "west")), false)
		&"finish_game":
			if game != null:
				game.call(&"complete_metroidvania")
	command_executed.emit(active_sequence_id, command_type)
