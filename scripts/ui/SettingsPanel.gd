class_name SettingsPanel
extends PanelContainer

signal closed

var _manager: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(620.0, 500.0)
	_manager = get_node_or_null("/root/SettingsManager")
	_build_interface()


func _build_interface() -> void:
	var margin := MarginContainer.new()
	for side in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 22)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	var title := Label.new()
	title.text = "SYSTEM SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	_add_slider(content, "Master Volume", &"master_volume", 0.0, 1.0, 0.05)
	_add_slider(content, "Music Volume", &"music_volume", 0.0, 1.0, 0.05)
	_add_slider(content, "SFX Volume", &"sfx_volume", 0.0, 1.0, 0.05)
	_add_slider(content, "Screen Shake", &"screen_shake_intensity", 0.0, 1.0, 0.05)
	_add_slider(content, "Controller Deadzone", &"controller_deadzone", 0.05, 0.8, 0.05)
	_add_slider(content, "UI Scale", &"ui_scale", 0.75, 1.5, 0.05)
	var checks := GridContainer.new()
	checks.columns = 2
	content.add_child(checks)
	_add_check(checks, "Fullscreen", &"fullscreen")
	_add_check(checks, "VSync", &"vsync")
	_add_check(checks, "Controller Vibration", &"controller_vibration")
	_add_check(checks, "Reduced Flashing", &"reduced_flashing")
	_add_check(checks, "High-Contrast Interactables", &"high_contrast_interactables")
	_add_check(checks, "Hold-to-Interact", &"hold_to_interact")
	var resolution_row := HBoxContainer.new()
	content.add_child(resolution_row)
	var resolution_label := Label.new()
	resolution_label.text = "Resolution"
	resolution_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resolution_row.add_child(resolution_label)
	var resolution := OptionButton.new()
	for option in ["1280x720", "1600x900", "1920x1080", "2560x1440"]:
		resolution.add_item(option)
	var selected := String(_manager.call(&"get_setting", &"resolution", "1280x720"))
	for index in range(resolution.item_count):
		if resolution.get_item_text(index) == selected:
			resolution.select(index)
			break
	resolution.item_selected.connect(func(index: int) -> void:
		_manager.call(&"set_setting", &"resolution", resolution.get_item_text(index))
	)
	resolution_row.add_child(resolution)
	var remap_hint := Label.new()
	remap_hint.text = "Controls are rebindable through SettingsManager; keyboard and controller bindings remain active together."
	remap_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	remap_hint.modulate = Color(0.65, 0.85, 1.0)
	content.add_child(remap_hint)
	var close_button := Button.new()
	close_button.text = "APPLY & CLOSE"
	close_button.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	content.add_child(close_button)
	close_button.grab_focus.call_deferred()


func _add_slider(parent: Control, label_text: String, setting_id: StringName, minimum: float, maximum: float, step: float) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 210.0
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = float(_manager.call(&"get_setting", setting_id, minimum))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void:
		_manager.call(&"set_setting", setting_id, value)
	)
	row.add_child(slider)


func _add_check(parent: Control, label_text: String, setting_id: StringName) -> void:
	var check := CheckButton.new()
	check.text = label_text
	check.button_pressed = bool(_manager.call(&"get_setting", setting_id, false))
	check.toggled.connect(func(value: bool) -> void:
		_manager.call(&"set_setting", setting_id, value)
	)
	parent.add_child(check)
