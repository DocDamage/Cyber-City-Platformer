extends Node2D

@onready var rooms: Node2D = $Rooms
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	var validation := WorldDatabase.validate()
	if not validation.is_empty():
		push_error("World database validation failed: %s" % validation)
		return
	var manager := get_node("/root/WorldManager")
	if not manager.call(&"bind_world", self, rooms, player):
		push_error("WorldRoot could not bind the world manager.")
		return
	await manager.call(&"load_initial_room")
