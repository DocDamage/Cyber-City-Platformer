class_name DialogueNPC
extends Area2D

var npc_id := ""
var display_name := "NPC"
var dialogue_entries: Array[String] = []
var _nearby_player: Node2D
var _prompt: Label


func configure(data: Dictionary) -> void:
	npc_id = String(data.get("id", "npc"))
	display_name = String(data.get("display_name", npc_id.capitalize()))
	for value: Variant in data.get("dialogue_entries", []):
		dialogue_entries.append(String(value))
	var values: Array = data.get("position", [480, 450])
	position = Vector2(float(values[0]), float(values[1]))


func _ready() -> void:
	add_to_group(&"npcs")
	collision_layer = 0
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 56
	collision.shape = shape
	add_child(collision)
	var silhouette := Polygon2D.new()
	silhouette.polygon = PackedVector2Array([Vector2(-18,30),Vector2(-22,-10),Vector2(-12,-35),Vector2(12,-35),Vector2(22,-10),Vector2(18,30)])
	silhouette.color = Color("58d7ff")
	add_child(silhouette)
	_prompt = Label.new()
	_prompt.position = Vector2(-72, -86)
	_prompt.custom_minimum_size.x = 144
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	add_child(_prompt)
	_bind_prompt_updates()
	_refresh_prompt()
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group(&"player"):
			_nearby_player = body
			_prompt.visible = true
	)
	body_exited.connect(func(body: Node2D) -> void:
		if body == _nearby_player:
			_nearby_player = null
			_prompt.visible = false
	)


func interact() -> bool:
	var game := get_node_or_null("/root/GameManager")
	var dialogue := get_node_or_null("/root/DialogueController")
	if game == null or dialogue == null:
		return false
	for entry_id: String in dialogue_entries:
		var definition := DialogueDatabase.entry(entry_id)
		if DialogueDatabase.conditions_met(definition, game.story_flags):
			dialogue.call_deferred(&"show_entry", entry_id)
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if _nearby_player != null and event.is_action_pressed(&"interact"):
		interact()
		get_viewport().set_input_as_handled()


func _bind_prompt_updates() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return
	for signal_name: StringName in [&"input_device_changed", &"action_binding_changed"]:
		var callback := Callable(self, &"_refresh_prompt")
		if settings.has_signal(signal_name) and not settings.is_connected(signal_name, callback):
			settings.connect(signal_name, callback)


func _refresh_prompt(_unused: Variant = null) -> void:
	if _prompt == null:
		return
	var settings := get_node_or_null("/root/SettingsManager")
	var binding := String(settings.call(&"get_action_prompt", &"interact")) if settings != null else "INTERACT"
	_prompt.text = "%s\n[%s] TALK" % [display_name.to_upper(), binding]
