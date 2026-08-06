class_name PauseMenu
extends CanvasLayer

const PLAYER_VISUAL_SCENE := preload("res://scenes/Player/PlayerVisual.tscn")
const TAB_NAMES := ["MAP", "EQUIPMENT", "INVENTORY", "ABILITIES", "JOURNAL", "SYSTEM"]

var _panel: ColorRect
var _tabs: TabContainer
var _header: Label
var _map_view: WorldMapView
var _map_help: Label
var _equipment_preview: PlayerVisual
var _equipment_portrait: PortraitView
var _equipment_content: VBoxContainer
var _inventory_text: RichTextLabel
var _abilities_text: RichTextLabel
var _journal_text: RichTextLabel
var _warp_list: VBoxContainer
var _first_focus_by_tab: Dictionary = {}
var _equipment_sort_mode := 0
var _equipment_filter_mode := 0
var _equipment_feedback_text := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	_build_menu()
	_panel.visible = false
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null:
		for signal_name: StringName in [&"input_device_changed", &"action_binding_changed"]:
			var callback := Callable(self, &"_refresh_input_prompts")
			if settings.has_signal(signal_name) and not settings.is_connected(signal_name, callback):
				settings.connect(signal_name, callback)
	_refresh_input_prompts()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_game"):
		if _panel.visible:
			resume()
		else:
			pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"open_map"):
		if _panel.visible and _tabs.current_tab == 0:
			resume()
		else:
			pause(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"open_inventory"):
		if not _panel.visible:
			pause(2)
		else:
			_tabs.current_tab = 2
		get_viewport().set_input_as_handled()


func pause(tab_index := 0) -> void:
	var dialogue := get_node_or_null("/root/DialogueController")
	if dialogue != null and not String(dialogue.get("active_entry_id")).is_empty():
		return
	_panel.visible = true
	get_tree().paused = true
	_tabs.current_tab = clampi(tab_index, 0, TAB_NAMES.size() - 1)
	_refresh_all()
	_focus_current_tab()


func resume() -> void:
	_panel.visible = false
	get_tree().paused = false


func is_open() -> bool:
	return _panel != null and _panel.visible


func _build_menu() -> void:
	_panel = ColorRect.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.color = Color(0.01, 0.015, 0.06, 0.96)
	add_child(_panel)
	var root_box := VBoxContainer.new()
	root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	_panel.add_child(root_box)
	_header = Label.new()
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header.add_theme_font_size_override("font_size", 22)
	_header.add_theme_color_override("font_color", Color("27e8ff"))
	root_box.add_child(_header)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(_tabs)
	_build_map_tab()
	_build_equipment_tab()
	_build_inventory_tab()
	_build_abilities_tab()
	_build_journal_tab()
	_build_system_tab()
	_tabs.tab_changed.connect(func(_index: int) -> void:
		_refresh_all()
		_focus_current_tab()
	)
	for index: int in range(TAB_NAMES.size()):
		_tabs.set_tab_title(index, TAB_NAMES[index])


func _build_map_tab() -> void:
	var tab := HBoxContainer.new()
	tab.name = "Map"
	tab.add_theme_constant_override("separation", 12)
	_tabs.add_child(tab)
	_map_view = WorldMapView.new()
	_map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(_map_view)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 245
	tab.add_child(side)
	var title := Label.new()
	title.text = "ACTIVATED RELAYS"
	title.add_theme_font_size_override("font_size", 17)
	side.add_child(title)
	_warp_list = VBoxContainer.new()
	side.add_child(_warp_list)
	_map_help = Label.new()
	_map_help.modulate = Color(0.65, 0.75, 0.9)
	_map_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_map_help)
	_first_focus_by_tab[0] = _map_view


func _build_equipment_tab() -> void:
	var tab := HBoxContainer.new()
	tab.name = "Equipment"
	_tabs.add_child(tab)
	var preview_box := VBoxContainer.new()
	preview_box.custom_minimum_size.x = 350
	tab.add_child(preview_box)
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(340, 225)
	container.stretch = true
	preview_box.add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(340, 225)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("0b1730")
	viewport.add_child(background)
	_equipment_preview = PLAYER_VISUAL_SCENE.instantiate() as PlayerVisual
	_equipment_preview.position = Vector2(170, 140)
	_equipment_preview.scale = Vector2(3.0, 3.0)
	viewport.add_child(_equipment_preview)
	_equipment_portrait = PortraitView.new()
	_equipment_portrait.custom_minimum_size = Vector2(180, 180)
	preview_box.add_child(_equipment_portrait)
	_equipment_content = VBoxContainer.new()
	_equipment_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.add_child(_equipment_content)


