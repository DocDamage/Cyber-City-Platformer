extends CanvasLayer

var _health: Label
var _energy: Label
var _corruption: Label
var _location: Label
var _phase: Label
var _objective: Label
var _toast: Label
var _toast_generation := 0


func _ready() -> void:
	layer = 40
	_build()
	var game := get_node_or_null("/root/GameManager")
	if game != null:
		game.player_health_changed.connect(_on_health)
		game.player_energy_changed.connect(_on_energy)
		game.world_progress_changed.connect(_on_room)
		game.story_flag_changed.connect(func(_flag: StringName, _value: Variant) -> void: _refresh_objective())
		game.quest_changed.connect(func(_quest_id: StringName, _state: Dictionary) -> void: _refresh_objective())
		game.inventory_changed.connect(func(item_id: StringName, amount: int) -> void: _show_toast("ACQUIRED  %s  ×%d" % [String(item_id).replace("_", " ").to_upper(), amount]))
		game.locked_barrier_discovered.connect(func(_barrier_id: String, _room_id: String, required_ability: StringName) -> void:
			_show_toast("ROUTE LOCKED  •  REQUIRES %s" % String(required_ability).replace("_", " ").to_upper())
		)
		_on_health(game.player_health, game.player_max_health)
		_on_energy(game.player_energy, game.player_max_energy)
		_on_room(game.world_progress.current_room_id)
		_refresh_objective()
	var world := get_node_or_null("/root/WorldManager")
	if world != null:
		world.transition_completed.connect(func(room_id: String, _spawn: String) -> void: _on_room(room_id))
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null:
		var teleport := player.get_node_or_null("TeleportController") as TeleportController
		if teleport != null:
			teleport.marker_attached.connect(_on_marker_attached)
			teleport.marker_recalled.connect(func() -> void: _phase.text = "PHASE: READY")
			teleport.teleport_completed.connect(func(_destination: Vector2) -> void: _phase.text = "PHASE: READY")
		var voice := player.get_node_or_null("VoiceBarkPlayer") as VoiceBarkPlayer
		if voice != null:
			voice.bark_started.connect(_on_bark_started)
		if player.has_signal(&"corruption_changed"):
			player.corruption_changed.connect(_on_corruption_changed)
			_on_corruption_changed(float(player.get("corruption")), float(player.get("max_corruption")))


func _build() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(14, 14)
	panel.custom_minimum_size = Vector2(260, 92)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_health = Label.new()
	_energy = Label.new()
	_corruption = Label.new()
	_phase = Label.new()
	for label: Label in [_health, _energy, _corruption, _phase]:
		box.add_child(label)
	_location = Label.new()
	_location.position = Vector2(560, 18)
	_location.custom_minimum_size.x = 380
	_location.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_location.add_theme_font_size_override("font_size", 18)
	add_child(_location)
	_objective = Label.new()
	_objective.position = Vector2(14, 112)
	_objective.custom_minimum_size.x = 500
	_objective.add_theme_color_override("font_color", Color("ffe66b"))
	add_child(_objective)
	_toast = Label.new()
	_toast.position = Vector2(250, 458)
	_toast.custom_minimum_size = Vector2(460, 48)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 18)
	_toast.add_theme_color_override("font_color", Color("ffe66b"))
	_toast.visible = false
	add_child(_toast)


func _on_health(current: int, maximum: int) -> void:
	_health.text = "VITALS  %d / %d" % [current, maximum]


func _on_energy(current: float, maximum: float) -> void:
	_energy.text = "ENERGY  %d / %d" % [roundi(current), roundi(maximum)]


func _on_corruption_changed(current: float, maximum: float) -> void:
	var percentage := roundi((current / maxf(maximum, 1.0)) * 100.0)
	_corruption.text = "CORRUPTION  %d%%" % percentage
	_corruption.modulate = Color("ff62bd") if percentage > 0 else Color(0.55, 0.62, 0.72, 0.75)


func _on_room(room_id: String) -> void:
	var definition := WorldDatabase.room(room_id)
	_location.text = String(definition.get("display_name", room_id)).to_upper()


func _on_marker_attached(valid: bool, _destination: Vector2, reason: StringName) -> void:
	_phase.text = "PHASE: LOCKED" if valid else "PHASE: INVALID (%s)" % String(reason).replace("_", " ").to_upper()


func _refresh_objective() -> void:
	var game := get_node_or_null("/root/GameManager")
	if game == null or _objective == null:
		return
	var quest: Dictionary = game.call(&"current_quest_objective")
	_objective.text = "OBJECTIVE  •  %s" % String(quest.get("objective", "Explore the connected world.")).to_upper()


func _on_bark_started(_profile_id: String, category: StringName, _path: String) -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and not bool(settings.call(&"get_setting", &"bark_subtitles", true)):
		return
	var subtitles := {&"damage":"[strained breath]", &"grunting":"[effort]", &"greeting":"[greeting]", &"confirmation":"[affirmative]"}
	_show_toast(String(subtitles.get(category, "[voice bark]")))


func _show_toast(message: String) -> void:
	_toast_generation += 1
	var generation := _toast_generation
	_toast.text = message
	_toast.visible = true
	await get_tree().create_timer(2.2, true, false, true).timeout
	if generation == _toast_generation:
		_toast.visible = false
