class_name PlayerAnimationFactory
extends RefCounted


static func build(sprite_sheet: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add(frames, sprite_sheet, &"Idle", 0, 0, 9, 9.0, true)
	_add(frames, sprite_sheet, &"Punch", 1, 0, 6, 16.0, false)
	_add(frames, sprite_sheet, &"Run", 3, 0, 7, 12.0, true)
	_add(frames, sprite_sheet, &"Jump", 4, 0, 3, 10.0, false)
	_add(frames, sprite_sheet, &"Fall", 4, 4, 7, 10.0, true)
	_add(frames, sprite_sheet, &"Defend", 5, 0, 1, 8.0, true)
	_add(frames, sprite_sheet, &"Shoot", 11, 0, 5, 16.0, false)
	return frames


static func _add(frames: SpriteFrames, sheet: Texture2D, animation: StringName, row: int, first: int, last: int, fps: float, loops: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loops)
	for column in range(first, last + 1):
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(column * 96, row * 96, 96, 96)
		frames.add_frame(animation, frame)
