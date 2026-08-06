extends Control

const PLAYER_VISUAL_SCENE := preload("res://scenes/Player/PlayerVisual.tscn")
const WEAPON_DESCRIPTIONS := {
	"sword": "BALANCED • medium reach • reliable three-hit combo",
	"dagger": "FAST • short reach • aerial and teleport synergy",
	"spear": "PRECISE • long forward reach • strong anti-air control",
	"heavy": "POWERFUL • slow commitment • armor and barrier break",
	"bow": "RANGED • charge and aim • energy-powered arrows",
	"staff": "ARCANE • projectiles and zones • high energy dependence",
}
const CYAN := Color("27e8ff")
const MAGENTA := Color("ff5dbd")
const PANEL_FILL := Color(0.025, 0.055, 0.12, 0.94)
const PANEL_BORDER := Color(0.12, 0.55, 0.74, 0.72)
const CREATOR_SIZE := Vector2(748.0, 452.0)
const PREVIEW_SIZE := Vector2i(246, 126)

var _game_manager: Node
var _draft := CharacterProfile.new()
var _visual: PlayerVisual
var _portrait: PortraitView
var _voice: VoiceBarkPlayer
var _name_edit: LineEdit
var _weapon_description: Label
var _weapon_stats: Label
var _identity_summary: Label
var _name_status: Label
var _preview_animation_label: Label
var _begin_button: Button
var _abandon_dialog: ConfirmationDialog
var _first_focus: Control
var _creator_scroll: ScrollContainer
var _action_bar: HBoxContainer
var _rng := RandomNumberGenerator.new()
var _option_controls: Dictionary = {}


func _ready() -> void:
	_game_manager = get_node("/root/GameManager")
	_rng.randomize()
	_build_background()
	_build_interface()
	_refresh_preview()
	_first_focus.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_abandon_dialog.popup_centered()
		get_viewport().set_input_as_handled()


func _build_background() -> void:
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = load("res://assets/runtime/environments/parallax/Neon Alley/Assets/layers/back.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.25, 0.42, 0.7)
	add_child(background)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.02, 0.08, 0.82)
	add_child(shade)


