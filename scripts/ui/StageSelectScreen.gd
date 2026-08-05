extends Control


func _ready() -> void:
	var manager := get_node("/root/GameManager")
	if not manager.campaign_progress.campaign_complete:
		manager.call(&"return_to_title")
		return
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.008, 0.015, 0.055)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 32)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var title := Label.new()
	title.text = "STAGE SELECT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	content.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	var registry := get_node("/root/AssetRegistry")
	var first_button: Button
	for act in range(1, 5):
		for substage in range(1, 6):
			var info: Dictionary = registry.call(&"get_stage_info", act, substage)
			var stage_id := "%d-%d" % [act, substage]
			var button := Button.new()
			button.text = "%s\n%s" % [stage_id, String(info.get("display_name", "Stage"))]
			button.custom_minimum_size = Vector2(170.0, 84.0)
			button.pressed.connect(func() -> void: manager.call(&"start_stage_select", stage_id))
			grid.add_child(button)
			if first_button == null:
				first_button = button
	var back := Button.new()
	back.text = "RETURN TO TITLE"
	back.pressed.connect(func() -> void: manager.call(&"return_to_title"))
	content.add_child(back)
	if first_button != null:
		first_button.grab_focus.call_deferred()