func _build_inventory_tab() -> void:
	_inventory_text = _rich_tab("Inventory")


func _build_abilities_tab() -> void:
	_abilities_text = _rich_tab("Abilities")


func _build_journal_tab() -> void:
	_journal_text = _rich_tab("Journal")


func _rich_tab(tab_name: String) -> RichTextLabel:
	var text_view := RichTextLabel.new()
	text_view.name = tab_name
	text_view.bbcode_enabled = true
	text_view.scroll_active = true
	text_view.focus_mode = Control.FOCUS_ALL
	text_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	text_view.add_theme_font_size_override("normal_font_size", 17)
	_tabs.add_child(text_view)
	var index := _tabs.get_tab_count() - 1
	_first_focus_by_tab[index] = text_view
	return text_view


func _build_system_tab() -> void:
	var tab := CenterContainer.new()
	tab.name = "System"
	_tabs.add_child(tab)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 390
	tab.add_child(box)
	var resume_button := _add_button(box, "ResumeButton", "RESUME", resume)
	_add_button(box, "CheckpointButton", "RESTART FROM LAST SAVE", _restart_checkpoint)
	_add_button(box, "SettingsButton", "SETTINGS & ACCESSIBILITY", _open_settings)
	_add_button(box, "TitleButton", "SAVE & RETURN TO TITLE", _return_to_title)
	_first_focus_by_tab[5] = resume_button


func _refresh_all() -> void:
	var game := get_node_or_null("/root/GameManager")
	if game == null:
		return
	var room := WorldDatabase.room(game.world_progress.current_room_id)
	_header.text = "%s  •  %s  •  MAP %d%%" % [game.character_profile.character_name.to_upper(), String(room.get("display_name", game.world_progress.current_room_id)).to_upper(), roundi(game.world_progress.map_completion(WorldDatabase.room_count()) * 100.0)]
	_map_view.queue_redraw()
	_refresh_warp_list(game)
	_refresh_equipment(game)
	_refresh_inventory(game)
	_refresh_abilities(game)
	_refresh_journal(game)


func _refresh_warp_list(game: Node) -> void:
	for child: Node in _warp_list.get_children():
		child.queue_free()
	var world := get_node_or_null("/root/WorldManager")
	for value: Variant in WorldDatabase.fast_travel_nodes():
		var node := value as Dictionary
		var node_id := String(node.get("id", ""))
		if not game.world_progress.activated_warp_nodes.has(node_id):
			continue
		var button := Button.new()
		var destination_available := WorldDatabase.fast_travel_node_available(node_id, game.story_flags)
		button.text = String(node.get("display_name", node_id)) + ("  •  STORY LOCKED" if not destination_available else "")
		button.disabled = world == null or not bool(world.call(&"can_fast_travel_to", node_id)) or String(node.get("room_id", "")) == game.world_progress.current_room_id
		button.pressed.connect(_travel_to_warp.bind(node_id))
		_warp_list.add_child(button)
	if _warp_list.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "No phase relays activated."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_warp_list.add_child(empty)