func _build_interface() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = CREATOR_SIZE
	frame.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.028, 0.068, 0.97), Color(0.18, 0.68, 0.86, 0.8)))
	center.add_child(frame)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	frame.add_child(margin)
	var root_box := VBoxContainer.new()
	root_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_theme_constant_override("separation", 6)
	margin.add_child(root_box)
	var masthead := HBoxContainer.new()
	masthead.custom_minimum_size.y = 32.0
	root_box.add_child(masthead)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override("separation", -2)
	masthead.add_child(title_stack)
	var title := Label.new()
	title.text = "CREATE RUNNER"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", CYAN)
	title_stack.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "IDENTITY  /  APPEARANCE  /  LOADOUT"
	subtitle.add_theme_font_size_override("font_size", 9)
	subtitle.add_theme_color_override("font_color", Color(0.58, 0.73, 0.87))
	title_stack.add_child(subtitle)
	var step_label := Label.new()
	step_label.text = "NEW OPERATIVE"
	step_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	step_label.add_theme_font_size_override("font_size", 10)
	step_label.add_theme_color_override("font_color", MAGENTA)
	masthead.add_child(step_label)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 9)
	root_box.add_child(columns)
	var creator_panel := PanelContainer.new()
	creator_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	creator_panel.size_flags_stretch_ratio = 1.3
	creator_panel.add_theme_stylebox_override("panel", _panel_style(PANEL_FILL, PANEL_BORDER))
	columns.add_child(creator_panel)
	_creator_scroll = ScrollContainer.new()
	_creator_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_creator_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_creator_scroll.follow_focus = true
	_creator_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var field_margin := MarginContainer.new()
	field_margin.add_theme_constant_override("margin_left", 9)
	field_margin.add_theme_constant_override("margin_right", 9)
	field_margin.add_theme_constant_override("margin_top", 7)
	field_margin.add_theme_constant_override("margin_bottom", 7)
	creator_panel.add_child(field_margin)
	field_margin.add_child(_creator_scroll)
	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("separation", 3)
	_creator_scroll.add_child(fields)
	_add_section_header(fields, "01  IDENTITY", "Name, pronouns, voice and comms portrait")
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Runner name"
	_name_edit.max_length = 24
	_name_edit.text = _draft.character_name
	_name_edit.text_changed.connect(func(value: String) -> void:
		_draft.character_name = value
		_refresh_preview()
	)
	_add_labeled_control(fields, "NAME", _name_edit)
	_name_status = Label.new()
	_name_status.add_theme_font_size_override("font_size", 11)
	_name_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fields.add_child(_name_status)
	_first_focus = _name_edit
	_add_pronoun_option(fields)
	_add_voice_option(fields)
	_add_portrait_option(fields)
	_add_section_header(fields, "02  APPEARANCE", "Layered body, face, hair and armor treatment")
	_add_catalog_option(fields, "BODY / FRAME", "body", "body_id")
	_add_catalog_option(fields, "SKIN TONE", "skin_tone", "skin_tone_id")
	_add_catalog_option(fields, "FACE", "face", "face_id")
	_add_catalog_option(fields, "HAIRSTYLE", "hair_style", "hair_style_id")
	_add_catalog_option(fields, "HAIR COLOR", "hair_color", "hair_color_id")
	_add_catalog_option(fields, "TOP", "top", "top_id")
	_add_catalog_option(fields, "TOP COLOR", "clothing_color", "top_color_id")
	_add_catalog_option(fields, "BOTTOM", "bottom", "bottom_id")
	_add_catalog_option(fields, "BOTTOM COLOR", "clothing_color", "bottom_color_id")
	_add_section_header(fields, "03  LOADOUT", "Starting weapon changes reach, timing and technique")
	_add_weapon_option(fields)
	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size.x = 264.0
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.04, 0.095, 0.96), Color(0.68, 0.25, 0.65, 0.7)))
	columns.add_child(preview_panel)
	var preview_box := VBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 3)
	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 8)
	preview_margin.add_theme_constant_override("margin_right", 8)
	preview_margin.add_theme_constant_override("margin_top", 6)
	preview_margin.add_theme_constant_override("margin_bottom", 6)
	preview_panel.add_child(preview_margin)
	preview_margin.add_child(preview_box)
	var preview_heading := Label.new()
	preview_heading.text = "LIVE FIELD PREVIEW"
	preview_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_heading.add_theme_font_size_override("font_size", 12)
	preview_heading.add_theme_color_override("font_color", MAGENTA)
	preview_box.add_child(preview_heading)
	var viewport_container := SubViewportContainer.new()
	viewport_container.custom_minimum_size = Vector2(PREVIEW_SIZE)
	viewport_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	viewport_container.stretch = true
	preview_box.add_child(viewport_container)
	var preview_viewport := SubViewport.new()
	preview_viewport.size = PREVIEW_SIZE
	preview_viewport.transparent_bg = false
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(preview_viewport)
	var preview_background := ColorRect.new()
	preview_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_background.color = Color("0b1730")
	preview_viewport.add_child(preview_background)
	var grid := _PreviewGrid.new()
	grid.preview_size = Vector2(PREVIEW_SIZE)
	preview_viewport.add_child(grid)
	_visual = PLAYER_VISUAL_SCENE.instantiate() as PlayerVisual
	_visual.position = Vector2(PREVIEW_SIZE.x * 0.5, 84.0)
	_visual.scale = Vector2(2.45, 2.45)
	preview_viewport.add_child(_visual)
	var motion_selector := OptionButton.new()
	motion_selector.tooltip_text = "Preview character animation"
	for entry: Array in [["IDLE", &"idle"], ["RUN", &"run"], ["JUMP", &"jump"], ["ATTACK", &"attack_1"], ["HURT", &"hurt"], ["PHASE", &"cast_2"]]:
		motion_selector.add_item("PREVIEW: %s" % String(entry[0]))
		motion_selector.set_item_metadata(motion_selector.item_count - 1, entry[1])
	motion_selector.item_selected.connect(func(index: int) -> void:
		var animation_name := StringName(motion_selector.get_item_metadata(index))
		_visual.play_animation(animation_name, true)
		_preview_animation_label.text = "%s MOTION" % motion_selector.get_item_text(index).trim_prefix("PREVIEW: ")
	)
	preview_box.add_child(motion_selector)
	_preview_animation_label = Label.new()
	_preview_animation_label.text = "IDLE MOTION"
	_preview_animation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_animation_label.add_theme_font_size_override("font_size", 9)
	_preview_animation_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.9))
	preview_box.add_child(_preview_animation_label)
	_weapon_description = Label.new()
	_weapon_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_weapon_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_weapon_description.custom_minimum_size.y = 24.0
	_weapon_description.add_theme_font_size_override("font_size", 10)
	preview_box.add_child(_weapon_description)
	_weapon_stats = Label.new()
	_weapon_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_weapon_stats.add_theme_font_size_override("font_size", 9)
	_weapon_stats.add_theme_color_override("font_color", Color("ffd66b"))
	preview_box.add_child(_weapon_stats)
	var portrait_row := HBoxContainer.new()
	portrait_row.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_box.add_child(portrait_row)
	_portrait = PortraitView.new()
	_portrait.custom_minimum_size = Vector2(92.0, 92.0)
	_portrait.show_weapon = false
	portrait_row.add_child(_portrait)
	_identity_summary = Label.new()
	_identity_summary.custom_minimum_size.x = 142.0
	_identity_summary.add_theme_font_size_override("font_size", 10)
	_identity_summary.modulate = Color(0.72, 0.84, 0.96)
	portrait_row.add_child(_identity_summary)
	_action_bar = HBoxContainer.new()
	_action_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_action_bar.add_theme_constant_override("separation", 7)
	root_box.add_child(_action_bar)
	_add_action_button(_action_bar, "RANDOMIZE", _randomize_all)
	_add_action_button(_action_bar, "BACK", func() -> void: _abandon_dialog.popup_centered())
	_begin_button = _add_action_button(_action_bar, "LOCK IN & DEPLOY", _confirm_character)
	_begin_button.add_theme_color_override("font_color", CYAN)
	_voice = VoiceBarkPlayer.new()
	add_child(_voice)
	_abandon_dialog = ConfirmationDialog.new()
	_abandon_dialog.title = "Abandon Character?"
	_abandon_dialog.dialog_text = "Return to the title without saving this character?"
	_abandon_dialog.confirmed.connect(func() -> void: _game_manager.call(&"return_to_title"))
	add_child(_abandon_dialog)


