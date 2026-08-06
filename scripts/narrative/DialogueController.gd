extends CanvasLayer

signal dialogue_started(entry_id: String)
signal line_presented(line_id: String, resolved_text: String)
signal dialogue_finished(entry_id: String, completed: bool)

var history: Array[Dictionary] = []
var active_entry_id := ""
var _panel: PanelContainer
var _speaker: Label
var _text: RichTextLabel
var _prompt: Label
var _portrait: PortraitView
var _choices: VBoxContainer
var _voice: VoiceBarkPlayer
var _line_complete := false
var _advance_requested := false
var _cancel_requested := false
var _typing_text := ""
var _visible_characters := 0.0
var _current_line: Dictionary = {}
var _pause_state_before_dialogue := false
var _owns_dialogue_pause := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110
	_build_interface()
	_panel.visible = false
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null:
		for signal_name: StringName in [&"input_device_changed", &"action_binding_changed"]:
			var callback := Callable(self, &"_refresh_continue_prompt")
			if settings.has_signal(signal_name) and not settings.is_connected(signal_name, callback):
				settings.connect(signal_name, callback)


func _exit_tree() -> void:
	if _voice != null:
		_voice.stop_bark()
	_restore_pause_state()


func _process(delta: float) -> void:
	if active_entry_id.is_empty() or _line_complete or _typing_text.is_empty():
		return
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and bool(settings.call(&"get_setting", &"instant_text", false)):
		_finish_typing()
		return
	var speed_scale := float(settings.call(&"get_setting", &"text_speed", 1.0)) if settings != null else 1.0
	_visible_characters += delta * 42.0 * speed_scale
	_text.visible_characters = mini(floori(_visible_characters), _typing_text.length())
	if _text.visible_characters >= _typing_text.length():
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if active_entry_id.is_empty():
		return
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact"):
		if not _line_complete:
			_finish_typing()
		elif _choices.get_child_count() == 0:
			_advance_requested = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dialogue_backlog"):
		_show_backlog()
		get_viewport().set_input_as_handled()


func show_entry(entry_id: String) -> bool:
	if not active_entry_id.is_empty():
		return false
	var definition := DialogueDatabase.entry(entry_id)
	var game := get_node_or_null("/root/GameManager")
	if definition.is_empty() or game == null or not DialogueDatabase.conditions_met(definition, game.story_flags):
		return false
	active_entry_id = entry_id
	_pause_state_before_dialogue = get_tree().paused
	_owns_dialogue_pause = true
	get_tree().paused = true
	_cancel_requested = false
	_panel.visible = true
	dialogue_started.emit(entry_id)
	for line_value: Variant in definition.get("lines", []):
		if _cancel_requested:
			break
		if line_value is Dictionary:
			await _present_line(line_value as Dictionary, game.character_profile)
	if not _cancel_requested:
		_apply_rewards(definition.get("rewards", []), game)
	var completed := not _cancel_requested
	_panel.visible = false
	active_entry_id = ""
	_current_line.clear()
	_voice.stop_bark()
	_restore_pause_state()
	dialogue_finished.emit(entry_id, completed)
	return completed


func cancel_current() -> void:
	if active_entry_id.is_empty():
		return
	_cancel_requested = true
	_advance_requested = true
	_clear_choices()


func advance_for_test() -> void:
	if not _line_complete:
		_finish_typing()
	else:
		_advance_requested = true


func resolved_history() -> Array[Dictionary]:
	return history.duplicate(true)


func clear_history() -> void:
	history.clear()


func _restore_pause_state() -> void:
	if not _owns_dialogue_pause:
		return
	if get_tree() != null:
		get_tree().paused = _pause_state_before_dialogue
	_owns_dialogue_pause = false


