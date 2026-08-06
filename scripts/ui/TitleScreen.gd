extends Control

const CREDITS_SCENE := "res://scenes/ui/CreditsScreen.tscn"

var _save_manager: Node
var _game_manager: Node
var _controls_label: Label


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
	subtitle.text = "PHASEBOUND"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color("ff4fa3")
	menu.add_child(subtitle)
	menu.add_child(HSeparator.new())
	var most_recent_slot := int(_save_manager.call(&"get_most_recent_slot"))
	var continue_button := _menu_button(menu, "CONTINUE", _continue_latest)
	continue_button.disabled = most_recent_slot < 0
	var new_game := _menu_button(menu, "NEW GAME", func() -> void: _game_manager.call(&"open_save_slots", &"new_game"))
	_menu_button(menu, "LOAD GAME", func() -> void: _game_manager.call(&"open_save_slots", &"load"))
	_menu_button(menu, "SETTINGS", _open_settings)
	_menu_button(menu, "CREDITS", func() -> void: _game_manager.call(&"change_level", CREDITS_SCENE))
	_menu_button(menu, "QUIT", func() -> void: get_tree().quit())
	_controls_label = Label.new()
	_controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls_label.modulate = Color(0.66, 0.78, 0.95)
	menu.add_child(_controls_label)
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null:
		for signal_name: StringName in [&"input_device_changed", &"action_binding_changed"]:
			var callback := Callable(self, &"_refresh_controls")
			if settings.has_signal(signal_name) and not settings.is_connected(signal_name, callback):
				settings.connect(signal_name, callback)
	_refresh_controls()
	(continue_button if not continue_button.disabled else new_game).grab_focus.call_deferred()


func _refresh_controls(_unused: Variant = null) -> void:
	if _controls_label == null:
		return
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		_controls_label.text = "CONTROLS AVAILABLE IN SETTINGS"
		return
	var family := StringName(settings.call(&"get_active_input_family"))
	var move := "LEFT STICK" if family == &"controller" else "%s / %s" % [_prompt(&"ui_left"), _prompt(&"ui_right")]
	_controls_label.text = "MOVE: %s   JUMP: %s\nATTACK: %s   TECHNIQUE: %s   DASH: %s   PHASE: %s" % [move, _prompt(&"ui_accept"), _prompt(&"attack_melee"), _prompt(&"attack_shoot"), _prompt(&"slide_dash"), _prompt(&"teleport")]


func _prompt(action: StringName) -> String:
	var settings := get_node_or_null("/root/SettingsManager")
	return String(settings.call(&"get_action_prompt", action)) if settings != null else "UNBOUND"


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


func _continue_latest() -> void:
	var slot := int(_save_manager.call(&"get_most_recent_slot"))
	if slot > 0:
		_save_manager.call(&"set_active_slot", slot)
		_save_manager.call(&"load_game", true, slot)


func _open_settings() -> void:
	var overlay := CenterContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var panel := SettingsPanel.new()
	panel.closed.connect(overlay.queue_free)
	overlay.add_child(panel)
