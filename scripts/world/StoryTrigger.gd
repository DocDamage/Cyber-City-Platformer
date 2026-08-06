class_name StoryTrigger
extends Area2D

var sequence_id := ""
var trigger_id := ""
var one_shot := true
var _triggered := false


func configure(data: Dictionary, room_bounds: Rect2) -> void:
	sequence_id = String(data.get("sequence_id", data.get("id", "")))
	trigger_id = String(data.get("trigger_id", "story_trigger_%s" % sequence_id))
	one_shot = bool(data.get("one_shot", true))
	var values: Array = data.get("rect", [room_bounds.position.x + 32.0, room_bounds.position.y, 160.0, room_bounds.size.y])
	position = Vector2(float(values[0]) + float(values[2]) * 0.5, float(values[1]) + float(values[3]) * 0.5)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(float(values[2]), float(values[3]))
	collision.shape = shape
	add_child(collision)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var game := get_node_or_null("/root/GameManager")
	_triggered = one_shot and game != null and bool(game.world_progress.get_object_state(trigger_id, false))
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group(&"player"):
		return
	_triggered = one_shot
	var game := get_node_or_null("/root/GameManager")
	if game != null and one_shot:
		game.world_progress.set_object_state(trigger_id, true)
	var director := get_node_or_null("/root/CutsceneDirector")
	if director != null:
		director.call_deferred(&"play_sequence", sequence_id, body)
