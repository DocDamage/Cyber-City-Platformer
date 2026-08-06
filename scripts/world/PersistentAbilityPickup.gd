class_name PersistentAbilityPickup
extends Area2D

signal collected(ability_id: StringName)

var ability_id: StringName = &""
var pickup_state_id := ""
var display_name := "Ability"
var dialogue_entry_id := ""
var _collected := false


func configure(data: Dictionary) -> void:
	ability_id = StringName(data.get("ability", data.get("id", "")))
	pickup_state_id = String(data.get("state_id", "ability_pickup_%s" % ability_id))
	display_name = String(data.get("display_name", String(ability_id).replace("_", " ").capitalize()))
	dialogue_entry_id = String(data.get("dialogue", ""))
	var values: Array = data.get("position", [480, 270])
	position = Vector2(float(values[0]), float(values[1]))


func _ready() -> void:
	add_to_group(&"persistent_ability_pickups")
	var game := get_node_or_null("/root/GameManager")
	_collected = game != null and (game.abilities.has(ability_id) or bool(game.world_progress.get_object_state(pickup_state_id, false)))
	if _collected:
		queue_free()
		return
	collision_layer = 0
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 30.0
	collision.shape = shape
	add_child(collision)
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([Vector2(0, -26), Vector2(22, 0), Vector2(0, 26), Vector2(-22, 0)])
	glow.color = Color("8ff5ff")
	add_child(glow)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(0, -13), Vector2(11, 0), Vector2(0, 13), Vector2(-11, 0)])
	core.color = Color("ffe66b")
	add_child(core)
	var label := Label.new()
	label.text = display_name.to_upper()
	label.position = Vector2(-100, -58)
	label.custom_minimum_size.x = 200
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("8ff5ff"))
	add_child(label)
	body_entered.connect(_on_body_entered)


func collect_for_test() -> bool:
	return _collect()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_collect()


func _collect() -> bool:
	if _collected or ability_id.is_empty():
		return false
	var game := get_node_or_null("/root/GameManager")
	if game == null or not game.call(&"grant_ability", ability_id):
		return false
	_collected = true
	game.world_progress.set_object_state(pickup_state_id, true)
	collected.emit(ability_id)
	monitoring = false
	visible = false
	if not dialogue_entry_id.is_empty():
		var dialogue := get_node_or_null("/root/DialogueController")
		if dialogue != null:
			dialogue.call_deferred(&"show_entry", dialogue_entry_id)
	var save := get_node_or_null("/root/SaveManager")
	if save != null:
		save.call_deferred(&"save_game")
	queue_free.call_deferred()
	return true