func _refresh_equipment(game: Node) -> void:
	if _equipment_preview != null:
		_equipment_preview.apply_profile(game.character_profile)
	if _equipment_portrait != null:
		_equipment_portrait.apply_profile(game.character_profile)
	for child: Node in _equipment_content.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "EQUIPPED: %s" % game.equipment.main_weapon_id.replace("_", " ").to_upper()
	title.add_theme_font_size_override("font_size", 21)
	_equipment_content.add_child(title)
	var definition := WeaponCatalog.family(game.equipment.weapon_family_id)
	var technique := WeaponCatalog.technique_profile(game.equipment.weapon_family_id)
	var summary := Label.new()
	summary.text = "%s\nBase damage: %d  •  Technique: %s (%d energy)\n%s\n%s" % [String(definition.get("display_name", String(game.equipment.weapon_family_id).capitalize())), int(definition.get("base_damage", 1)), String(technique.get("id", "technique")).replace("_", " ").capitalize(), roundi(float(technique.get("cost", 0.0))), String(definition.get("role", "")), _move_summary(game.equipment.weapon_family_id)]
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_equipment_content.add_child(summary)
	var slots := Label.new()
	slots.text = "MODULE SLOTS\nBody: %s\nAccessory A: %s\nAccessory B: %s\nEmpty slots require a compatible module before they can be equipped." % [_slot_name(game.equipment.body_module_id), _slot_name(game.equipment.accessory_ids[0]), _slot_name(game.equipment.accessory_ids[1])]
	slots.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slots.modulate = Color("a9b9d6")
	_equipment_content.add_child(slots)
	var label := Label.new()
	label.text = "WEAPON ARMORY"
	label.add_theme_font_size_override("font_size", 17)
	_equipment_content.add_child(label)
	var selectors := HBoxContainer.new()
	var sort_selector := OptionButton.new()
	for sort_label: String in ["SORT: NAME", "SORT: DAMAGE", "SORT: SPEED"]:
		sort_selector.add_item(sort_label)
	sort_selector.select(_equipment_sort_mode)
	sort_selector.item_selected.connect(_set_equipment_sort.bind(game))
	selectors.add_child(sort_selector)
	var filter_selector := OptionButton.new()
	for filter_label: String in ["FILTER: OWNED", "FILTER: ALL", "FILTER: MELEE", "FILTER: RANGED"]:
		filter_selector.add_item(filter_label)
	filter_selector.select(_equipment_filter_mode)
	filter_selector.item_selected.connect(_set_equipment_filter.bind(game))
	selectors.add_child(filter_selector)
	_equipment_content.add_child(selectors)
	_first_focus_by_tab[1] = sort_selector
	var weapon_ids := _filtered_weapon_ids(game)
	for weapon_id: String in weapon_ids:
		var item := WeaponCatalog.weapon(StringName(weapon_id))
		var family_key := String(item.get("family", ""))
		var owned: bool = game.inventory.has_item(StringName(weapon_id))
		var button := Button.new()
		button.text = "%s  —  %s%s" % [family_key.to_upper(), String(item.get("display_name", weapon_id.replace("_", " ").capitalize())), "  [LOCKED]" if not owned else ""]
		button.icon = WeaponCatalog.icon(StringName(weapon_id), owned)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", WeaponCatalog.ICON_RUNTIME_SIZE)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 38.0
		button.disabled = not owned or weapon_id == game.equipment.main_weapon_id
		button.focus_entered.connect(_preview_weapon.bind(game, weapon_id))
		button.mouse_entered.connect(_preview_weapon.bind(game, weapon_id))
		button.pressed.connect(_equip_weapon.bind(game, weapon_id))
		_equipment_content.add_child(button)
	var comparison := Label.new()
	comparison.name = "WeaponComparison"
	comparison.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comparison.text = _weapon_comparison(game.equipment.weapon_family_id, game.equipment.weapon_family_id)
	_equipment_content.add_child(comparison)
	var feedback := Label.new()
	feedback.name = "EquipmentFeedback"
	feedback.text = _equipment_feedback_text
	feedback.modulate = Color("65ffb8")
	_equipment_content.add_child(feedback)


