class_name CreatorAnimationCatalog
extends RefCounted

const PATH := "res://data/characters/animation_catalog.json"

static var _data: Dictionary = {}
static var _frame_cells: Array[Vector2i] = []
static var _frames_cache: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is not Dictionary:
			push_error("Creator animation catalog is invalid: %s" % PATH)
			return {}
		_data = parsed as Dictionary
	return _data


static func animation(animation_name: StringName) -> Dictionary:
	return ((data().get("animations", {}) as Dictionary).get(String(animation_name), {}) as Dictionary).duplicate(true)


static func animation_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for key: Variant in (data().get("animations", {}) as Dictionary):
		names.append(StringName(key))
	return names


static func frame_count(animation_name: StringName) -> int:
	var definition := animation(animation_name)
	var source_frames: Array = definition.get("source_frames", [])
	return int(source_frames[1]) - int(source_frames[0]) + 1 if source_frames.size() == 2 else 0


static func source_frame(animation_name: StringName, local_frame: int) -> int:
	var definition := animation(animation_name)
	var source_frames: Array = definition.get("source_frames", [])
	if source_frames.size() != 2:
		return 1
	return clampi(int(source_frames[0]) + local_frame, int(source_frames[0]), int(source_frames[1]))


static func frame_event(animation_name: StringName, local_frame: int) -> StringName:
	var events: Dictionary = animation(animation_name).get("events", {})
	return StringName(events.get(str(local_frame), ""))


static func cell_for_source_frame(source_frame_number: int) -> Vector2i:
	_ensure_frame_cells()
	if source_frame_number < 1 or source_frame_number > _frame_cells.size():
		return Vector2i.ZERO
	return _frame_cells[source_frame_number - 1]


static func build_sprite_frames(texture: Texture2D) -> SpriteFrames:
	if texture == null:
		return SpriteFrames.new()
	var cache_key := texture.resource_path
	if not cache_key.is_empty() and _frames_cache.has(cache_key):
		return _frames_cache[cache_key] as SpriteFrames
	var result := SpriteFrames.new()
	result.remove_animation(&"default")
	var frame_size_values: Array = data().get("frame_size", [100, 40])
	var frame_size := Vector2(float(frame_size_values[0]), float(frame_size_values[1]))
	for animation_name: StringName in animation_names():
		var definition := animation(animation_name)
		result.add_animation(animation_name)
		result.set_animation_speed(animation_name, float(definition.get("fps", 8.0)))
		result.set_animation_loop(animation_name, bool(definition.get("loop", false)))
		for local_frame: int in range(frame_count(animation_name)):
			var cell := cell_for_source_frame(source_frame(animation_name, local_frame))
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(Vector2(cell) * frame_size, frame_size)
			result.add_frame(animation_name, frame)
	if not cache_key.is_empty():
		_frames_cache[cache_key] = result
	return result


static func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	_ensure_frame_cells()
	if _frame_cells.size() != 102:
		errors.append("Expected 102 source frames, found %d." % _frame_cells.size())
	var covered: Dictionary = {}
	for animation_name: StringName in animation_names():
		for local_frame: int in range(frame_count(animation_name)):
			covered[source_frame(animation_name, local_frame)] = animation_name
	for source_index: int in range(1, 103):
		if not covered.has(source_index):
			errors.append("Source frame %d is not assigned." % source_index)
	return errors


static func clear_runtime_cache() -> void:
	_frames_cache.clear()


static func _ensure_frame_cells() -> void:
	if not _frame_cells.is_empty():
		return
	var row_counts: Array = data().get("row_frame_counts", [])
	for row: int in range(row_counts.size()):
		for column: int in range(int(row_counts[row])):
			_frame_cells.append(Vector2i(column, row))
