class_name Collectible
extends Area2D

signal collected(pickup_id: StringName, value: int)

const COIN_FRAMES: Array[Texture2D] = [
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin1.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin2.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin3.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin4.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin5.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin6.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin7.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin8.png"),
]

@export var pickup_id: StringName = &"coin"
@export_range(1, 9999, 1) var value := 100

var _elapsed := 0.0
var _collected := false
var _start_y := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group(&"collectibles")
	_start_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_elapsed += delta
	sprite.texture = COIN_FRAMES[int(_elapsed * 12.0) % COIN_FRAMES.size()]
	position.y = _start_y + sin(_elapsed * 3.2) * 3.0


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
