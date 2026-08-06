extends Control

const PLAYER_VISUAL_SCENE := preload("res://scenes/Player/PlayerVisual.tscn")


func _ready() -> void:
	var manager := get_node("/root/GameManager")
	get_node("/root/SaveManager").call(&"save_game")
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call(&"play_bgm", 4)
		audio.call(&"play_sfx", &"ending")
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.015, 0.005, 0.06)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(620.0, 0.0)
	content.add_theme_constant_override("separation", 16)
	center.add_child(content)
	var portrait := PortraitView.new()
	portrait.custom_minimum_size = Vector2(150, 150)
	portrait.show_weapon = true
	content.add_child(portrait)
	portrait.apply_profile(manager.character_profile)
	var title := Label.new()
	title.text = "THE VOID IS SILENT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("27e8ff"))
	content.add_child(title)
	var epilogue := Label.new()
	epilogue.text = PronounResolver.resolve("{player_name} broke the convergence. Cyber City will remember {object}.", manager.character_profile)
	epilogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	epilogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	epilogue.add_theme_font_size_override("font_size", 20)
	content.add_child(epilogue)
	var results := Label.new()
	results.text = "CAMPAIGN COMPLETE\nFINAL SCORE  %06d\nTIME  %s\nCOLLECTIBLES  %d" % [manager.current_score, _format_time(manager.campaign_progress.total_play_time), manager.collected_pickups.size()]
	results.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results.add_theme_font_size_override("font_size", 24)
	content.add_child(results)
	var credits := Button.new()
	credits.text = "VIEW CREDITS"
	credits.pressed.connect(func() -> void: manager.call(&"change_level", "res://scenes/ui/CreditsScreen.tscn"))
	content.add_child(credits)
	var continue_button := Button.new()
	continue_button.text = "CONTINUE EXPLORING"
	continue_button.pressed.connect(func() -> void: manager.call(&"change_level", "res://scenes/world/WorldRoot.tscn"))
	content.add_child(continue_button)
	var title_button := Button.new()
	title_button.text = "RETURN TO TITLE"
	title_button.pressed.connect(func() -> void: manager.call(&"return_to_title"))
	content.add_child(title_button)
	credits.grab_focus.call_deferred()
	var live_visual := PLAYER_VISUAL_SCENE.instantiate() as PlayerVisual
	live_visual.position = Vector2(128, 390)
	live_visual.scale = Vector2(1.35, 1.35)
	add_child(live_visual)
	live_visual.apply_profile(manager.character_profile)
	live_visual.play_animation(&"idle", true)


func _format_time(seconds: float) -> String:
	var total := maxi(roundi(seconds), 0)
	return "%02d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]