func _refresh_inventory(game: Node) -> void:
	var lines := PackedStringArray(["[font_size=24][color=#27e8ff]INVENTORY[/color][/font_size]", "Currency: %d" % game.inventory.currency, "[color=#8292b3]Inventory actions are view-only while paused; equipment changes belong in the Equipment tab.[/color]"])
	var unique_ids := PackedStringArray(game.inventory.unique_items.keys())
	unique_ids.sort()
	var weapon_ids := PackedStringArray()
	var key_item_ids := PackedStringArray()
	for item_id: String in unique_ids:
		if WeaponCatalog.weapon(StringName(item_id)).is_empty():
			key_item_ids.append(item_id)
		else:
			weapon_ids.append(item_id)
	lines.append("\n[b]WEAPONS[/b]")
	if weapon_ids.is_empty():
		lines.append("  None")
	for item_id: String in weapon_ids:
		var item := WeaponCatalog.weapon(StringName(item_id))
		var status := "  [EQUIPPED]" if item_id == game.equipment.main_weapon_id else ""
		var display_name := String(item.get("display_name", item_id.replace("_", " ").capitalize()))
		var category := "%s • %s" % [String(item.get("category", "weapon")).to_upper(), String(item.get("family", "")).to_upper()]
		var icon_path := WeaponCatalog.icon_path(StringName(item_id))
		lines.append("\n[img=%dx%d]%s[/img]  [b]%s[/b]%s  [color=#8292b3]%s[/color]" % [WeaponCatalog.ICON_RUNTIME_SIZE, WeaponCatalog.ICON_RUNTIME_SIZE, icon_path, display_name, status, category])
		lines.append("  %s" % String(item.get("description", "A unique progression item.")))
		lines.append("  [i][color=#8fa6ca]%s[/color][/i]" % String(item.get("lore", "Its purpose is recorded in the Journal.")))
	lines.append("\n[b]KEY ITEMS[/b]")
	if key_item_ids.is_empty():
		lines.append("  None")
	for item_id: String in key_item_ids:
		lines.append("[img=%dx%d]%s[/img]  [b]%s[/b]  [color=#8292b3]KEY ITEM[/color]" % [WeaponCatalog.ICON_RUNTIME_SIZE, WeaponCatalog.ICON_RUNTIME_SIZE, WeaponCatalog.UNKNOWN_ICON_PATH, item_id.replace("_", " ").capitalize()])
		lines.append("  A unique progression item. Its purpose is recorded in the Journal.")
	lines.append("\n[b]MATERIALS[/b]")
	if game.inventory.stacks.is_empty():
		lines.append("  None")
	var stack_ids := PackedStringArray(game.inventory.stacks.keys())
	stack_ids.sort()
	for item_id: String in stack_ids:
		lines.append("[img=%dx%d]%s[/img]  %s  ×%d" % [WeaponCatalog.ICON_RUNTIME_SIZE, WeaponCatalog.ICON_RUNTIME_SIZE, WeaponCatalog.icon_path(StringName(item_id)), item_id.replace("_", " ").capitalize(), int(game.inventory.stacks[item_id])])
	_inventory_text.text = "\n".join(lines)


func _set_equipment_sort(index: int, game: Node) -> void:
	_equipment_sort_mode = clampi(index, 0, 2)
	_refresh_equipment(game)
	_focus_current_tab()


func _set_equipment_filter(index: int, game: Node) -> void:
	_equipment_filter_mode = clampi(index, 0, 3)
	_refresh_equipment(game)
	_focus_current_tab()


func _filtered_weapon_ids(game: Node) -> Array[String]:
	var result: Array[String] = []
	var definitions := WeaponCatalog.weapons()
	for weapon_id: String in definitions:
		var item := definitions[weapon_id] as Dictionary
		var owned: bool = game.inventory.has_item(StringName(weapon_id))
		var category := String(item.get("category", ""))
		if _equipment_filter_mode == 0 and not owned:
			continue
		if _equipment_filter_mode == 2 and category != "melee":
			continue
		if _equipment_filter_mode == 3 and category != "ranged":
			continue
		result.append(weapon_id)
	result.sort_custom(func(left: String, right: String) -> bool:
		var left_item := WeaponCatalog.weapon(StringName(left))
		var right_item := WeaponCatalog.weapon(StringName(right))
		var left_family := StringName(left_item.get("family", "sword"))
		var right_family := StringName(right_item.get("family", "sword"))
		if _equipment_sort_mode == 1:
			var left_damage := int(WeaponCatalog.family(left_family).get("base_damage", 0))
			var right_damage := int(WeaponCatalog.family(right_family).get("base_damage", 0))
			if left_damage != right_damage:
				return left_damage > right_damage
		elif _equipment_sort_mode == 2:
			var left_speed := float(_family_stats(left_family).get("speed", 0.0))
			var right_speed := float(_family_stats(right_family).get("speed", 0.0))
			if not is_equal_approx(left_speed, right_speed):
				return left_speed > right_speed
		return String(left_item.get("display_name", left)) < String(right_item.get("display_name", right))
	)
	return result


