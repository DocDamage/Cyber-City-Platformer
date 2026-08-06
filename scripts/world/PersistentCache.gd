class_name PersistentCache
extends Area2D

signal collected(cache_id: String, amount: int)

var cache_id := ""
var amount := 25
var _collected := false


func configure(data: Dictionary) -> void:
	cache_id = String(data.get("id", ""))
	amount = maxi(int(data.get("amount", 25)), 1)
	var values: Array = data.get("position", [480, 270])
	position = Vector2(float(values[0]), float(values[1]))


func _ready() -> void:
	add_to_group(&"persistent_caches")
	var game := get_node_or_null("/root/GameManager")
	_collected = game != null and bool(game.world_progress.get_object_state(cache_id, false))
	if _collected:
		queue_free()
		return
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 30.0
	collision.shape = shape
	add_child(collision)
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(0, -24), Vector2(21, -8), Vector2(15, 20),
		Vector2(-15, 20), Vector2(-21, -8),
	])
	glow.color = Color("ffd45a")
	add_child(glow)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(0, -13), Vector2(11, -4), Vector2(8, 10),
		Vector2(-8, 10), Vector2(-11, -4),
	])
	core.color = Color("fff3ae")
	core.z_index = 1
	add_child(core)
	var label := Label.new()
	label.text = "+%d CREDITS" % amount
	label.position = Vector2(-70, -58)
	label.custom_minimum_size.x = 140.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("ffe98b"))
	add_child(label)
	body_entered.connect(_on_body_entered)


func collect_for_test() -> bool:
	return _collect()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_collect()


func _collect() -> bool:
	if _collected or cache_id.is_empty():
		return false
	var game := get_node_or_null("/root/GameManager")
	if game == null:
		return false
	_collected = true
	game.inventory.currency += amount
	game.world_progress.set_object_state(cache_id, true)
	collected.emit(cache_id, amount)
	monitoring = false
	visible = false
	var save := get_node_or_null("/root/SaveManager")
	if save != null:
		save.call_deferred(&"save_game")
	queue_free.call_deferred()
	return true
