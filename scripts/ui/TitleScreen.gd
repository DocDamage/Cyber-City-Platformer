extends Control

const CREDITS_SCENE := "res://scenes/ui/CreditsScreen.tscn"
const STAGE_SELECT_SCENE := "res://scenes/ui/StageSelectScreen.tscn"

var _save_manager: Node
var _game_manager: Node
var _new_game_dialog: ConfirmationDialog


func _ready() -> void:
	_save_manager = get_node("/root/SaveManager")
	_game_manager = get_node("/root/GameManager")
	get_tree().paused = false
	_build_background()
	_build_menu()


func _build_background() -> void:
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = load("res://assets/runtime/environments/parallax/Rooftops 2/back.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.32, 0.46, 0.72)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.02, 0.08, 0.76)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _build_menu() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460.0, 500.0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 30)
	panel.add_child(margin)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	margin.add_child(menu)
	var title := Label.new()
	title.text = "CYBER CITY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("27e8ff"))
	menu.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "NIGHT RUN PROTOCOL"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color("ff4fa3")
	menu.add_child(subtitle)
	menu.add_child(HSeparator.new())
	var new_game := _menu_button(menu, "NEW GAME", _on_new_game_pressed)
	var continue_button := _menu_button(menu, "CONTINUE", _on_continue_pressed)
	continue_button.disabled = not _save_manager.call(&"has_valid_save")
	var stage_select := _menu_button(menu, "STAGE SELECT", _open_stage_select)
	stage_select.disabled = not _saved_campaign_is_complete()
	_menu_button(menu, "SETTINGS", _open_settings)
	_menu_button(menu, "CREDITS", func() -> void: _game_manager.call(&"change_level", CREDITS_SCENE))
	_menu_button(menu, "QUIT", func() -> void: get_tree().quit())
	var controls := Label.new()
	controls.text = "MOVE: ARROWS / STICK   JUMP: SPACE / A\nMELEE: Z / A   SHOOT: X / X   DASH: C / B"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.modulate = Color(0.66, 0.78, 0.95)
	menu.add_child(controls)
	new_game.grab_focus.call_deferred()
	_new_game_dialog = ConfirmationDialog.new()
	_new_game_dialog.title = "Overwrite Current Run?"
	_new_game_dialog.dialog_text = "Starting a new game replaces the current campaign save."
	_new_game_dialog.confirmed.connect(_begin_new_game)
	add_child(_new_game_dialog)


func _menu_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42.0
	button.pressed.connect(func() -> void:
		var audio := get_node_or_null("/root/AudioManager")
		if audio != null:
			audio.call(&"play_sfx", &"ui_confirm")
		callback.call()
	)
	parent.add_child(button)
	return button


func _on_new_game_pressed() -> void:
	if _save_manager.call(&"has_valid_save"):
		_new_game_dialog.popup_centered()
	else:
		_begin_new_game()


func _begin_new_game() -> void:
	_save_manager.call(&"reset_save")
	_game_manager.call(&"start_new_game")


func _on_continue_pressed() -> void:
	_save_manager.call(&"load_game", true)


func _open_stage_select() -> void:
	if _save_manager.call(&"load_game", false):
		_game_manager.call(&"change_level", STAGE_SELECT_SCENE)


func _saved_campaign_is_complete() -> bool:
	var summary: Dictionary = _save_manager.call(&"get_save_summary")
	var progress: Dictionary = summary.get("campaign_progress", {})
	return bool(progress.get("campaign_complete", false))


func _open_settings() -> void:
	var overlay := CenterContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var panel := SettingsPanel.new()
	panel.closed.connect(overlay.queue_free)
	overlay.add_child(panel)
