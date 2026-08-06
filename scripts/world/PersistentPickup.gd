class_name PersistentPickup
extends Area2D

signal collected(item_id: String, family_id: StringName)

var item_id := ""
var family_id: StringName = &"sword"
var pickup_state_id := ""
var display_name := "Weapon"
var dialogue_entry_id := ""
var _collected := false


func configure(data: Dictionary) -> void:
	item_id = String(data.get("id", ""))
	family_id = StringName(data.get("family", "sword"))
	pickup_state_id = String(data.get("state_id", "pickup_%s" % item_id))
	display_name = String(data.get("display_name", item_id.replace("_", " ").capitalize()))
	dialogue_entry_id = String(data.get("dialogue", "dagger_cache_found"))
	var values: Array = data.get("position", [480, 270])
	position = Vector2(float(values[0]), float(values[1]))


func _ready() -> void:
	add_to_group(&"persistent_pickups")
	var game := get_node_or_null("/root/GameManager")
	_collected = game != null and bool(game.world_progress.get_object_state(pickup_state_id, false))
	if _collected:
		queue_free()
		return
	collision_layer = 0
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 28
	collision.shape = shape
	add_child(collision)
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([Vector2(0,-22),Vector2(18,0),Vector2(0,22),Vector2(-18,0)])
	glow.color = Color("ffe66b")
	add_child(glow)
	var label := Label.new()
	label.text = display_name.to_upper()
	label.position = Vector2(-88, -54)
	label.custom_minimum_size.x = 176
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("ffe66b"))
	add_child(label)
	body_entered.connect(_on_body_entered)


func collect_for_test() -> bool:
	return _collect()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_collect()


func _collect() -> bool:
	if _collected or item_id.is_empty():
		return false
	var game := get_node_or_null("/root/GameManager")
	if game == null:
		return false
	if not game.call(&"add_inventory_item", StringName(item_id), 1, true) and not game.inventory.has_item(StringName(item_id)):
		return false
	_collected = true
	game.world_progress.set_object_state(pickup_state_id, true)
	collected.emit(item_id, family_id)
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