func _preview_weapon(game: Node, weapon_id: String) -> void:
	var comparison := _equipment_content.get_node_or_null("WeaponComparison") as Label
	if comparison == null:
		return
	var item := WeaponCatalog.weapon(StringName(weapon_id))
	var target_family := StringName(item.get("family", game.equipment.weapon_family_id))
	comparison.text = "[PREVIEW] %s\n%s\n%s\n%s" % [String(item.get("display_name", weapon_id)), String(item.get("description", "")), String(item.get("lore", "")), _weapon_comparison(game.equipment.weapon_family_id, target_family)]


func _equip_weapon(game: Node, weapon_id: String) -> void:
	var item := WeaponCatalog.weapon(StringName(weapon_id))
	var family_id := StringName(item.get("family", ""))
	if family_id.is_empty() or not bool(game.call(&"equip_main_weapon", weapon_id, family_id)):
		_equipment_feedback_text = "EQUIP FAILED — ITEM IS NOT AVAILABLE."
	else:
		_equipment_feedback_text = "EQUIPPED %s — LIVE PREVIEW AND MOVE SET UPDATED." % String(item.get("display_name", weapon_id)).to_upper()
		var audio := get_node_or_null("/root/AudioManager")
		if audio != null:
			audio.call(&"play_sfx", &"ui_confirm")
	_refresh_all()


func _family_stats(family_id: StringName) -> Dictionary:
	var definition := WeaponCatalog.family(family_id)
	var combo := definition.get("ground_combo", []) as Array
	var cycle_total := 0.0
	var reach := 0.0
	for attack_value: Variant in combo:
		var attack := attack_value as Dictionary
		cycle_total += float(attack.get("startup", 0.0)) + float(attack.get("active", 0.0)) + float(attack.get("recovery", 0.0))
		var hitbox := attack.get("hitbox", []) as Array
		if hitbox.size() == 2:
			reach = maxf(reach, float(hitbox[0]))
	var average_cycle := cycle_total / maxf(float(combo.size()), 1.0)
	return {
		"damage": int(definition.get("base_damage", 0)),
		"speed": 1.0 / maxf(average_cycle, 0.01),
		"reach": reach,
		"energy": float(WeaponCatalog.technique_profile(family_id).get("cost", 0.0)),
	}


func _weapon_comparison(current_family: StringName, target_family: StringName) -> String:
	var current := _family_stats(current_family)
	var target := _family_stats(target_family)
	return "LIVE → PREVIEW  •  Damage %d → %d  •  Speed %.2f → %.2f attacks/s  •  Reach %.0f → %.0f px  •  Energy %.0f → %.0f" % [int(current.damage), int(target.damage), float(current.speed), float(target.speed), float(current.reach), float(target.reach), float(current.energy), float(target.energy)]


func _move_summary(family_id: StringName) -> String:
	var definition := WeaponCatalog.family(family_id)
	var combo := definition.get("ground_combo", []) as Array
	var air := definition.get("air_attack", {}) as Dictionary
	var technique := definition.get("technique", {}) as Dictionary
	return "Moves: %d-hit ground chain • air strike %.2fs active • %s technique" % [combo.size(), float(air.get("active", 0.0)), String(technique.get("id", "technique")).replace("_", " ").capitalize()]


func _slot_name(item_id: String) -> String:
	return "EMPTY — NO COMPATIBLE MODULE RECOVERED" if item_id.is_empty() else item_id.replace("_", " ").to_upper()


func _refresh_abilities(game: Node) -> void:
	var lines := PackedStringArray(["[font_size=24][color=#27e8ff]ABILITIES[/color][/font_size]", "", "[b]PHASE MARKER[/b]  —  UNIVERSAL", "Throw a marker, then phase to its validated destination. This is distinct from relay fast travel.", "Hold %s to aim • release to throw • press again to phase • %s to recall" % [_input_prompt(&"teleport"), _input_prompt(&"teleport_cancel")], ""])
	if game.abilities.levels.is_empty():
		lines.append("No additional traversal modules acquired.")
	for ability_id: String in game.abilities.levels:
		lines.append("[b]%s[/b]  LV.%d" % [ability_id.replace("_", " ").to_upper(), int(game.abilities.levels[ability_id])])
	_abilities_text.text = "\n".join(lines)