func _present_line(line: Dictionary, profile: CharacterProfile) -> void:
	_current_line = line.duplicate(true)
	var speaker := DialogueDatabase.resolve_text(String(line.get("speaker", "")), profile)
	var resolved := DialogueDatabase.resolve_text(String(line.get("text", "")), profile)
	_speaker.text = speaker
	_typing_text = resolved
	_text.text = resolved
	_text.visible_characters = 0
	_visible_characters = 0.0
	_line_complete = false
	_advance_requested = false
	_prompt.text = ""
	_clear_choices()
	var portrait_profile := profile.duplicate_profile()
	if String(line.get("portrait", "")) != "player":
		portrait_profile.portrait_id = String(line.get("portrait_id", "portrait_12"))
	_portrait.apply_profile(portrait_profile)
	var bark := StringName(line.get("voice_bark", ""))
	if not bark.is_empty():
		_voice.set_voice_profile(profile.voice_profile_id)
		_voice.play_bark(bark)
	history.append({"entry_id": active_entry_id, "line_id": String(line.get("id", "")), "speaker": speaker, "text": resolved})
	while history.size() > 100:
		history.pop_front()
	line_presented.emit(String(line.get("id", "")), resolved)
	while not _line_complete and not _cancel_requested:
		await get_tree().process_frame
	if _cancel_requested:
		return
	var choices: Array = line.get("choices", [])
	if not choices.is_empty():
		_build_choices(choices)
	else:
		_prompt.text = _continue_prompt()
		var settings := get_node_or_null("/root/SettingsManager")
		if settings != null and bool(settings.call(&"get_setting", &"auto_advance", false)):
			await get_tree().create_timer(0.85, true, false, true).timeout
			_advance_requested = true
	while not _advance_requested and not _cancel_requested:
		await get_tree().process_frame


func _finish_typing() -> void:
	if _line_complete:
		return
	_line_complete = true
	_text.visible_characters = -1


func _build_choices(choices: Array) -> void:
	for choice_value: Variant in choices:
		if choice_value is not Dictionary:
			continue
		var choice := choice_value as Dictionary
		var button := Button.new()
		button.text = String(choice.get("text", "Continue"))
		button.pressed.connect(func() -> void:
			var game := get_node_or_null("/root/GameManager")
			if game != null and choice.has("set_flag"):
				game.call(&"set_story_flag", StringName(choice.get("set_flag", "")), choice.get("value", true), false)
			_advance_requested = true
		)
		_choices.add_child(button)
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus.call_deferred()


func _apply_rewards(rewards: Variant, game: Node) -> void:
	if rewards is not Array:
		return
	for reward_value: Variant in rewards:
		if reward_value is not Dictionary:
			continue
		var reward := reward_value as Dictionary
		match String(reward.get("type", "")):
			"story_flag": game.call(&"set_story_flag", StringName(reward.get("id", "")), reward.get("value", true), false)
			"item": game.call(&"add_inventory_item", StringName(reward.get("id", "")), int(reward.get("amount", 1)), bool(reward.get("unique", false)))
			"ability": game.call(&"grant_ability", StringName(reward.get("id", "")), int(reward.get("amount", 1)))


func _continue_prompt() -> String:
	var settings := get_node_or_null("/root/SettingsManager")
	var binding := String(settings.call(&"get_action_prompt", &"interact")) if settings != null else "INTERACT"
	var backlog := String(settings.call(&"get_action_prompt", &"dialogue_backlog")) if settings != null else "BACKLOG"
	return "%s  CONTINUE   •   %s  BACKLOG" % [binding, backlog]


func _refresh_continue_prompt(_unused: Variant = null) -> void:
	if not active_entry_id.is_empty() and _line_complete and _choices.get_child_count() == 0:
		_prompt.text = _continue_prompt()


func _show_backlog() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "DIALOGUE BACKLOG"
	var lines := PackedStringArray()
	for item: Dictionary in history:
		lines.append("%s: %s" % [item.speaker, item.text])
	dialog.dialog_text = "\n\n".join(lines)
	add_child(dialog)
	dialog.popup_centered_ratio(0.75)
	dialog.confirmed.connect(dialog.queue_free)


func _clear_choices() -> void:
	for child: Node in _choices.get_children():
		child.queue_free()


func _build_interface() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DialoguePanel"
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 36.0
	_panel.offset_top = -214.0
	_panel.offset_right = -36.0
	_panel.offset_bottom = -24.0
	add_child(_panel)
	var margin := MarginContainer.new()
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)
	_portrait = PortraitView.new()
	_portrait.custom_minimum_size = Vector2(148, 148)
	row.add_child(_portrait)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(content)
	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 22)
	_speaker.add_theme_color_override("font_color", Color("27e8ff"))
	content.add_child(_speaker)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = false
	_text.custom_minimum_size.y = 78
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 18)
	content.add_child(_text)
	_choices = VBoxContainer.new()
	content.add_child(_choices)
	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt.modulate = Color(0.65, 0.8, 0.92)
	content.add_child(_prompt)
	_voice = VoiceBarkPlayer.new()
	add_child(_voice)
