extends CharacterBody2D

signal died

var input_disabled := false
var gravity_multiplier := 1.0


func _ready() -> void:
	add_to_group(&"player")


func set_input_disabled(value: bool) -> void:
	input_disabled = value


func set_gravity_multiplier(value: float) -> void:
	gravity_multiplier = value