func _add_pronoun_option(parent: Control) -> void:
	var option := OptionButton.new()
	for entry: Array in [["They / Them", &"they_them"], ["She / Her", &"she_her"], ["He / Him", &"he_him"]]:
		option.add_item(String(entry[0]))
		option.set_item_metadata(option.item_count - 1, entry[1])
		if entry[1] == _draft.pronoun_set_id:
			option.select(option.item_count - 1)
	option.item_selected.connect(func(index: int) -> void:
		_draft.pronoun_set_id = StringName(option.get_item_metadata(index))
		_refresh_preview()
	)
	_option_controls[&"pronoun_set_id"] = option
	_add_labeled_control(parent, "PRONOUNS", option)


func _add_voice_option(parent: Control) -> void:
	var row := VBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = "VOICE PROFILE"
	row.add_child(label)
	var selection := HBoxContainer.new()
	row.add_child(selection)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entry: Dictionary in CreatorCatalog.voices():
		option.add_item(String(entry.display_name))
		option.set_item_metadata(option.item_count - 1, String(entry.id))
		if String(entry.id) == _draft.voice_profile_id:
			option.select(option.item_count - 1)
	option.item_selected.connect(func(index: int) -> void:
		_draft.voice_profile_id = String(option.get_item_metadata(index))
		_voice.set_voice_profile(_draft.voice_profile_id)
	)
	_option_controls[&"voice_profile_id"] = option
	selection.add_child(option)
	for entry: Array in [["HI", &"greeting"], ["ATK", &"grunting"], ["HIT", &"damage"], ["OK", &"confirmation"]]:
		var preview := Button.new()
		preview.text = String(entry[0])
		preview.custom_minimum_size.x = 38.0
		preview.add_theme_font_size_override("font_size", 9)
		preview.pressed.connect(func() -> void:
			_voice.set_voice_profile(_draft.voice_profile_id)
			_voice.play_bark(entry[1], true)
		)
		selection.add_child(preview)


func _add_catalog_option(parent: Control, label_text: String, category: String, property_name: StringName) -> void:
	var option := OptionButton.new()
	option.tooltip_text = "Choose %s" % label_text.to_lower()
	var current := String(_draft.appearance.get(property_name))
	for entry: Dictionary in CreatorCatalog.options(category):
		option.add_item(String(entry.display_name))
		var index := option.item_count - 1
		option.set_item_metadata(index, String(entry.id))
		if String(entry.id) == current:
			option.select(index)
	option.item_selected.connect(func(index: int) -> void:
		_draft.appearance.set(property_name, String(option.get_item_metadata(index)))
		_refresh_preview()
	)
	_option_controls[property_name] = option
	_add_labeled_control(parent, label_text, _selector_with_arrows(option))


