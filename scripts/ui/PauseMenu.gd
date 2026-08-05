class_name PauseMenu
extends CanvasLayer

var _panel: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	_build_menu()
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_game"):
		if _panel.visible:
			resume()
		else:
			pause()
		get_viewport().set_input_as_handled()


func pause() -> void:
	_panel.visible = true
	get_tree().paused = true
	var first_button := _panel.find_child("ResumeButton", true, false) as Button
	if first_button != null:
		first_button.grab_focus()


func resume() -> void:
	_panel.visible = false
	get_tree().paused = false


func _build_menu() -> void:
	_panel = ColorRect.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.color = Color(0.01, 0.015, 0.06, 0.86)
	add_child(_panel)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(360.0, 0.0)
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)
	var title := Label.new()
	title.text = "SYSTEM PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	_add_button(box, "ResumeButton", "RESUME", resume)
	_add_button(box, "CheckpointButton", "RESTART CHECKPOINT", _restart_checkpoint)
	_add_button(box, "StageButton", "RESTART STAGE", _restart_stage)
	_add_button(box, "SettingsButton", "SETTINGS", _open_settings)
	_add_button(box, "TitleButton", "RETURN TO TITLE", _return_to_title)


func _add_button(parent: Control, node_name: String, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size.y = 44.0
	button.pressed.connect(func() -> void:
		var audio := get_node_or_null("/root/AudioManager")
		if audio != null:
			audio.call(&"play_sfx", &"ui_confirm")
		callback.call()
	)
	parent.add_child(button)


func _restart_checkpoint() -> void:
	resume()
	var stage := get_tree().current_scene as StageBase
	if stage != null and stage.runtime_controller != null:
		stage.runtime_controller.restart_checkpoint()


func _restart_stage() -> void:
	resume()
	get_tree().reload_current_scene()


func _return_to_title() -> void:
	resume()
	get_node("/root/GameManager").call(&"return_to_title")


func _open_settings() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(center)
	var settings := SettingsPanel.new()
	settings.closed.connect(center.queue_free)
	center.add_child(settings)