func _refresh_input_prompts(_unused: Variant = null) -> void:
	if _map_help != null:
		var settings := get_node_or_null("/root/SettingsManager")
		var family := StringName(settings.call(&"get_active_input_family")) if settings != null else &"keyboard_mouse"
		_map_help.text = ("D-pad: pan\n%s / %s: zoom\n%s: close" % [_input_prompt(&"teleport_cancel"), _input_prompt(&"teleport"), _input_prompt(&"open_map")] if family == &"controller" else "Drag / arrows: pan\nMouse wheel: zoom\n%s: close" % _input_prompt(&"open_map"))
	if _panel != null and _panel.visible:
		var game := get_node_or_null("/root/GameManager")
		if game != null:
			_refresh_abilities(game)


func _input_prompt(action: StringName) -> String:
	var settings := get_node_or_null("/root/SettingsManager")
	return String(settings.call(&"get_action_prompt", action)) if settings != null else "UNBOUND"


func _refresh_journal(game: Node) -> void:
	var lines := PackedStringArray(["[font_size=24][color=#27e8ff]JOURNAL[/color][/font_size]", "", "[b]QUESTS[/b]"])
	var quests: Array = game.call(&"quest_journal_entries")
	for quest_value: Variant in quests:
		var quest := quest_value as Dictionary
		var status := String(quest.get("status", "active")).to_upper()
		var progress := "%d/%d" % [int(quest.get("progress", 0)), int(quest.get("total", 0))]
		lines.append("\n[b]%s[/b]  •  %s  •  %s" % [String(quest.get("title", "Quest")).to_upper(), status, progress])
		lines.append(String(quest.get("objective", "")))
	lines.append("\n[b]DISCOVERED RECORDS[/b]")
	var records := PackedStringArray()
	if game.has_story_flag(&"prologue_complete"):
		records.append("• Phase Relay Protocol")
	if game.has_story_flag(&"factory_purpose_revealed"):
		records.append("• Assembly Purpose Archive")
	if game.has_story_flag(&"oracle_origin_revealed"):
		records.append("• Oracle Timeline Record")
	if game.has_story_flag(&"nest_evidence_found"):
		records.append("• Convergence Growth Rings")
	lines.append("\n".join(records) if not records.is_empty() else "No records discovered.")
	lines.append("\n[b]CONVERSATION HISTORY[/b]")
	var dialogue := get_node_or_null("/root/DialogueController")
	if dialogue != null:
		var history: Array = dialogue.call(&"resolved_history")
		for index: int in range(maxi(history.size() - 8, 0), history.size()):
			var item: Dictionary = history[index]
			lines.append("%s: %s" % [item.speaker, item.text])
	_journal_text.text = "\n".join(lines)


func _focus_current_tab() -> void:
	var control := _first_focus_by_tab.get(_tabs.current_tab) as Control
	if control != null:
		control.grab_focus.call_deferred()


func _add_button(parent: Control, node_name: String, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size.y = 44
	button.pressed.connect(func() -> void:
		var audio := get_node_or_null("/root/AudioManager")
		if audio != null:
			audio.call(&"play_sfx", &"ui_confirm")
		callback.call()
	)
	parent.add_child(button)
	return button


func _travel_to_warp(node_id: String) -> void:
	var world := get_node_or_null("/root/WorldManager")
	if world == null:
		return
	resume()
	await world.call(&"fast_travel", node_id)


func _restart_checkpoint() -> void:
	resume()
	var game := get_node_or_null("/root/GameManager")
	var world := get_node_or_null("/root/WorldManager")
	if game != null and world != null and not game.world_progress.last_safe_save_room_id.is_empty():
		var save := get_node_or_null("/root/SaveManager")
		if save != null and save.call(&"load_game", false):
			get_tree().reload_current_scene()
			return
	var stage := get_tree().current_scene as StageBase
	if stage != null and stage.runtime_controller != null:
		stage.runtime_controller.restart_checkpoint()


func _return_to_title() -> void:
	var save := get_node_or_null("/root/SaveManager")
	if save != null:
		save.call(&"save_game")
	resume()
	get_node("/root/GameManager").call(&"return_to_title")


func _open_settings() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(center)
	var settings := SettingsPanel.new()
	settings.closed.connect(func() -> void:
		center.queue_free()
		_focus_current_tab()
	)
	center.add_child(settings)