func _add_weapon_option(parent: Control) -> void:
	var option := OptionButton.new()
	for family: StringName in CharacterProfile.WEAPON_FAMILIES:
		var definition := WeaponCatalog.family(family)
		option.add_item(String(definition.get("display_name", String(family).capitalize())))
		option.set_item_metadata(option.item_count - 1, family)
	option.item_selected.connect(func(index: int) -> void:
		_draft.starting_weapon_family = StringName(option.get_item_metadata(index))
		_refresh_preview()
	)
	_option_controls[&"starting_weapon_family"] = option
	_add_labeled_control(parent, "STARTING WEAPON", _selector_with_arrows(option))


func _add_portrait_option(parent: Control) -> void:
	var option := OptionButton.new()
	for entry: Dictionary in CreatorCatalog.portraits():
		option.add_item(String(entry.display_name))
		var index := option.item_count - 1
		option.set_item_metadata(index, String(entry.id))
		option.set_item_tooltip(index, "JRPG archetype: %s" % String(entry.get("archetype", "Runner")))
	option.item_selected.connect(func(index: int) -> void:
		_draft.portrait_id = String(option.get_item_metadata(index))
		_refresh_preview()
	)
	_option_controls[&"portrait_id"] = option
	_add_labeled_control(parent, "PORTRAIT", _selector_with_arrows(option))


func _selector_with_arrows(option: OptionButton) -> HBoxContainer:
	var selector := HBoxContainer.new()
	selector.add_theme_constant_override("separation", 4)
	var previous := Button.new()
	previous.text = "‹"
	previous.custom_minimum_size.x = 32.0
	previous.tooltip_text = "Previous option"
	previous.pressed.connect(func() -> void: _cycle_option(option, -1))
	selector.add_child(previous)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.add_child(option)
	var next := Button.new()
	next.text = "›"
	next.custom_minimum_size.x = 32.0
	next.tooltip_text = "Next option"
	next.pressed.connect(func() -> void: _cycle_option(option, 1))
	selector.add_child(next)
	return selector


func _cycle_option(option: OptionButton, direction: int) -> void:
	if option.item_count <= 1:
		return
	var next_index := posmod(option.selected + direction, option.item_count)
	option.select(next_index)
	option.item_selected.emit(next_index)


func _add_section_header(parent: Control, title: String, subtitle: String) -> void:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", -1)
	parent.add_child(section)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", CYAN)
	section.add_child(heading)
	var hint := Label.new()
	hint.text = subtitle
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color(0.48, 0.65, 0.78))
	section.add_child(hint)
	var separator := HSeparator.new()
	separator.modulate = Color(0.25, 0.75, 0.92, 0.4)
	section.add_child(separator)


