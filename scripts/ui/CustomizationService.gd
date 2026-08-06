class_name CustomizationService
extends CanvasLayer

signal service_opened(service_type: StringName)
signal service_closed(service_type: StringName, committed: bool)

const PLAYER_VISUAL_SCENE := preload("res://scenes/Player/PlayerVisual.tscn")

var service_type: StringName = &"barber"
var _draft: CharacterProfile
var _panel: PanelContainer
var _visual: PlayerVisual
var _portrait: PortraitView
var _voice: VoiceBarkPlayer
var _first_control: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	add_to_group(&"customization_service")


func open(next_type: StringName) -> bool:
	if _panel != null:
		return false
	var game := get_node_or_null("/root/GameManager")
	if game == null:
		return false
	service_type = next_type if next_type in [&"barber", &"tailor"] else &"barber"
	_draft = game.character_profile.duplicate_profile()
	game.get_tree().paused = true
	_build()
	_refresh_preview()
	_first_control.grab_focus.call_deferred()
	service_opened.emit(service_type)
	return true


func cancel() -> void:
	_close(false)


func confirm() -> void:
	var game := get_node_or_null("/root/GameManager")
	if game == null or not game.call(&"commit_cosmetic_profile", _draft):
		return
	_close(true)


func draft_profile() -> CharacterProfile:
	return _draft.duplicate_profile() if _draft != null else CharacterProfile.new()


func set_draft_option(property_name: StringName, option_id: String) -> bool:
	if _draft == null or not property_name in [&"face_id", &"hair_style_id", &"hair_color_id", &"top_id", &"top_color_id", &"bottom_id", &"bottom_color_id"]:
		return false
	_draft.appearance.set(property_name, option_id)
	_draft.appearance.sanitize()
	_refresh_preview()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if _panel != null and event.is_action_pressed(&"ui_cancel"):
		cancel()
		get_viewport().set_input_as_handled()


func _build() -> void:
	var shade := ColorRect.new()
	shade.name = "ServiceShade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.02, 0.07, 0.9)
	add_child(shade)
	_panel = PanelContainer.new()
	_panel.name = "CustomizationPanel"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(100, 45)
	_panel.size = Vector2(760, 450)
	add_child(_panel)
	var margin := MarginContainer.new()
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	_panel.add_child(margin)
	var root_box := VBoxContainer.new()
	margin.add_child(root_box)
	var title := Label.new()
	title.text = "SIGNAL BARBER" if service_type == &"barber" else "PHASE TAILOR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	root_box.add_child(title)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(columns)
	var options := VBoxContainer.new()
	options.custom_minimum_size.x = 350
	columns.add_child(options)
	if service_type == &"barber":
		_add_option(options, "FACE", "face", &"face_id")
		_add_option(options, "HAIR", "hair_style", &"hair_style_id")
		_add_option(options, "HAIR COLOR", "hair_color", &"hair_color_id")
		_add_portrait_option(options)
		_add_voice_option(options)
	else:
		_add_option(options, "TOP", "top", &"top_id")
		_add_option(options, "TOP COLOR", "clothing_color", &"top_color_id")
		_add_option(options, "BOTTOM", "bottom", &"bottom_id")
		_add_option(options, "BOTTOM COLOR", "clothing_color", &"bottom_color_id")
	var preview_column := VBoxContainer.new()
	preview_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(preview_column)
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(320, 250)
	container.stretch = true
	preview_column.add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320, 250)
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("0b1730")
	viewport.add_child(background)
	_visual = PLAYER_VISUAL_SCENE.instantiate() as PlayerVisual
	_visual.position = Vector2(160, 145)
	_visual.scale = Vector2(3.0, 3.0)
	viewport.add_child(_visual)
	_portrait = PortraitView.new()
	_portrait.custom_minimum_size = Vector2(110, 110)
	_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_column.add_child(_portrait)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	root_box.add_child(actions)
	var cancel_button := Button.new()
	cancel_button.text = "CANCEL"
	cancel_button.pressed.connect(cancel)
	actions.add_child(cancel_button)
	var confirm_button := Button.new()
	confirm_button.text = "CONFIRM CHANGES"
	confirm_button.pressed.connect(confirm)
	actions.add_child(confirm_button)
	_voice = VoiceBarkPlayer.new()
	add_child(_voice)


func _add_option(parent: Control, label_text: String, category: String, property_name: StringName) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 120
	row.add_child(label)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var current := String(_draft.appearance.get(property_name))
	for entry: Dictionary in CreatorCatalog.options(category):
		option.add_item(String(entry.display_name))
		option.set_item_metadata(option.item_count - 1, String(entry.id))
		if String(entry.id) == current:
			option.select(option.item_count - 1)
	option.item_selected.connect(func(index: int) -> void:
		set_draft_option(property_name, String(option.get_item_metadata(index)))
	)
	row.add_child(option)
	if _first_control == null:
		_first_control = option


func _add_portrait_option(parent: Control) -> void:
	var option := OptionButton.new()
	for entry: Dictionary in CreatorCatalog.portraits():
		option.add_item(String(entry.display_name))
		option.set_item_metadata(option.item_count - 1, String(entry.id))
		if String(entry.id) == _draft.portrait_id:
			option.select(option.item_count - 1)
	option.item_selected.connect(func(index: int) -> void:
		_draft.portrait_id = String(option.get_item_metadata(index))
		_refresh_preview()
	)
	_add_labeled(parent, "PORTRAIT", option)


func _add_voice_option(parent: Control) -> void:
	var row := HBoxContainer.new()
	var option := OptionButton.new()
	for entry: Dictionary in CreatorCatalog.voices():
		option.add_item(String(entry.display_name))
		option.set_item_metadata(option.item_count - 1, String(entry.id))
		if String(entry.id) == _draft.voice_profile_id:
			option.select(option.item_count - 1)
	option.item_selected.connect(func(index: int) -> void:
		_draft.voice_profile_id = String(option.get_item_metadata(index))
	)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(option)
	var preview := Button.new()
	preview.text = "PREVIEW"
	preview.pressed.connect(func() -> void:
		_voice.set_voice_profile(_draft.voice_profile_id)
		_voice.play_bark(&"greeting", true)
	)
	row.add_child(preview)
	_add_labeled(parent, "VOICE", row)


func _add_labeled(parent: Control, label_text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 120
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	if _first_control == null:
		_first_control = control


func _refresh_preview() -> void:
	if _draft == null:
		return
	_draft.sanitize()
	if _visual != null:
		_visual.apply_profile(_draft)
	if _portrait != null:
		_portrait.apply_profile(_draft)


func _close(committed: bool) -> void:
	if _panel == null:
		return
	get_tree().paused = false
	var closed_type := service_type
	for child: Node in get_children():
		child.queue_free()
	_panel = null
	_first_control = null
	_visual = null
	_portrait = null
	_voice = null
	service_closed.emit(closed_type, committed)
