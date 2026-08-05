extends Control


func _ready() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.008, 0.012, 0.05)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(680.0, 0.0)
	content.add_theme_constant_override("separation", 14)
	center.add_child(content)
	var title := Label.new()
	title.text = "CREDITS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	content.add_child(title)
	var text := Label.new()
	text.text = "CYBER CITY PLATFORMER\n\nDesign, engineering, and production: DocDamage\nBuilt with Godot Engine 4.7\n\nThird-party art, music, and sound are credited in\nassets/runtime/LICENSE_MANIFEST.json and LICENSES.md.\n\nThank you for running the night protocol."
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 20)
	content.add_child(text)
	var back := Button.new()
	back.text = "RETURN TO TITLE"
	back.pressed.connect(func() -> void: get_node("/root/GameManager").call(&"return_to_title"))
	content.add_child(back)
	back.grab_focus.call_deferred()
