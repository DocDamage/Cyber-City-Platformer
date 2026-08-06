extends Control

const PLAYER_VISUAL_SCENE := preload("res://scenes/Player/PlayerVisual.tscn")

var _save_manager: Node
var _game_manager: Node
var _mode: StringName
var _overwrite_dialog: ConfirmationDialog
var _pending_slot := -1
var _delete_dialog: ConfirmationDialog
var _delete_slot := -1


func _ready() -> void:
	_save_manager = get_node("/root/SaveManager")
	_game_manager = get_node("/root/GameManager")
	_mode = _game_manager.pending_save_slot_mode
	_build_background()
	_build_interface()


func _build_background() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("080d20")
	add_child(background)


func _build_interface() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720.0, 480.0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 28)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	var title := Label.new()
	title.text = "SELECT SAVE SLOT — %s" % ("NEW GAME" if _mode == &"new_game" else "LOAD GAME")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("27e8ff"))
	content.add_child(title)
	var first_button: Button
	for entry: Dictionary in _save_manager.call(&"get_slot_summaries"):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 96
		content.add_child(row)
		var portrait := PortraitView.new()
		portrait.custom_minimum_size = Vector2(82, 82)
		portrait.show_weapon = true
		if not (entry.summary as Dictionary).is_empty():
			portrait.apply_profile(_profile_from_summary(entry.summary))
		row.add_child(portrait)
		if not (entry.summary as Dictionary).is_empty():
			_add_live_preview(row, entry.summary, int(entry.slot_id))
		var button := Button.new()
		button.custom_minimum_size.y = 92.0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = _slot_text(entry)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var status := StringName(entry.status)
		button.disabled = _mode == &"load" and status not in [&"valid", &"recoverable", &"legacy"]
		button.pressed.connect(_select_slot.bind(int(entry.slot_id), status))
		row.add_child(button)
		var delete_button := Button.new()
		delete_button.text = "DELETE"
		delete_button.custom_minimum_size.x = 82
		delete_button.disabled = status == &"empty"
		delete_button.pressed.connect(_request_delete.bind(int(entry.slot_id)))
		row.add_child(delete_button)
		if first_button == null and not button.disabled:
			first_button = button
	var back := Button.new()
	back.text = "RETURN"
	back.custom_minimum_size.y = 44.0
	back.pressed.connect(func() -> void: _game_manager.call(&"return_to_title"))
	content.add_child(back)
	(first_button if first_button != null else back).grab_focus.call_deferred()
	_overwrite_dialog = ConfirmationDialog.new()
	_overwrite_dialog.title = "Overwrite Slot?"
	_overwrite_dialog.dialog_text = "This slot already contains a campaign. Its current save and backup will be replaced."
	_overwrite_dialog.confirmed.connect(_confirm_new_game)
	add_child(_overwrite_dialog)
	_delete_dialog = ConfirmationDialog.new()
	_delete_dialog.title = "Delete Campaign?"
	_delete_dialog.dialog_text = "Delete this slot and its recovery backup? This cannot be undone."
	_delete_dialog.confirmed.connect(_confirm_delete)
	add_child(_delete_dialog)


func _add_live_preview(row: HBoxContainer, summary: Dictionary, slot_id: int) -> void:
	var container := SubViewportContainer.new()
	container.name = "Slot%dLivePreview" % slot_id
	container.custom_minimum_size = Vector2(92, 92)
	container.stretch = true
	container.tooltip_text = "Exact saved character appearance and equipped weapon"
	row.add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(92, 92)
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("0b1730")
	viewport.add_child(background)
	var visual := PLAYER_VISUAL_SCENE.instantiate() as PlayerVisual
	visual.name = "Slot%dPlayerVisual" % slot_id
	visual.position = Vector2(46, 55)
	visual.scale = Vector2(1.75, 1.75)
	viewport.add_child(visual)
	visual.apply_profile(_profile_from_summary(summary))
	visual.play_animation(&"idle", true)


func _slot_text(entry: Dictionary) -> String:
	var slot := int(entry.slot_id)
	var status := StringName(entry.status)
	if status == &"empty":
		return "SLOT %d\n  EMPTY" % slot
	if status == &"corrupt":
		return "SLOT %d\n  CORRUPTED — NO RECOVERABLE BACKUP" % slot
	var summary: Dictionary = entry.summary
	var recovery := "  [BACKUP RECOVERY AVAILABLE]" if status == &"recoverable" else ("  [LEGACY SAVE — MIGRATES ON LOAD]" if status == &"legacy" else "")
	return "SLOT %d%s\n  %s  •  %s / %s  •  %s\n  MAP %d%%  •  %s  •  %s" % [
		slot,
		recovery,
		String(summary.get("character_name", "Runner")),
		_pretty(String(summary.get("region_id", "cyber_city"))),
		_pretty(String(summary.get("district_id", "rooftop_alley"))),
		_format_time(float(summary.get("play_time", 0.0))),
		roundi(float(summary.get("map_completion", 0.0)) * 100.0),
		String(summary.get("weapon_family_id", "sword")).to_upper(),
		String(entry.saved_at_utc),
	]


func _select_slot(slot: int, status: StringName) -> void:
	if _mode == &"load":
		_save_manager.call(&"set_active_slot", slot)
		_save_manager.call(&"load_game", true, slot)
		return
	_pending_slot = slot
	if status in [&"valid", &"recoverable", &"legacy", &"corrupt"]:
		_overwrite_dialog.popup_centered()
	else:
		_confirm_new_game()


func _confirm_new_game() -> void:
	if _pending_slot > 0:
		_game_manager.call(&"start_character_creation", _pending_slot)


func _request_delete(slot: int) -> void:
	_delete_slot = slot
	_delete_dialog.popup_centered()


func _confirm_delete() -> void:
	if _delete_slot <= 0:
		return
	_save_manager.call(&"reset_save", _delete_slot)
	get_tree().reload_current_scene()


func _profile_from_summary(summary: Dictionary) -> CharacterProfile:
	var profile := CharacterProfile.new()
	profile.character_name = String(summary.get("character_name", "Runner"))
	profile.portrait_id = String(summary.get("portrait_id", "portrait_01"))
	profile.pronoun_set_id = StringName(summary.get("pronoun_set_id", "they_them"))
	profile.voice_profile_id = String(summary.get("voice_profile_id", "voice_01"))
	profile.starting_weapon_family = StringName(summary.get("weapon_family_id", "sword"))
	profile.appearance.load_dict(summary.get("appearance", {}))
	profile.sanitize()
	return profile


func _format_time(seconds: float) -> String:
	var total := maxi(int(seconds), 0)
	return "%02d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]


func _pretty(value: String) -> String:
	return value.replace("_", " ").capitalize()
