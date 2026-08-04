class_name Collectible
extends Area2D

signal collected(pickup_id: StringName, value: int)

@export var pickup_id: StringName = &"coin"
@export_range(1, 9999, 1) var value := 100

var _elapsed := 0.0
var _collected := false
var _start_y := 0.0
var _coin_frames: Array[Texture2D] = []

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group(&"collectibles")
	_start_y = position.y
	_coin_frames = _load_prop_frames(1, "coin", 8)
	if not _coin_frames.is_empty():
		sprite.texture = _coin_frames[0]
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_elapsed += delta
	if not _coin_frames.is_empty():
		sprite.texture = _coin_frames[int(_elapsed * 12.0) % _coin_frames.size()]
	position.y = _start_y + sin(_elapsed * 3.2) * 3.0


func _load_prop_frames(act_number: int, frame_prefix: String, frame_count: int) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	var registry := get_node_or_null("/root/AssetRegistry")
	if registry == null:
		push_error("Collectible requires the AssetRegistry autoload.")
		return result
	for frame_number in range(1, frame_count + 1):
		var texture := registry.call(&"get_prop_texture", act_number, "%s%d" % [frame_prefix, frame_number]) as Texture2D
		if texture != null:
			result.append(texture)
	return result


func _on_body_entered(body: Node) -> void:
	if _collected or not body.is_in_group(&"player"):
		return
	_collected = true
	set_deferred("monitoring", false)
	var sound_manager := get_node_or_null("/root/SoundManager")
	if sound_manager != null:
		sound_manager.call(&"play_sfx", &"pickup", global_position, -3.0)
	collected.emit(pickup_id, value)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.8, 0.2), 0.12)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.12)
	await tween.finished
	queue_free()