func _add_labeled_control(parent: Control, label_text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 108.0
	label.add_theme_font_size_override("font_size", 10)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 6
	return style


func _add_action_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(132.0, 32.0)
	button.add_theme_font_size_override("font_size", 10)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _refresh_preview() -> void:
	if _name_edit != null:
		_draft.character_name = _name_edit.text
	_draft.sanitize()
	if _visual != null:
		_visual.apply_profile(_draft)
	if _portrait != null:
		_portrait.apply_profile(_draft)
	if _weapon_description != null:
		_weapon_description.text = String(WEAPON_DESCRIPTIONS.get(String(_draft.starting_weapon_family), ""))
	if _weapon_stats != null:
		var family := WeaponCatalog.family(_draft.starting_weapon_family)
		var opening := WeaponCatalog.attack_profile(_draft.starting_weapon_family, false, 1)
		var technique := WeaponCatalog.technique_profile(_draft.starting_weapon_family)
		_weapon_stats.text = "DMG %d   •   START %.2fs   •   TECH %d EN" % [
			int(family.get("base_damage", 1)),
			float(opening.get("startup", 0.0)),
			int(round(float(technique.get("cost", 0.0)))),
		]
	if _identity_summary != null:
		var pronouns := {&"they_them":"THEY / THEM", &"she_her":"SHE / HER", &"he_him":"HE / HIM"}
		var portrait := CreatorCatalog.portrait(_draft.portrait_id)
		_identity_summary.text = "%s\n%s  •  %s\n%s\n%s" % [
			_draft.character_name.to_upper(),
			String(pronouns.get(_draft.pronoun_set_id, "THEY / THEM")),
			String(portrait.get("display_name", "Vanguard")).to_upper(),
			String(portrait.get("archetype", "Vanguard Hero")).to_upper(),
			String(WeaponCatalog.family(_draft.starting_weapon_family).get("display_name", "Phase Edge")).to_upper(),
		]
	if _name_status != null and _name_edit != null:
		var raw_name := _name_edit.text.strip_edges()
		_name_status.text = "ENTER A CALLSIGN TO DEPLOY" if raw_name.is_empty() else "%d / 24  •  PROFILE READY" % raw_name.length()
		_name_status.add_theme_color_override("font_color", MAGENTA if raw_name.is_empty() else Color("72e6a1"))
		if _begin_button != null:
			_begin_button.disabled = raw_name.is_empty()


func _randomize_all() -> void:
	for category_property: Array in [["body", &"body_id"], ["skin_tone", &"skin_tone_id"], ["face", &"face_id"], ["hair_style", &"hair_style_id"], ["hair_color", &"hair_color_id"], ["top", &"top_id"], ["clothing_color", &"top_color_id"], ["bottom", &"bottom_id"], ["clothing_color", &"bottom_color_id"]]:
		var choices := CreatorCatalog.options(String(category_property[0]))
		if not choices.is_empty():
			_draft.appearance.set(category_property[1], String((choices[_rng.randi_range(0, choices.size() - 1)] as Dictionary).id))
	var portraits := CreatorCatalog.portraits()
	_draft.portrait_id = String((portraits[_rng.randi_range(0, portraits.size() - 1)] as Dictionary).id)
	_draft.pronoun_set_id = CharacterProfile.PRONOUN_IDS[_rng.randi_range(0, CharacterProfile.PRONOUN_IDS.size() - 1)]
	var voices := CreatorCatalog.voices()
	if not voices.is_empty():
		_draft.voice_profile_id = String((voices[_rng.randi_range(0, voices.size() - 1)] as Dictionary).id)
	_draft.starting_weapon_family = CharacterProfile.WEAPON_FAMILIES[_rng.randi_range(0, CharacterProfile.WEAPON_FAMILIES.size() - 1)]
	_sync_option_controls()
	_refresh_preview()


func _sync_option_controls() -> void:
	for property_value: Variant in _option_controls:
		var property_name := property_value as StringName
		var option := _option_controls[property_name] as OptionButton
		var wanted := ""
		if property_name == &"starting_weapon_family":
			wanted = String(_draft.starting_weapon_family)
		elif property_name == &"portrait_id":
			wanted = _draft.portrait_id
		elif property_name == &"pronoun_set_id":
			wanted = String(_draft.pronoun_set_id)
		elif property_name == &"voice_profile_id":
			wanted = _draft.voice_profile_id
		else:
			wanted = String(_draft.appearance.get(property_name))
		for index: int in range(option.item_count):
			if String(option.get_item_metadata(index)) == wanted:
				option.select(index)
				break


func _confirm_character() -> void:
	if _name_edit.text.strip_edges().is_empty():
		_name_status.text = "CALLSIGN REQUIRED"
		_name_edit.grab_focus()
		return
	_draft.character_name = _name_edit.text
	_draft.creation_complete = true
	_draft.sanitize()
	if not _draft.is_valid(true):
		_name_edit.grab_focus()
		return
	_game_manager.call(&"start_created_game", _draft)


class _PreviewGrid:
	extends Node2D
	var preview_size := Vector2(246.0, 126.0)

	func _draw() -> void:
		for x: int in range(0, int(preview_size.x) + 1, 18):
			draw_line(Vector2(x, 0), Vector2(x, preview_size.y), Color(0.08, 0.28, 0.42, 0.35), 1.0)
		for y: int in range(0, int(preview_size.y) + 1, 18):
			draw_line(Vector2(0, y), Vector2(preview_size.x, y), Color(0.08, 0.28, 0.42, 0.35), 1.0)
		var floor_y := preview_size.y - 14.0
		draw_line(Vector2(0, floor_y), Vector2(preview_size.x, floor_y), Color("27e8ff"), 2.0)
		draw_circle(Vector2(preview_size.x * 0.5, floor_y), 30.0, Color(0.1, 0.75, 0.95, 0.08))
