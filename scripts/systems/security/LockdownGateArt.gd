class_name LockdownGateArt
extends Node2D

## A compact physical frame plus an energy curtain.  It deliberately avoids a
## single flat colour block so combat locks and security gates read as part of
## the room's machinery at platformer scale.

var gate_size := Vector2(34.0, 180.0)
var act_number := 1
var charge := 0.0
var purpose: StringName = &"security"


func configure(size: Vector2, act: int, gate_purpose: StringName = &"security") -> void:
	gate_size = size
	act_number = clampi(act, 1, 4)
	purpose = gate_purpose
	name = "LockdownGateArt"
	set_meta(&"presentation", "framed_lockdown_gate")
	set_meta(&"act", act_number)
	set_meta(&"purpose", String(purpose))
	queue_redraw()


func set_charge(value: float) -> void:
	charge = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var half := gate_size * 0.5
	var palette := _palette()
	var frame: Color = palette.get("frame", Color("536179")) as Color
	var energy: Color = palette.get("energy", Color("4ee7ff")) as Color
	var core: Color = palette.get("core", Color("0c1729")) as Color
	var field_width := maxf(gate_size.x - 8.0, 12.0)
	var field := Rect2(Vector2(-field_width * 0.5, -half.y + 13.0), Vector2(field_width, maxf(gate_size.y - 26.0, 8.0)))

	# Recessed field behind a bolted pair of emitter housings.
	draw_rect(field.grow(3.0), Color(core, 0.94), true)
	draw_rect(field, Color(energy, 0.18 + charge * 0.12), true)
	for y: float in range(int(field.position.y + 7.0), int(field.end.y - 2.0), 12):
		draw_line(Vector2(field.position.x + 2.0, y), Vector2(field.end.x - 2.0, y), Color(energy, 0.62), 1.0, false)
	draw_line(Vector2(-field_width * 0.24, field.position.y), Vector2(-field_width * 0.24, field.end.y), Color(energy, 0.72), 1.5, false)
	draw_line(Vector2(field_width * 0.24, field.position.y), Vector2(field_width * 0.24, field.end.y), Color(energy, 0.72), 1.5, false)
	draw_line(Vector2(0.0, field.position.y + 3.0), Vector2(0.0, field.end.y - 3.0), Color(energy.lightened(0.22), 0.96), 2.0, false)

	var housing_width := maxf(gate_size.x + 18.0, 42.0)
	var housing_height := 14.0
	for y_position: float in [-half.y, half.y - housing_height]:
		var housing := Rect2(Vector2(-housing_width * 0.5, y_position), Vector2(housing_width, housing_height))
		draw_rect(housing, Color(core.lightened(0.09), 0.98), true)
		draw_rect(housing, Color(frame, 0.94), false, 2.0)
		draw_line(housing.position + Vector2(4.0, housing_height * 0.5), Vector2(housing.end.x - 4.0, housing.position.y + housing_height * 0.5), Color(energy, 0.72), 1.0, false)
		for x_position: float in [housing.position.x + 7.0, housing.end.x - 7.0]:
			draw_circle(Vector2(x_position, housing.position.y + housing_height * 0.5), 1.8, frame.lightened(0.25))

	# Side rails preserve a hard collision read without obscuring the action.
	for x_position: float in [field.position.x - 3.0, field.end.x + 3.0]:
		draw_line(Vector2(x_position, -half.y + housing_height), Vector2(x_position, half.y - housing_height), Color(frame, 0.94), 2.0, false)


func _palette() -> Dictionary:
	match act_number:
		1:
			return {"frame": Color("bd4d9c"), "energy": Color("36e5ff"), "core": Color("131128")}
		2:
			return {"frame": Color("d89432"), "energy": Color("5be6ff"), "core": Color("101b2e")}
		3:
			return {"frame": Color("8269f2"), "energy": Color("d4b0ff"), "core": Color("17112b")}
		_:
			return {"frame": Color("a740d6"), "energy": Color("f164c7"), "core": Color("220d29")}
