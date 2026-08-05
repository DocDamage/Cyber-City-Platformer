extends CharacterBody2D

signal died

var gravity_multiplier := 1.0


func set_gravity_multiplier(value: float) -> void:
	gravity_multiplier = value
